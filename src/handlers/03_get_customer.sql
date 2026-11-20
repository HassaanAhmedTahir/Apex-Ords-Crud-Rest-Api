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
WHERE  cust_id    = :id
AND    deleted_yn = 'NO'
