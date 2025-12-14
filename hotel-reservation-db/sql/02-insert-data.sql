-- Insert Room Types
INSERT INTO room_types (type_name, base_price, capacity, description) VALUES
('Single', 50.00, 1, 'Cozy room with single bed'),
('Double', 80.00, 2, 'Comfortable room with double bed'),
('Twin', 85.00, 2, 'Room with two single beds'),
('Suite', 150.00, 4, 'Luxurious suite with living area'),
('Deluxe', 200.00, 3, 'Premium room with city view');

SELECT * FROM room_types;

-- Insert Rooms
INSERT INTO rooms (room_number, room_type_id, floor, status) VALUES
('101', 1, 1, 'Available'),
('102', 1, 1, 'Available'),
('103', 2, 1, 'Available'),
('104', 2, 1, 'Occupied'),
('201', 3, 2, 'Available'),
('202', 3, 2, 'Available'),
('203', 4, 2, 'Available'),
('204', 4, 2, 'Maintenance'),
('301', 5, 3, 'Available'),
('302', 5, 3, 'Available'),
('303', 2, 3, 'Available'),
('304', 2, 3, 'Available'),
('401', 4, 4, 'Available'),
('402', 4, 4, 'Available'),
('403', 1, 4, 'Available');

SELECT * FROM rooms;

-- Insert Guests
INSERT INTO guests (first_name, last_name, email, phone, address) VALUES
('John', 'Doe', 'john.doe@email.com', '555-0101', '123 Main St, New York, NY'),
('Jane', 'Smith', 'jane.smith@email.com', '555-0102', '456 Oak Ave, Los Angeles, CA'),
('Mike', 'Johnson', 'mike.j@email.com', '555-0103', '789 Pine Rd, Chicago, IL'),
('Emily', 'Brown', 'emily.brown@email.com', '555-0104', '321 Elm St, Houston, TX'),
('David', 'Wilson', 'david.w@email.com', '555-0105', '654 Maple Dr, Phoenix, AZ'),
('Sarah', 'Davis', 'sarah.davis@email.com', '555-0106', '987 Cedar Ln, Philadelphia, PA'),
('Robert', 'Miller', 'robert.m@email.com', '555-0107', '147 Birch Ct, San Antonio, TX'),
('Lisa', 'Taylor', 'lisa.taylor@email.com', '555-0108', '258 Spruce Way, San Diego, CA'),
('James', 'Anderson', 'james.a@email.com', '555-0109', '369 Ash Blvd, Dallas, TX'),
('Mary', 'Thomas', 'mary.thomas@email.com', '555-0110', '741 Willow Rd, San Jose, CA'),
('Chris', 'Martinez', 'chris.m@email.com', '555-0111', '852 Cherry St, Austin, TX'),
('Linda', 'Garcia', 'linda.g@email.com', '555-0112', '963 Poplar Ave, Jacksonville, FL'),
('Michael', 'Rodriguez', 'michael.r@email.com', '555-0113', '159 Hickory Dr, Fort Worth, TX'),
('Patricia', 'Lee', 'patricia.lee@email.com', '555-0114', '357 Magnolia Ln, Columbus, OH'),
('Daniel', 'White', 'daniel.w@email.com', '555-0115', '468 Dogwood Ct, Charlotte, NC');

SELECT * FROM guests;

-- Insert Reservations (mix of past, current, and future)
INSERT INTO reservations (guest_id, check_in_date, check_out_date, total_amount, status) VALUES
(1, '2024-12-01', '2024-12-05', 320.00, 'Completed'),
(2, '2024-12-03', '2024-12-07', 600.00, 'Completed'),
(3, '2024-12-05', '2024-12-08', 255.00, 'Completed'),
(4, '2024-12-06', '2024-12-10', 640.00, 'Confirmed'),
(5, '2024-12-08', '2024-12-12', 400.00, 'Confirmed'),
(6, '2024-12-10', '2024-12-15', 750.00, 'Confirmed'),
(7, '2024-12-12', '2024-12-14', 170.00, 'Confirmed'),
(8, '2024-12-15', '2024-12-20', 1000.00, 'Confirmed'),
(9, '2024-12-18', '2024-12-22', 320.00, 'Confirmed'),
(10, '2024-12-20', '2024-12-25', 1250.00, 'Confirmed'),
(11, '2024-11-15', '2024-11-18', 255.00, 'Completed'),
(12, '2024-11-20', '2024-11-23', 240.00, 'Completed'),
(13, '2024-11-25', '2024-11-28', 450.00, 'Cancelled'),
(14, '2024-12-25', '2024-12-30', 1500.00, 'Confirmed'),
(15, '2024-12-28', '2025-01-02', 800.00, 'Confirmed');

-- Insert Reservation-Room links
INSERT INTO reservation_rooms (reservation_id, room_id) VALUES
(1, 3), -- John Doe - Room 103 (Double)
(2, 7), -- Jane Smith - Room 203 (Suite)
(3, 1), (3, 2), -- Mike - Two singles
(4, 3), (4, 11), -- Emily - Two doubles
(5, 9), -- David - Deluxe
(6, 13), -- Sarah - Suite
(7, 15), (7, 1), -- Robert - Two singles
(8, 9), (8, 10), -- Lisa - Two deluxe
(9, 3), (9, 11), -- James - Two doubles
(10, 13), (10, 14), -- Mary - Two suites
(11, 1), (11, 2), (11, 15), -- Chris - Three rooms
(12, 3), (12, 11), -- Linda
(13, 7), -- Michael (cancelled)
(14, 9), (14, 10), (14, 13), -- Patricia - 3 rooms
(15, 3), (15, 11); -- Daniel

-- Insert Payments
INSERT INTO payments (reservation_id, amount, payment_method, status) VALUES
(1, 320.00, 'Credit Card', 'Completed'),
(2, 600.00, 'Online', 'Completed'),
(3, 255.00, 'Cash', 'Completed'),
(4, 320.00, 'Credit Card', 'Completed'),
(4, 320.00, 'Credit Card', 'Pending'),
(5, 400.00, 'Debit Card', 'Completed'),
(6, 750.00, 'Online', 'Completed'),
(7, 170.00, 'Cash', 'Completed'),
(8, 500.00, 'Credit Card', 'Completed'),
(8, 500.00, 'Credit Card', 'Pending'),
(9, 320.00, 'Online', 'Completed'),
(10, 625.00, 'Credit Card', 'Completed'),
(10, 625.00, 'Credit Card', 'Pending'),
(11, 255.00, 'Debit Card', 'Completed'),
(12, 240.00, 'Cash', 'Completed'),
(13, 450.00, 'Credit Card', 'Refunded'),
(14, 750.00, 'Online', 'Completed'),
(14, 750.00, 'Credit Card', 'Pending'),
(15, 800.00, 'Debit Card', 'Completed');


