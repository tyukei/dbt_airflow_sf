
  create or replace   view KEITA_NAKATA_DB.AIRFLOW_DBT.customer
  
   as (
    SELECT ID 
    , FIRST_NAME
    , LAST_NAME
    , birthdate
FROM KEITA_NAKATA_DB.AIRFLOW_DBT.customers
  );

