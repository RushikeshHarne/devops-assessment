-- 002_seed.sql: Seed 120 hotel bookings across cities, orgs, statuses
-- and booking_events for a subset of bookings.

DO $$
DECLARE
  orgs    UUID[] := ARRAY[
    'a0000000-0000-0000-0000-000000000001'::UUID,
    'a0000000-0000-0000-0000-000000000002'::UUID,
    'a0000000-0000-0000-0000-000000000003'::UUID
  ];
  cities   TEXT[] := ARRAY['delhi','mumbai','bangalore','hyderabad','chennai','kolkata'];
  statuses TEXT[] := ARRAY['confirmed','cancelled','pending','completed','no_show'];
  hotels   TEXT[] := ARRAY['HTL001','HTL002','HTL003','HTL004','HTL005',
                            'HTL006','HTL007','HTL008','HTL009','HTL010'];
  bid      UUID;
  i        INT;
  days_ago INT;
BEGIN
  FOR i IN 1..120 LOOP
    days_ago := (random() * 60)::INT;  -- spread over last 60 days

    INSERT INTO hotel_bookings (
      org_id, hotel_id, city, checkin_date, checkout_date,
      amount, status, created_at
    ) VALUES (
      orgs[1 + (i % array_length(orgs, 1))],
      hotels[1 + (i % array_length(hotels, 1))],
      cities[1 + (i % array_length(cities, 1))],
      CURRENT_DATE - days_ago,
      CURRENT_DATE - days_ago + (1 + (random() * 5)::INT),
      (500 + random() * 9500)::NUMERIC(12,2),
      statuses[1 + (i % array_length(statuses, 1))],
      NOW() - (days_ago || ' days')::INTERVAL
    )
    RETURNING id INTO bid;

    -- Add events for every 3rd booking
    IF i % 3 = 0 THEN
      INSERT INTO booking_events (booking_id, event_type, payload, created_at)
      VALUES
        (bid, 'booking_created',
         jsonb_build_object('source', 'web', 'ip', '192.168.1.' || i),
         NOW() - (days_ago || ' days')::INTERVAL),
        (bid, 'payment_processed',
         jsonb_build_object('method', 'card', 'last4', lpad((i*7 % 10000)::TEXT, 4, '0')),
         NOW() - (days_ago || ' days')::INTERVAL + INTERVAL '5 minutes');
    END IF;
  END LOOP;
END $$;
