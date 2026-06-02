\pset pager off

/*
    Questão 1:
    Consultar as tabelas de catálogo para listar todos os índices existentes
    acompanhados das tabelas e colunas indexadas pelo mesmo.
*/

SELECT
    ns.nspname AS esquema,
    tab.relname AS tabela,
    idx.relname AS indice,
    ix.indisunique AS unico,
    ix.indisprimary AS chave_primaria,
    string_agg(col.attname, ', ' ORDER BY col.attnum) AS colunas
FROM pg_index ix
JOIN pg_class tab
    ON tab.oid = ix.indrelid
JOIN pg_class idx
    ON idx.oid = ix.indexrelid
JOIN pg_namespace ns
    ON ns.oid = tab.relnamespace
JOIN pg_attribute col
    ON col.attrelid = tab.oid
   AND col.attnum = ANY(ix.indkey)
WHERE ns.nspname = 'public'

GROUP BY
    ns.nspname,
    tab.relname,
    idx.relname,
    ix.indisunique,
    ix.indisprimary

ORDER BY
    tab.relname,
    idx.relname;