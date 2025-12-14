-- Hotel Reservation System Database Schema

-- Create GUESTS table
CREATE TABLE guests (
    guest_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ROOM_TYPES table
CREATE TABLE room_types (
    room_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price > 0),
    capacity INT NOT NULL CHECK (capacity > 0),
    description TEXT
);

-- Create ROOMS table
CREATE TABLE rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(10) NOT NULL UNIQUE,
    room_type_id INT NOT NULL,
    floor INT NOT NULL CHECK (floor > 0),
    status VARCHAR(20) DEFAULT 'Available' CHECK (status IN ('Available', 'Occupied', 'Maintenance')),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
);

-- Create RESERVATIONS table
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    guest_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'Confirmed' CHECK (status IN ('Confirmed', 'Cancelled', 'Completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    CHECK (check_out_date > check_in_date)
);

-- Create RESERVATION_ROOMS junction table
CREATE TABLE reservation_rooms (
    reservation_room_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL,
    room_id INT NOT NULL,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    UNIQUE (reservation_id, room_id)
);

-- Create PAYMENTS table
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    reservation_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Cash', 'Credit Card', 'Debit Card', 'Online')),
    status VARCHAR(20) DEFAULT 'Completed' CHECK (status IN ('Completed', 'Pending', 'Refunded')),
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
);