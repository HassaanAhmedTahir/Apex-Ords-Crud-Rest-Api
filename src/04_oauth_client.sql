DECLARE
  l_roles    OWA.VC_ARR;
  l_patterns OWA.VC_ARR;
BEGIN
  ORDS.CREATE_ROLE(p_role_name => 'demo_api_role');

  l_roles(1)    := 'demo_api_role';
  l_patterns(1) := '/demo/*';

  ORDS.DEFINE_PRIVILEGE(
    p_privilege_name => 'demo.api.privilege',
    p_roles          => l_roles,
    p_patterns       => l_patterns,
    p_label          => 'Demo Customers API',
    p_description    => 'Protects all /demo/ endpoints');
  COMMIT;
END;
/

BEGIN
  OAUTH.CREATE_CLIENT(
    p_name            => 'demo_client',
    p_grant_type      => 'client_credentials',
    p_owner           => 'Demo Owner',
    p_description     => 'Client for the demo customers API',
    p_support_email   => 'support@example.com',
    p_privilege_names => 'demo.api.privilege');

  OAUTH.GRANT_CLIENT_ROLE(
    p_client_name => 'demo_client',
    p_role_name   => 'demo_api_role');
  COMMIT;
END;
/

SELECT client_id, client_secret
FROM   user_ords_clients
WHERE  name = 'demo_client';
