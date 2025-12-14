import streamlit as st
import psycopg2
import pandas as pd
from datetime import date, timedelta

# Database connection
@st.cache_resource
def get_connection():
    return psycopg2.connect(
        dbname="hotel_reservation_db",
        user="postgres",
        password="3777",  
        host="localhost",
        port="5432"
    )

conn = get_connection()

st.title("🏨 Luxury Hotel Reservation System")

# Function to load data WITHOUT caching for real-time updates
def load_available_rooms():
    query = """
            SELECT r.room_number, rt.type_name, rt.base_price, rt.capacity, r.floor
            FROM rooms r
                     JOIN room_types rt ON r.room_type_id = rt.room_type_id
            WHERE r.status = 'Available'
            ORDER BY r.room_number \
            """
    return pd.read_sql(query, conn)

def load_current_reservations():
    query = """
            SELECT
                res.reservation_id,
                g.first_name || ' ' || g.last_name AS guest_name,
                g.email,
                res.check_in_date,
                res.check_out_date,
                res.total_amount,
                res.status,
                STRING_AGG(r.room_number, ', ') AS rooms_booked
            FROM reservations res
                     JOIN guests g ON res.guest_id = g.guest_id
                     LEFT JOIN reservation_rooms rr ON res.reservation_id = rr.reservation_id
                     LEFT JOIN rooms r ON rr.room_id = r.room_id
            WHERE res.status IN ('Confirmed', 'Completed')
            GROUP BY res.reservation_id, g.first_name, g.last_name, g.email,
                     res.check_in_date, res.check_out_date, res.total_amount, res.status
            ORDER BY res.check_in_date DESC \
            """
    return pd.read_sql(query, conn)

def load_guests():
    query = "SELECT guest_id, first_name, last_name, email, phone FROM guests ORDER BY last_name, first_name"
    return pd.read_sql(query, conn)

# Create tabs
tab1, tab2, tab3, tab4 = st.tabs(["📋 Available Rooms", "➕ New Guest", "🎫 New Reservation", "📜 Current Reservations"])

# TAB 1: Available Rooms
with tab1:
    st.header("Available Rooms")
    rooms_df = load_available_rooms()
    if not rooms_df.empty:
        st.dataframe(rooms_df, use_container_width=True)
    else:
        st.warning("No rooms currently available")

    if st.button("🔄 Refresh Rooms"):
        st.rerun()

# TAB 2: Add New Guest
with tab2:
    st.header("Add New Guest")

    with st.form("new_guest_form"):
        col1, col2 = st.columns(2)
        first_name = col1.text_input("First Name*", key="guest_first")
        last_name = col2.text_input("Last Name*", key="guest_last")

        col3, col4 = st.columns(2)
        email = col3.text_input("Email*", key="guest_email")
        phone = col4.text_input("Phone*", key="guest_phone")

        address = st.text_input("Address (Optional)", key="guest_address")

        submit_guest = st.form_submit_button("➕ Add Guest")

        if submit_guest:
            if not all([first_name, last_name, email, phone]):
                st.error("Please fill in all required fields (*)")
            else:
                try:
                    with conn.cursor() as cur:
                        cur.execute("""
                                    INSERT INTO guests (first_name, last_name, email, phone, address)
                                    VALUES (%s, %s, %s, %s, %s)
                                        RETURNING guest_id
                                    """, (first_name, last_name, email, phone, address if address else None))
                        guest_id = cur.fetchone()[0]
                        conn.commit()
                    st.success(f"✅ Guest added successfully! Guest ID: {guest_id}")
                    st.balloons()
                except psycopg2.IntegrityError:
                    conn.rollback()
                    st.error("⚠️ A guest with this email already exists!")
                except Exception as e:
                    conn.rollback()
                    st.error(f"❌ Error adding guest: {e}")

    # Show current guests
    st.subheader("Current Guests")
    guests_df = load_guests()
    st.dataframe(guests_df, use_container_width=True)

# TAB 3: New Reservation
with tab3:
    st.header("Make a New Reservation")

    # Load guests for selection
    guests_df = load_guests()

    if guests_df.empty:
        st.warning("⚠️ No guests in the system. Please add a guest first in the 'New Guest' tab.")
    else:
        guest_options = {f"{row['first_name']} {row['last_name']} ({row['email']})": row['guest_id']
                         for _, row in guests_df.iterrows()}

        selected_guest_name = st.selectbox("Select Guest*", options=list(guest_options.keys()))
        guest_id = guest_options[selected_guest_name]

        col1, col2 = st.columns(2)
        check_in = col1.date_input("Check-in Date*", date.today())
        check_out = col2.date_input("Check-out Date*", date.today() + timedelta(days=3))

        if st.button("🔍 Search Available Rooms"):
            if check_out <= check_in:
                st.error("❌ Check-out date must be after check-in date")
            else:
                with conn.cursor() as cur:
                    cur.execute("""
                                SELECT r.room_id, r.room_number, rt.type_name, rt.base_price, rt.capacity, r.floor
                                FROM rooms r
                                         JOIN room_types rt ON r.room_type_id = rt.room_type_id
                                WHERE r.status = 'Available'
                                  AND r.room_id NOT IN (
                                    SELECT rr.room_id
                                    FROM reservation_rooms rr
                                             JOIN reservations res ON rr.reservation_id = res.reservation_id
                                    WHERE res.status = 'Confirmed'
                                      AND res.check_in_date < %s
                                      AND res.check_out_date > %s
                                )
                                ORDER BY r.room_number
                                """, (check_out, check_in))
                    rooms = cur.fetchall()

                    if rooms:
                        rooms_df = pd.DataFrame(rooms, columns=["room_id", "room_number", "type", "price", "capacity", "floor"])

                        st.success(f"✅ Found {len(rooms_df)} available rooms")
                        st.dataframe(rooms_df[['room_number', 'type', 'price', 'capacity', 'floor']], use_container_width=True)

                        # Store in session state
                        st.session_state['available_rooms'] = rooms_df
                        st.session_state['check_in'] = check_in
                        st.session_state['check_out'] = check_out
                        st.session_state['guest_id'] = guest_id
                    else:
                        st.warning("😔 No rooms available for these dates")

        # Booking section (only show if rooms were searched)
        if 'available_rooms' in st.session_state and not st.session_state['available_rooms'].empty:
            st.divider()
            st.subheader("Complete Booking")

            rooms_df = st.session_state['available_rooms']
            selected_room_num = st.selectbox("Select Room to Book*", rooms_df['room_number'].tolist())
            selected_room = rooms_df[rooms_df['room_number'] == selected_room_num].iloc[0]

            nights = (st.session_state['check_out'] - st.session_state['check_in']).days
            total = nights * selected_room['price']

            col1, col2, col3 = st.columns(3)
            col1.metric("Nights", nights)
            col2.metric("Price per Night", f"${selected_room['price']:.2f}")
            col3.metric("Total Amount", f"${total:.2f}")

            if st.button("✅ Confirm Booking", type="primary"):
                try:
                    with conn.cursor() as cur:
                        # Insert reservation (convert numpy types to Python types)
                        cur.execute("""
                                    INSERT INTO reservations (guest_id, check_in_date, check_out_date, total_amount, status)
                                    VALUES (%s, %s, %s, %s, 'Confirmed')
                                        RETURNING reservation_id
                                    """, (int(st.session_state['guest_id']), st.session_state['check_in'],
                                          st.session_state['check_out'], float(total)))
                        res_id = cur.fetchone()[0]

                        # Link room to reservation (convert numpy int64 to Python int)
                        cur.execute("""
                                    INSERT INTO reservation_rooms (reservation_id, room_id)
                                    VALUES (%s, %s)
                                    """, (res_id, int(selected_room['room_id'])))

                        conn.commit()

                    st.success(f"🎉 Booking confirmed! Reservation ID: #{res_id}")
                    st.balloons()

                    # Clear session state
                    for key in ['available_rooms', 'check_in', 'check_out', 'guest_id']:
                        if key in st.session_state:
                            del st.session_state[key]

                    st.info("👉 View your reservation in the 'Current Reservations' tab")

                except Exception as e:
                    conn.rollback()
                    st.error(f"❌ Booking failed: {e}")

# TAB 4: Current Reservations
with tab4:
    st.header("Current Reservations")

    reservations_df = load_current_reservations()

    if not reservations_df.empty:
        st.dataframe(reservations_df, use_container_width=True)

        st.divider()
        st.subheader("Cancel a Reservation")

        # Create a more readable display for selection
        res_options = {f"#{row['reservation_id']} - {row['guest_name']} ({row['check_in_date']} to {row['check_out_date']})": row['reservation_id']
                       for _, row in reservations_df.iterrows()}

        selected_res_display = st.selectbox("Select reservation to cancel", options=list(res_options.keys()))
        res_to_cancel = res_options[selected_res_display]

        if st.button("🗑️ Cancel Reservation", type="secondary"):
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                                UPDATE reservations SET status = 'Cancelled' WHERE reservation_id = %s
                                """, (res_to_cancel,))
                    conn.commit()
                st.success(f"✅ Reservation #{res_to_cancel} has been cancelled")
                st.rerun()
            except Exception as e:
                conn.rollback()
                st.error(f"❌ Error cancelling reservation: {e}")
    else:
        st.info("📭 No current reservations")

    if st.button("🔄 Refresh Reservations"):
        st.rerun()

# Sidebar
st.sidebar.success("✨ Live System")
st.sidebar.info("💡 Tip: Use the refresh buttons to see real-time updates!")
if st.sidebar.button("🔄 Refresh All Data"):
    st.rerun()