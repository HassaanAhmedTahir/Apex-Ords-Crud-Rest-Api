SELECT cust_id,
       cust_number,
       first_name,
       last_name,
       email,
       phone,
       city,
       country,
       status,
       created_at,
       updated_at
FROM   demo_customers
WHERE  deleted_yn = 'NO'
AND    (:city IS NULL OR UPPER(city) = UPPER(:city))
ORDER BY cust_id DESC
