-- TRANSACTION EXAMPLES FOR HOTEL RESERVATION SYSTEM

-- Transaction 1: Complete Booking Process
-- This creates a reservation, links rooms, and records payment
BEGIN;

-- Insert new guest
INSERT INTO guests (first_name, last_name, email, phone, address)
VALUES ('Tom', 'Hanks', 'tom.hanks@email.com', '555-0300', '789 Hollywood Blvd, LA, CA')
RETURNING guest_id; -- Note the guest_id returned (let's say it's 16)

-- Create reservation
INSERT INTO reservations (guest_id, check_in_date, check_out_date, total_amount, status)
VALUES (16, '2025-01-10', '2025-01-15', 400.00, 'Confirmed')
RETURNING reservation_id; -- Note the reservation_id (let's say it's 16)

-- Link room to reservation
INSERT INTO reservation_rooms (reservation_id, room_id)
VALUES (16, 5); -- Room 201

-- Update room status
UPDATE rooms SET status = 'Occupied' WHERE room_id = 5;

-- Record payment
INSERT INTO payments (reservation_id, amount, payment_method, status)
VALUES (16, 400.00, 'Credit Card', 'Completed');

COMMIT;
-- If everything succeeds, changes are saved


-- Transaction 2: Cancellation with Rollback Demo
-- This demonstrates rolling back a transaction on error
BEGIN;

-- Try to cancel reservation
UPDATE reservations 
SET status = 'Cancelled' 
WHERE reservation_id = 4;

-- Free up the room
UPDATE rooms 
SET status = 'Available'
WHERE room_id IN (
    SELECT room_id FROM reservation_rooms WHERE reservation_id = 4
);

-- Record refund
INSERT INTO payments (reservation_id, amount, payment_method, status)
VALUES (4, -640.00, 'Credit Card', 'Refunded');

-- Oops! Let's say we made a mistake - rollback
ROLLBACK;
-- All changes are undone


-- Transaction 3: Room Maintenance Update
BEGIN;

-- Set room to maintenance
UPDATE rooms 
SET status = 'Maintenance'
WHERE room_number = '301';

-- Cancel any future reservations for this room
UPDATE reservations r
SET status = 'Cancelled'
WHERE r.reservation_id IN (
    SELECT DISTINCT rr.reservation_id
    FROM reservation_rooms rr
    JOIN rooms rm ON rr.room_id = rm.room_id
    WHERE rm.room_number = '301'
      AND r.check_in_date > CURRENT_DATE
);

COMMIT;


-- Transaction 4: Demonstrating ACID properties
-- Test atomicity: Either all operations complete or none
BEGIN;

SAVEPOINT before_update;

-- Update multiple related records
UPDATE reservations SET total_amount = total_amount * 1.1 
WHERE status = 'Confirmed';

UPDATE payments SET amount = amount * 1.1 
WHERE status = 'Pending';

-- If you want to undo just these operations:
ROLLBACK TO SAVEPOINT before_update;

-- Or commit everything:
COMMIT;