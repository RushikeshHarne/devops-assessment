-- 001_schema.sql: Create tables

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS hotel_bookings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       UUID NOT NULL,
  hotel_id     VARCHAR(100) NOT NULL,
  city         VARCHAR(100) NOT NULL,
  checkin_date DATE NOT NULL,
  checkout_date DATE NOT NULL,
  amount       NUMERIC(12,2) NOT NULL,
  status       VARCHAR(50) NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS booking_events (
  id         BIGSERIAL PRIMARY KEY,
  booking_id UUID NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  payload    JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for the target query:
-- SELECT org_id, status, COUNT(*), SUM(amount)
-- FROM hotel_bookings
-- WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
-- GROUP BY org_id, status;
--
-- A composite index on (city, created_at) covers the WHERE clause filters.
-- Including org_id and status as covering columns avoids a heap fetch for
-- the GROUP BY columns, making this an index-only scan.
CREATE INDEX IF NOT EXISTS idx_bookings_city_created_covering
  ON hotel_bookings (city, created_at DESC)
  INCLUDE (org_id, status, amount);
