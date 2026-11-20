DECLARE
  e_check_violation EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check_violation, -2290);
BEGIN
  UPDATE demo_customers
     SET first_name = COALESCE(:first_name, first_name)
       , last_name  = COALESCE(:last_name,  last_name)
       , email      = COALESCE(LOWER(:email), email)
       , phone      = COALESCE(:phone,      phone)
       , city       = COALESCE(:city,       city)
       , country    = COALESCE(:country,    country)
       , status     = COALESCE(UPPER(:status), status)
       , updated_at = SYSTIMESTAMP
   WHERE cust_id    = :id
     AND deleted_yn = 'NO';

  IF SQL%ROWCOUNT = 0 THEN
    :status_code := 404;
    :message     := 'Customer not found';
  ELSE
    :status_code := 200;
    :message     := 'Customer updated successfully';
  END IF;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    :status_code := 409;
    :message     := 'Email already belongs to another customer';
  WHEN e_check_violation THEN
    :status_code := 400;
    :message     := 'status must be ACTIVE or INACTIVE';
END;
