SELECT
  BOOKING_DATE,
  HOTEL,
  COUNT(ID) as count_bookings
FROM KEITA_NAKATA_DB.AIRFLOW_DBT.prepped_data
GROUP BY
  BOOKING_DATE,
  HOTEL