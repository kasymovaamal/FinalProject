-- INDEXING FOR PERFORMANCE OPTIMIZATION

-- Check query performance BEFORE indexing
EXPLAIN ANALYZE
SELECT * FROM guests WHERE email = 'john.doe@email.com';

EXPLAIN ANALYZE
SELECT * FROM reservations WHERE check_in_date = '2024-12-10';

-- Create indexes on frequently queried columns
CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_guests_last_name ON guests(last_name);
CREATE INDEX idx_reservations_dates ON reservations(check_in_date, check_out_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_payments_reservation ON payments(reservation_id);

-- Check query performance AFTER indexing
EXPLAIN ANALYZE
SELECT * FROM guests WHERE email = 'john.doe@email.com';

EXPLAIN ANALYZE
SELECT * FROM reservations WHERE check_in_date = '2024-12-10';

-- View all indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- VIEWS FOR COMMON QUERIES

-- View 1: Current Reservations Summary
CREATE OR REPLACE VIEW current_reservations AS
SELECT 
    r.reservation_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    g.email,
    g.phone,
    r.check_in_date,
    r.check_out_date,
    STRING_AGG(rm.room_number, ', ') AS rooms,
    r.total_amount,
    r.status
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
JOIN reservation_rooms rr ON r.reservation_id = rr.reservation_id
JOIN rooms rm ON rr.room_id = rm.room_id
WHERE r.status = 'Confirmed'
  AND r.check_out_date >= CURRENT_DATE
GROUP BY r.reservation_id, g.first_name, g.last_name, g.email, g.phone;

-- Use the view
SELECT * FROM current_reservations;


-- View 2: Available Rooms with Details
CREATE OR REPLACE VIEW available_rooms_view AS
SELECT 
    r.room_id,
    r.room_number,
    rt.type_name,
    rt.base_price,
    rt.capacity,
    r.floor,
    rt.description
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.status = 'Available'
ORDER BY r.room_number;

-- Use the view
SELECT * FROM available_rooms_view;


-- View 3: Guest Reservation History
CREATE OR REPLACE VIEW guest_history AS
SELECT 
    g.guest_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    g.email,
    COUNT(r.reservation_id) AS total_stays,
    SUM(r.total_amount) AS lifetime_value,
    MAX(r.check_out_date) AS last_stay,
    MIN(r.check_in_date) AS first_stay
FROM guests g
LEFT JOIN reservations r ON g.guest_id = r.guest_id
WHERE r.status IN ('Completed', 'Confirmed')
GROUP BY g.guest_id, g.first_name, g.last_name, g.email;

-- Use the view
SELECT * FROM guest_history ORDER BY lifetime_value DESC;