DECLARE
  e_check_violation EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check_violation, -2290);
  v_cust_id demo_customers.cust_id%TYPE;
BEGIN
  -- 1. Validate required fields
  IF :cust_number IS NULL OR :first_name IS NULL THEN
    :status_code := 400;
    :message     := 'cust_number and first_name are required';
    RETURN;
  END IF;

  -- 2. Insert the row (JSON body fields arrive as bind variables)
  INSERT INTO demo_customers
         (cust_number, first_name, last_name, email, phone, city, country, status)
  VALUES (:cust_number, :first_name, :last_name, LOWER(:email),
          :phone, :city, :country, NVL(UPPER(:status), 'ACTIVE'))
  RETURNING cust_id INTO v_cust_id;

  -- 3. Build the response
  :status_code := 201;
  :cust_id     := v_cust_id;
  :message     := 'Customer created successfully';
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    :status_code := 409;
    :message     := 'Customer number or email already exists';
  WHEN e_check_violation THEN
    :status_code := 400;
    :message     := 'status must be ACTIVE or INACTIVE';
END;
