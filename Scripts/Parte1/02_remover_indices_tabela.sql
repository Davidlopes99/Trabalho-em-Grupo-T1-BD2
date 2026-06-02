(criar procedimento que deleta o indice)

CREATE OR REPLACE PROCEDURE public.remover_indices_tabela(p_nome_tabela TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_registro RECORD;
    v_sql TEXT;
BEGIN
    
    FOR v_registro IN 
        SELECT idx.relname AS indice_nome
        FROM pg_index ix
        JOIN pg_class tab ON tab.oid = ix.indrelid
        JOIN pg_class idx ON idx.oid = ix.indexrelid
        JOIN pg_namespace ns ON ns.oid = tab.relnamespace
        WHERE tab.relname = p_nome_tabela
          AND ns.nspname = 'public'
          
          AND ix.indisprimary = FALSE 
    LOOP
       
        v_sql := 'DROP INDEX IF EXISTS public.' || quote_ident(v_registro.indice_nome);
        
        RAISE NOTICE 'Removendo o índice: %', v_registro.indice_nome;
        
        
        EXECUTE v_sql;
    END LOOP;
    
    RAISE NOTICE 'Todos os índices customizados da tabela "%" foram removidos com sucesso.', p_nome_tabela;
END;
$$;

(chamar procedimento escolhendo a tabela)

CALL public.remover_indices_tabela('nome da tabela');
