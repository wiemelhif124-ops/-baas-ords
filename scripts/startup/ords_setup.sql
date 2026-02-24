-- ============================================================
-- SCRIPT  : ORDS - Enable Schema, Module, Template, Handler,
--             Rôle, Privilège, OAuth Client
-- Connexion : BK_ORDS
-- ============================================================
---CONN / AS SYSDBA;
ALTER SESSION SET CONTAINER = FREEPDB1;

-- ==================== ÉTAPE 1 : Activer le schéma ORDS ====================
BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'BK_ORDS',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'bk_ords',
    p_auto_rest_auth      => TRUE
  );
  COMMIT;
END;
/

-- ==================== ÉTAPE 2 : Définir le Module TR_ALL ====================
BEGIN
    ORDS.DEFINE_MODULE(
        p_module_name => 'TR_ALL.module',
        p_base_path => '/TRALL/',
        p_items_per_page=> 25,
        p_status => 'PUBLISHED',
        p_comments=> ''
    );
    
END;
/

-- ==================== ÉTAPE 3 : Définir le Template ====================
BEGIN
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'TR_ALL.module',
        p_pattern => 'TRALL/',
        p_priority => 0,
        p_etag_type => 'HASH',
        p_comments => ''
    );
    
END;

/

-- ==================== ÉTAPE 4 : Définir le Handler (GET) ====================
BEGIN
    ORDS.DEFINE_HANDLER(
        p_module_name => 'TR_ALL.module',
        p_pattern => 'TRALL/',
        p_method => 'GET',
        p_source_type => ords.source_type_collection_feed,
        p_source => 'SELECT
  a.CODEIDENTIFIANT,
  a.NOM,
  a.PRENOM,
  a.TYPEIDENTIFIANT,
  a.CATEGBENIF,
  a.AGE,
  a.NATIONALITE,
  a.AGENCE,
  a.DATE_EXTRACT,
  a.PERIODDEC,
  (
    SELECT JSON_ARRAYAGG(
             JSON_OBJECT(
               ''''codpaysdest''''        VALUE a2.CODPAYSDEST,
               ''''ecosalaire''''         VALUE a2.ECOSALAIRE,
               ''''moddeliv''''           VALUE a2.MODDELIV,
               ''''mntalloctourdev''''    VALUE a2.MNTALLOCTOURDEV,
               ''''devise''''             VALUE a2.DEVISE,
               ''''mntalloc''''           VALUE a2.MNTALLOC,
               ''''datdelivalloctour''''  VALUE a2.DATDELIVALLOCTOUR,
               ''''numautbctsd''''        VALUE a2.NUMAUTBCTSD,
               ''''datautbctsd''''        VALUE a2.DATAUTBCTSD,
               ''''numautbct''''          VALUE a2.NUMAUTBCT,
               ''''dateautbct''''         VALUE a2.DATEAUTBCT,
               ''''cli1''''               VALUE a2.CLI1,
               ''''age1''''               VALUE a2.AGE1,
               ''''ope''''                VALUE a2.OPE,
               ''''eve''''                VALUE a2.EVE,
               ''''retrocessions''''      VALUE (
                 SELECT JSON_ARRAYAGG(
                          JSON_OBJECT(
                            ''''natop''''                 VALUE r.NATOP,
                            ''''cadretro''''              VALUE r.CADRETRO,
                            ''''datretro''''              VALUE r.DATRETRO,
                            ''''mntretrodev''''           VALUE r.MNTRETRODEV,
                            ''''devmntretro''''           VALUE r.DEVMNTRETRO,
                            ''''cvmntretro''''            VALUE r.CVMNTRETRO,
                            ''''numautbctsd''''           VALUE r.NUMAUTBCTSD,
                            ''''datautbctsd''''           VALUE r.DATAUTBCTSD,
                            ''''datretvoy''''             VALUE r.DATRETVOY,
                            ''''numdecd''''               VALUE r.NUMDECD,
                            ''''datdecd''''               VALUE r.DATDECD,
                            ''''datdelivalloctouris''''   VALUE r.DATDELIVALLOCTOURIS
                          ) RETURNING JSON
                        )
                 FROM TR_RETALL r
                 WHERE r.CODEIDENTIFIANT = a2.CODEIDENTIFIANT
                   AND r.PERIODDEC = a2.PERIODDEC
                   AND r.AGENCE = a2.AGENCE
                   AND NVL(r.CLI, a2.CLI1) = a2.CLI1
               )
             ) RETURNING JSON
           )
    FROM TR_ALL a2
    WHERE a2.CODEIDENTIFIANT = a.CODEIDENTIFIANT
      AND a2.PERIODDEC = a.PERIODDEC
      AND a2.AGENCE = a.AGENCE
  ) AS allocations
FROM (
  SELECT DISTINCT 
    CODEIDENTIFIANT,
    NOM,
    PRENOM,
    TYPEIDENTIFIANT,
    CATEGBENIF,
    AGE,
    NATIONALITE,
    AGENCE,
    DATE_EXTRACT,
    PERIODDEC
  FROM TR_ALL
  WHERE :CODEIDENTIFIANT IS NULL OR TRIM(CODEIDENTIFIANT) = :CODEIDENTIFIANT
) a
ORDER BY a.CODEIDENTIFIANT, a.PERIODDEC',
        p_items_per_page => 7,
        p_comments => ''
    );
    
END;
/

-- ==================== ÉTAPE 5 : Créer le Rôle ====================
BEGIN
   ORDS.CREATE_ROLE(P_ROLE_NAME => 'ROLE_TR_ALL');
    
END;
/

-- ==================== ÉTAPE 6 : Créer le Privilège ====================
DECLARE
L_PRIV_ROLES owa.vc_arr;
L_PRIV_PATTERNS owa.vc_arr;
L_PRIV_MODULES owa.vc_arr;
BEGIN
L_PRIV_ROLES( 1 ) := 'ROLE_TR_ALL';
L_PRIV_MODULES( 1 ) := 'TR_ALL.module';
ORDS.DEFINE_PRIVILEGE(
    P_PRIVILEGE_NAME => 'TR_ALL.module.privilege',
    P_ROLES => L_PRIV_ROLES,
    P_PATTERNS =>  L_PRIV_PATTERNS,
    P_MODULES => L_PRIV_MODULES,
    P_LABEL => 'TR_ALL module privilege',
    P_DESCRIPTION => 'A Privilege created for demonstrating privileges for the TR_ALL.module Resource Module.',
    P_COMMENTS=> ''
);

END;
/

-- ==================== ÉTAPE 7 : Créer le Client OAuth ====================
BEGIN
    OAUTH.CREATE_CLIENT(
        P_NAME            => 'bk_oauth_TR_ALL',
        P_GRANT_TYPE      => 'client_credentials',
        P_OWNER           => 'BK_ORDS',
        P_DESCRIPTION     => 'OAuth 2.0 client used to securely access the TR_ALL REST module in Oracle REST Data Services.',
        P_SUPPORT_EMAIL   => 'support@bk.com',
        P_SUPPORT_URI     => 'https://bk.com',
        P_PRIVILEGE_NAMES => 'TR_ALL.module.privilege'
    );
    COMMIT;
END;
/

COMMIT;
EXIT;