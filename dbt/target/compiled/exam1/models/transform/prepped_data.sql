SELECT A.ID 
    , FIRST_NAME
    , LAST_NAME
    , birthdate
    , BOOKING_REFERENCE
    , HOTEL
    , BOOKING_DATE
    , COST
FROM KEITA_NAKATA_DB.AIRFLOW_DBT.customer  A
JOIN KEITA_NAKATA_DB.AIRFLOW_DBT.combined_bookings B
on A.ID = B.ID