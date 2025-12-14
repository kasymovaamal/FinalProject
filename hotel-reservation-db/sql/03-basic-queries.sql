-- BASIC SQL QUERIES FOR HOTEL RESERVATION SYSTEM

-- 1. SELECT: View all guests
SELECT * FROM guests ORDER BY last_name;

-- 2. SELECT with WHERE: Find a specific guest
SELECT * FROM guests 
WHERE email = 'john.doe@email.com';

-- 3. SELECT: View all available rooms
SELECT r.room_number, rt.type_name, rt.base_price, r.floor
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.status = 'Available'
ORDER BY r.room_number;

-- 4. SELECT: View current reservations (checked in but not checked out)
SELECT 
    r.reservation_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    r.check_in_date,
    r.check_out_date,
    r.total_amount
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
WHERE r.status = 'Confirmed' 
  AND r.check_in_date <= CURRENT_DATE 
  AND r.check_out_date >= CURRENT_DATE;

-- 5. INSERT: Add a new guest
INSERT INTO guests (first_name, last_name, email, phone, address)
VALUES ('Alice', 'Cooper', 'alice.cooper@email.com', '555-0200', '123 Rock St, Detroit, MI');

-- 6. UPDATE: Change room status
UPDATE rooms 
SET status = 'Maintenance'
WHERE room_number = '102';

-- 7. UPDATE: Update guest contact information
UPDATE guests
SET phone = '555-9999', address = '999 New Address St, Boston, MA'
WHERE email = 'john.doe@email.com';

-- 8. DELETE: Cancel a reservation
DELETE FROM reservations
WHERE reservation_id = 13 AND status = 'Cancelled';

-- 9. SELECT with COUNT: Count rooms by type
SELECT rt.type_name, COUNT(r.room_id) as room_count
FROM room_types rt
LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
GROUP BY rt.type_name;

-- 10. SELECT: Calculate total revenue
SELECT SUM(total_amount) as total_revenue
FROM reservations
WHERE status = 'Completed';