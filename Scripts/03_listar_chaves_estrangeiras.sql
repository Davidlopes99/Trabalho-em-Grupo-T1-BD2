/* Questão 3: Consultar as tabelas de catálogo para listar todas as chaves estrangeiras existentes
informando as tabelas e colunas envolvidas. */

SELECT
    c.conname AS constraint_name,
    t1.relname AS table_name,
    a1.attname AS column_name,
    t2.relname AS foreign_table_name,
    a2.attname AS foreign_column_name
FROM
    pg_catalog.pg_constraint c
JOIN pg_catalog.pg_class t1 ON t1.oid = c.conrelid
JOIN pg_catalog.pg_class t2 ON t2.oid = c.confrelid
JOIN pg_catalog.pg_attribute a1 ON a1.attnum = ANY(c.conkey) AND a1.attrelid = c.conrelid
JOIN pg_catalog.pg_attribute a2 ON a2.attnum = ANY(c.confkey) AND a2.attrelid = c.confrelid
WHERE
    c.contype = 'f' -- Tipo 'f' = Foreign Key
ORDER BY
    t1.relname, c.conname;
