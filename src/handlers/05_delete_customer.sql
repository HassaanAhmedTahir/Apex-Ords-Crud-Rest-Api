BEGIN
  UPDATE demo_customers
     SET deleted_yn = 'YES'
       , status     = 'INACTIVE'
       , updated_at = SYSTIMESTAMP
   WHERE cust_id    = :id
     AND deleted_yn = 'NO';

  IF SQL%ROWCOUNT = 0 THEN
    :status_code := 404;
    :message     := 'Customer not found or already deleted';
  ELSE
    :status_code := 200;
    :message     := 'Customer deleted successfully';
  END IF;
END;
