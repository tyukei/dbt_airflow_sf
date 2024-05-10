
  create or replace   view KEITA_NAKATA_DB.AIRFLOW_DBT.hotel_count_by_day
  
   as (
    SELECT
  BOOKING_DATE,
  HOTEL,
  COUNT(ID) as count_bookings
FROM KEITA_NAKATA_DB.AIRFLOW_DBT.prepped_data
GROUP BY
  BOOKING_DATE,
  HOTEL
  );

