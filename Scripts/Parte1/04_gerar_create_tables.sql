/*
    Banco de Dados II
    Questão 4 - Criar usando a linguagem de programação do SGBD escolhido um script que construa
    de forma dinâmica a partir do catálogo os comandos create table das tabelas
    existentes no esquema exemplo considerando pelo menos as informações sobre
    colunas (nome, tipo e obrigatoriedade) e chaves primárias e estrangeiras.
*/

\pset pager off

DROP FUNCTION IF EXISTS public.gerar_create_tables(TEXT);

CREATE OR REPLACE FUNCTION public.gerar_create_tables(p_schema TEXT DEFAULT 'public')
RETURNS TABLE (
    tabela TEXT,
    comando_create TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    r_tabela RECORD;
    v_colunas TEXT;
    v_constraints TEXT;
    v_sql TEXT;
BEGIN
    FOR r_tabela IN
        SELECT
            c.oid AS tabela_oid,
            n.nspname AS schema_name,
            c.relname AS table_name
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema
          AND c.relkind = 'r'
        ORDER BY c.relname
    LOOP
        /*
            1) Colunas:
               - nome da coluna;
               - tipo da coluna;
               - obrigatoriedade.
        */
        SELECT string_agg(
                   '    ' || quote_ident(a.attname) || ' ' ||
                   pg_catalog.format_type(a.atttypid, a.atttypmod) ||
                   CASE
                       WHEN a.attnotnull THEN ' NOT NULL'
                       ELSE ''
                   END,
                   E',\n'
                   ORDER BY a.attnum
               )
        INTO v_colunas
        FROM pg_catalog.pg_attribute a
        WHERE a.attrelid = r_tabela.tabela_oid
          AND a.attnum > 0
          AND NOT a.attisdropped;

        /*
            2) Restrições:
               - chave primária;
               - chaves estrangeiras.

        */
        SELECT string_agg(
                   '    CONSTRAINT ' || quote_ident(con.conname) || ' ' ||
                   pg_catalog.pg_get_constraintdef(con.oid, true),
                   E',\n'
                   ORDER BY
                       CASE con.contype
                           WHEN 'p' THEN 1
                           WHEN 'f' THEN 2
                           ELSE 3
                       END,
                       con.conname
               )
        INTO v_constraints
        FROM pg_catalog.pg_constraint con
        WHERE con.conrelid = r_tabela.tabela_oid
          AND con.contype IN ('p', 'f');

        /*
            3) Montagem final do CREATE TABLE.
        */
        v_sql :=
            'CREATE TABLE ' ||
            quote_ident(r_tabela.schema_name) || '.' || quote_ident(r_tabela.table_name) ||
            E'\n(\n' ||
            v_colunas;

        IF v_constraints IS NOT NULL THEN
            v_sql := v_sql || E',\n' || v_constraints;
        END IF;

        v_sql := v_sql || E'\n);';

        tabela := r_tabela.table_name;
        comando_create := v_sql;

        RETURN NEXT;
    END LOOP;
END;
$$;

SELECT
    tabela,
    comando_create
FROM public.gerar_create_tables('public')
ORDER BY tabela;
