BEGIN
  -- Module: the container, owns the base path /demo/
  ORDS.DEFINE_MODULE(
    p_module_name    => 'demo.customers',
    p_base_path      => '/demo/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED',
    p_comments       => 'Demo CRUD API for DEMO_CUSTOMERS');

  -- Templates: the two URL shapes
  ORDS.DEFINE_TEMPLATE(p_module_name => 'demo.customers', p_pattern => 'customers/');
  ORDS.DEFINE_TEMPLATE(p_module_name => 'demo.customers', p_pattern => 'customers/:id');

  -- customers/  ->  GET (list) + POST (create)
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'demo.customers',
    p_pattern        => 'customers/',
    p_method         => 'GET',
    p_source_type    => ORDS.source_type_collection_feed,
    p_items_per_page => 25,
    p_source         => q'[
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
    ]');

  ORDS.DEFINE_HANDLER(
    p_module_name    => 'demo.customers',
    p_pattern        => 'customers/',
    p_method         => 'POST',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => q'[
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
    ]');

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'demo.customers',
    p_pattern            => 'customers/',
    p_method             => 'POST',
    p_name               => 'cust_id',
    p_bind_variable_name => 'cust_id',
    p_source_type        => 'RESPONSE',
    p_param_type         => 'INT',
    p_access_method      => 'OUT');

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'demo.customers',
    p_pattern            => 'customers/',
    p_method             => 'POST',
    p_name               => 'message',
    p_bind_variable_name => 'message',
    p_source_type        => 'RESPONSE',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT');

  -- customers/:id  ->  GET (one) + PUT (update) + DELETE (soft delete)
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'demo.customers',
    p_pattern        => 'customers/:id',
    p_method         => 'GET',
    p_source_type    => ORDS.source_type_collection_item,
    p_source         => q'[
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
    ]');

  ORDS.DEFINE_HANDLER(
    p_module_name    => 'demo.customers',
    p_pattern        => 'customers/:id',
    p_method         => 'PUT',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => q'[
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
    ]');

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'demo.customers',
    p_pattern            => 'customers/:id',
    p_method             => 'PUT',
    p_name               => 'message',
    p_bind_variable_name => 'message',
    p_source_type        => 'RESPONSE',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT');

  ORDS.DEFINE_HANDLER(
    p_module_name    => 'demo.customers',
    p_pattern        => 'customers/:id',
    p_method         => 'DELETE',
    p_source_type    => ORDS.source_type_plsql,
    p_source         => q'[
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
    ]');

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'demo.customers',
    p_pattern            => 'customers/:id',
    p_method             => 'DELETE',
    p_name               => 'message',
    p_bind_variable_name => 'message',
    p_source_type        => 'RESPONSE',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT');

  COMMIT;
END;
/
