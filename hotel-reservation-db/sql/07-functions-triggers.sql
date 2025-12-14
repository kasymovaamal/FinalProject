-- FUNCTIONS AND TRIGGERS FOR HOTEL RESERVATION SYSTEM

-- ======================
-- FUNCTIONS
-- ======================

-- Function 1: Calculate total cost based on room type and nights
CREATE OR REPLACE FUNCTION calculate_reservation_cost(
    p_room_id INT,
    p_check_in DATE,
    p_check_out DATE
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_base_price DECIMAL(10,2);
    v_nights INT;
    v_total DECIMAL(10,2);
BEGIN
    -- Get the base price for the room
    SELECT rt.base_price INTO v_base_price
    FROM rooms r
    JOIN room_types rt ON r.room_type_id = rt.room_type_id
    WHERE r.room_id = p_room_id;
    
    -- Calculate number of nights
    v_nights := p_check_out - p_check_in;
    
    -- Calculate total
    v_total := v_base_price * v_nights;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;


-- Function 2: Check room availability for dates
CREATE OR REPLACE FUNCTION check_room_availability(
    p_room_id INT,
    p_check_in DATE,
    p_check_out DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    v_conflict_count INT;
BEGIN
    -- Check if room has any conflicting reservations
    SELECT COUNT(*) INTO v_conflict_count
    FROM reservation_rooms rr
    JOIN reservations r ON rr.reservation_id = r.reservation_id
    WHERE rr.room_id = p_room_id
      AND r.status IN ('Confirmed', 'Completed')
      AND r.check_in_date < p_check_out
      AND r.check_out_date > p_check_in;
    
    -- Return true if available (no conflicts)
    RETURN v_conflict_count = 0;
END;
$$ LANGUAGE plpgsql;


-- ======================
-- TRIGGERS
-- ======================

-- Trigger 1: Prevent double booking
CREATE OR REPLACE FUNCTION prevent_double_booking()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict_count INT;
    v_check_in DATE;
    v_check_out DATE;
BEGIN
    -- Get check-in and check-out dates for this reservation
    SELECT check_in_date, check_out_date INTO v_check_in, v_check_out
    FROM reservations
    WHERE reservation_id = NEW.reservation_id;
    
    -- Check for conflicts
    SELECT COUNT(*) INTO v_conflict_count
    FROM reservation_rooms rr
    JOIN reservations r ON rr.reservation_id = r.reservation_id
    WHERE rr.room_id = NEW.room_id
      AND rr.reservation_id != NEW.reservation_id
      AND r.status IN ('Confirmed', 'Completed')
      AND r.check_in_date < v_check_out
      AND r.check_out_date > v_check_in;
    
    IF v_conflict_count > 0 THEN
        RAISE EXCEPTION 'Room % is already booked for these dates', NEW.room_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_double_booking
BEFORE INSERT OR UPDATE ON reservation_rooms
FOR EACH ROW
EXECUTE FUNCTION prevent_double_booking();


-- Trigger 2: Auto-update room status when reservation is made
CREATE OR REPLACE FUNCTION update_room_status_on_reservation()
RETURNS TRIGGER AS $$
DECLARE
    v_check_in DATE;
    v_check_out DATE;
BEGIN
    -- Get reservation dates
    SELECT check_in_date, check_out_date INTO v_check_in, v_check_out
    FROM reservations
    WHERE reservation_id = NEW.reservation_id;
    
    -- If check-in is today or in the past, mark room as occupied
    IF v_check_in <= CURRENT_DATE AND v_check_out > CURRENT_DATE THEN
        UPDATE rooms 
        SET status = 'Occupied'
        WHERE room_id = NEW.room_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_room_status
AFTER INSERT ON reservation_rooms
FOR EACH ROW
EXECUTE FUNCTION update_room_status_on_reservation();


-- Trigger 3: Log reservation changes (audit trail)
CREATE TABLE IF NOT EXISTS reservation_audit (
    audit_id SERIAL PRIMARY KEY,
    reservation_id INT,
    action VARCHAR(20),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_reservation_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        INSERT INTO reservation_audit (reservation_id, action, old_status, new_status, changed_by)
        VALUES (NEW.reservation_id, 'UPDATE', OLD.status, NEW.status, CURRENT_USER);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO reservation_audit (reservation_id, action, old_status, changed_by)
        VALUES (OLD.reservation_id, 'DELETE', OLD.status, CURRENT_USER);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_reservation_changes
AFTER UPDATE OR DELETE ON reservations
FOR EACH ROW
EXECUTE FUNCTION log_reservation_changes();