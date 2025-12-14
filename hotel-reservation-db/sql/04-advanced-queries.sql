-- ADVANCED SQL QUERIES FOR HOTEL RESERVATION SYSTEM

-- 1. JOIN: Get complete reservation details
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
GROUP BY r.reservation_id, g.first_name, g.last_name, g.email, g.phone
ORDER BY r.check_in_date DESC;

-- 2. SUBQUERY: Find guests who have spent more than average
SELECT 
    g.guest_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    SUM(r.total_amount) AS total_spent
FROM guests g
JOIN reservations r ON g.guest_id = r.guest_id
WHERE r.status = 'Completed'
GROUP BY g.guest_id, g.first_name, g.last_name
HAVING SUM(r.total_amount) > (
    SELECT AVG(total_amount) 
    FROM reservations 
    WHERE status = 'Completed'
)
ORDER BY total_spent DESC;

-- 3. WINDOW FUNCTION: Rank guests by total spending
SELECT 
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    COUNT(r.reservation_id) AS num_reservations,
    SUM(r.total_amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(r.total_amount) DESC) AS spending_rank
FROM guests g
JOIN reservations r ON g.guest_id = r.guest_id
WHERE r.status = 'Completed'
GROUP BY g.guest_id, g.first_name, g.last_name;

-- 4. CTE: Calculate occupancy rate by room type
WITH room_nights AS (
    SELECT 
        rt.type_name,
        COUNT(rr.reservation_room_id) AS booked_nights,
        COUNT(DISTINCT r.room_id) AS total_rooms
    FROM room_types rt
    LEFT JOIN rooms r ON rt.room_type_id = r.room_type_id
    LEFT JOIN reservation_rooms rr ON r.room_id = rr.room_id
    LEFT JOIN reservations res ON rr.reservation_id = res.reservation_id
        AND res.status = 'Completed'
    GROUP BY rt.type_name
)
SELECT 
    type_name,
    total_rooms,
    booked_nights,
    ROUND((booked_nights::NUMERIC / NULLIF(total_rooms, 0) * 100), 2) AS occupancy_percentage
FROM room_nights
ORDER BY occupancy_percentage DESC;

-- 5. CASE: Categorize reservations by duration
SELECT 
    reservation_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    check_in_date,
    check_out_date,
    (check_out_date - check_in_date) AS nights,
    CASE 
        WHEN (check_out_date - check_in_date) = 1 THEN 'Short Stay'
        WHEN (check_out_date - check_in_date) BETWEEN 2 AND 4 THEN 'Medium Stay'
        WHEN (check_out_date - check_in_date) >= 5 THEN 'Long Stay'
    END AS stay_category
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
ORDER BY nights DESC;

-- 6. AGGREGATION: Monthly revenue report
SELECT 
    TO_CHAR(check_in_date, 'YYYY-MM') AS month,
    COUNT(reservation_id) AS num_reservations,
    SUM(total_amount) AS revenue,
    AVG(total_amount) AS avg_booking_value
FROM reservations
WHERE status IN ('Completed', 'Confirmed')
GROUP BY TO_CHAR(check_in_date, 'YYYY-MM')
ORDER BY month DESC;

-- 7. COMPLEX QUERY: Find available rooms for specific dates
-- This query finds rooms NOT booked between given dates
SELECT 
    r.room_number,
    rt.type_name,
    rt.base_price,
    r.floor
FROM rooms r
JOIN room_types rt ON r.room_type_id = rt.room_type_id
WHERE r.status = 'Available'
  AND r.room_id NOT IN (
    SELECT rr.room_id
    FROM reservation_rooms rr
    JOIN reservations res ON rr.reservation_id = res.reservation_id
    WHERE res.status IN ('Confirmed', 'Completed')
      AND res.check_in_date < '2024-12-15'  -- Your desired checkout
      AND res.check_out_date > '2024-12-10' -- Your desired checkin
  )
ORDER BY rt.base_price;

-- 8. WINDOW FUNCTION: Running total of revenue
SELECT 
    payment_date::DATE,
    amount,
    payment_method,
    SUM(amount) OVER (ORDER BY payment_date::DATE) AS running_total
FROM payments
WHERE status = 'Completed'
ORDER BY payment_date::DATE;