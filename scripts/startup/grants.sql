 Donner accès aux tables à BK_API
-- Connexion : BK_ORDS
-- ============================================================

ALTER SESSION SET CONTAINER = FREEPDB1;
--CONN bk_ords/bk_ords@FREEPDB1;

GRANT SELECT ON bk_ords.tr_all TO bk_api;
GRANT SELECT ON bk_ords.tr_retall TO bk_api;

COMMIT;
EXIT;