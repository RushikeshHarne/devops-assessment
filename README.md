# DevOps Assessment — Terraform + Database Reliability

## Repository Structure

```
.
├── .github/workflows/terraform.yml   # CI: fmt, init, validate, plan on PRs
├── infra/
│   ├── modules/
│   │   ├── network/   # VPC, subnets, IGW, NAT, security groups
│   │   ├── ecs/       # ALB, ECS cluster, task definition, service
│   │   └── rds/       # RDS PostgreSQL (private, subnet group)
│   └── envs/
│       ├── dev/       # Small instance, 3-day backup, no deletion protection
│       └── prod/      # Larger instance, 14-day backup, deletion protection on, multi-AZ
├── migrations/
│   ├── 001_schema.sql # Tables + covering index
│   └── 002_seed.sql   # 120 bookings, events for every 3rd booking
├── scripts/
│   ├── backup.sh
│   └── restore.sh
└── docker-compose.yml
```

---

## Part 1 & 2 — Terraform Infrastructure

### Architecture

```
Internet → ALB (public subnets) → ECS/Fargate (private subnets) → RDS PostgreSQL (private subnets)
```

- RDS has no public access; its security group only allows port 5432 from the ECS security group.
- NAT Gateway allows ECS tasks to pull images without a public IP.

### Environment Differences

| Setting                  | dev            | prod           |
|--------------------------|----------------|----------------|
| ECS CPU / Memory         | 256 / 512      | 1024 / 2048    |
| ECS desired count        | 1              | 2              |
| RDS instance class       | db.t3.micro    | db.t3.medium   |
| RDS allocated storage    | 20 GB          | 100 GB         |
| RDS multi-AZ             | false          | true           |
| Backup retention         | 3 days         | 14 days        |
| Deletion protection      | false          | true           |
| Skip final snapshot      | true           | false          |

### Validate Terraform Locally

```bash
# Install Terraform >= 1.5 first

# Dev
cd infra/envs/dev
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var="db_password=test"

# Prod
cd ../prod
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var="db_password=test"
```

---

## Part 3 — GitHub Actions

The workflow at `.github/workflows/terraform.yml` triggers on Pull Requests that touch `infra/**`.

It runs in a matrix for both `dev` and `prod` environments:

1. `terraform fmt -check`
2. `terraform init -backend=false`
3. `terraform validate`
4. `terraform plan -refresh=false`

The plan output is posted as a **PR comment** and also uploaded as a **workflow artifact** (`tfplan-dev`, `tfplan-prod`).

Required GitHub secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

---

## Part 4 — Local Database Setup

### Prerequisites

- Docker and Docker Compose

### Start the database

```bash
docker compose up -d
```

Docker Compose mounts `./migrations/` into `/docker-entrypoint-initdb.d/`, so both `001_schema.sql` and `002_seed.sql` run automatically on first start.

### Verify data loaded

```bash
docker exec devops_db psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM hotel_bookings;"
# Expected: 120

docker exec devops_db psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM booking_events;"
# Expected: ~40 (every 3rd booking gets 2 events)
```

---

## Part 5 — Seed Data and Index

### Seed data covers

- 120 hotel bookings spread over the last 60 days
- 6 cities: delhi, mumbai, bangalore, hyderabad, chennai, kolkata
- 3 organisations
- 5 statuses: confirmed, cancelled, pending, completed, no_show
- booking_events for every 3rd booking (2 events each: `booking_created`, `payment_processed`)

### Target query

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

### Index

```sql
CREATE INDEX idx_bookings_city_created_covering
  ON hotel_bookings (city, created_at DESC)
  INCLUDE (org_id, status, amount);
```

**Why this index:**

- `city` is the equality filter — placing it first lets PostgreSQL jump directly to the matching partition of the B-tree.
- `created_at DESC` is the range filter — ordering it descending matches the `>= NOW() - INTERVAL` scan direction and avoids a sort.
- `INCLUDE (org_id, status, amount)` adds the three columns needed by `GROUP BY` and `SUM` as non-key covering columns. PostgreSQL can satisfy the entire query from the index without touching the heap (index-only scan), which is the most significant performance gain for this read-heavy aggregation.

### Verify the index is used

```bash
docker exec devops_db psql -U appuser -d appdb -c "
EXPLAIN (ANALYZE, BUFFERS)
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"
```

Look for `Index Only Scan using idx_bookings_city_created_covering` in the output.

---

## Part 6 — Backup and Restore

### Prerequisites

`pg_dump` and `pg_restore` must be installed locally (PostgreSQL client tools).

```bash
# Ubuntu/Debian
sudo apt-get install -y postgresql-client
```

### Backup

```bash
./scripts/backup.sh
# Creates: ./backups/appdb_YYYYMMDD_HHMMSS.dump
```

Environment variables (all have defaults matching docker-compose):

| Variable    | Default      |
|-------------|--------------|
| DB_HOST     | localhost    |
| DB_PORT     | 5432         |
| DB_NAME     | appdb        |
| DB_USER     | appuser      |
| PGPASSWORD  | apppassword  |
| BACKUP_DIR  | ./backups    |

### Restore

```bash
./scripts/restore.sh ./backups/appdb_YYYYMMDD_HHMMSS.dump
```

The restore script:
1. Terminates active connections to the database
2. Drops and recreates the database
3. Runs `pg_restore` into the fresh database

### Verify restore worked

```bash
# 1. Row counts should match pre-backup counts
docker exec devops_db psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM hotel_bookings;"

docker exec devops_db psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM booking_events;"

# 2. Run the target aggregation query
docker exec devops_db psql -U appuser -d appdb -c "
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"

# 3. Confirm the index exists
docker exec devops_db psql -U appuser -d appdb \
  -c "\di idx_bookings_city_created_covering"
```

---

## Quick Start (full local run)

```bash
# 1. Start DB (runs migrations + seed automatically)
docker compose up -d

# 2. Wait for healthy, then verify
docker compose ps

# 3. Backup
./scripts/backup.sh

# 4. Restore (use the file printed by backup.sh)
./scripts/restore.sh ./backups/appdb_<timestamp>.dump

# 5. Verify
docker exec devops_db psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM hotel_bookings;"
```
