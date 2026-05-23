SELECT version() AS versao_postgresql;

SELECT current_database() AS banco_atual;

SELECT current_schema() AS esquema_atual;

SELECT
    table_schema AS esquema,
    table_name AS tabela,
    table_type AS tipo
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;