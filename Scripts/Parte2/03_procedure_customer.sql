/************************
  PARTE 3 — Stored Procedures + Controle de Permissões
  Regra Semântica 2: e-mail de cliente deve ser único e obrigatório.
  A manipulação da tabela customer só é permitida via procedure.
************************/

/* ===================================================================
   PASSO 1 — Criar o usuário restrito
   =================================================================== */
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'usr_customer_app'
    ) THEN
        CREATE ROLE usr_customer_app LOGIN PASSWORD 'SenhaForte#2025';
    END IF;
END
$$;

-- Garante que o usuário NÃO tenha acesso direto à tabela
REVOKE ALL PRIVILEGES ON TABLE customer FROM usr_customer_app;

-- Concede acesso ao schema para que o usuário consiga "enxergar" os objetos
GRANT USAGE ON SCHEMA public TO usr_customer_app;


/* ===================================================================
   PASSO 2 — Procedure: inserir cliente com validação de e-mail único
   =================================================================== */
CREATE OR REPLACE PROCEDURE sp_inserir_customer(
    p_customer_id    INTEGER,
    p_first_name     VARCHAR,
    p_last_name      VARCHAR,
    p_email          VARCHAR,
    p_company        VARCHAR  DEFAULT NULL,
    p_address        VARCHAR  DEFAULT NULL,
    p_city           VARCHAR  DEFAULT NULL,
    p_state          VARCHAR  DEFAULT NULL,
    p_country        VARCHAR  DEFAULT NULL,
    p_postal_code    VARCHAR  DEFAULT NULL,
    p_phone          VARCHAR  DEFAULT NULL,
    p_fax            VARCHAR  DEFAULT NULL,
    p_support_rep_id INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
SECURITY DEFINER -- <--- CRUCIAL: Faz a procedure rodar com os poderes do criador
AS $$
BEGIN
    -- Regra semântica 2a: e-mail é obrigatório
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        RAISE EXCEPTION
            'Regra semântica violada: o e-mail do cliente não pode ser nulo ou vazio.';
    END IF;

    -- Regra semântica 2b: e-mail deve ser único
    IF EXISTS (
        SELECT 1 FROM customer WHERE email = p_email
    ) THEN
        RAISE EXCEPTION
            'Regra semântica violada: o e-mail "%" já está cadastrado para outro cliente.',
            p_email;
    END IF;

    -- Inserção segura
    INSERT INTO customer (
        customer_id, first_name, last_name, company,
        address, city, state, country, postal_code,
        phone, fax, email, support_rep_id
    ) VALUES (
        p_customer_id, p_first_name, p_last_name, p_company,
        p_address, p_city, p_state, p_country, p_postal_code,
        p_phone, p_fax, p_email, p_support_rep_id
    );

    RAISE NOTICE 'Cliente % % inserido com sucesso (id=%).', 
        p_first_name, p_last_name, p_customer_id;
END;
$$;


/* ===================================================================
   PASSO 3 — Procedure: atualizar e-mail do cliente com mesma validação
   =================================================================== */
CREATE OR REPLACE PROCEDURE sp_atualizar_email_customer(
    p_customer_id INTEGER,
    p_novo_email  VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER -- <--- CRUCIAL: Permite que o usuário restrito atualize via proc
AS $$
BEGIN
    -- Verifica se o cliente existe
    IF NOT EXISTS (
        SELECT 1 FROM customer WHERE customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION
            'Cliente com id % não encontrado.', p_customer_id;
    END IF;

    -- Regra semântica 2a: e-mail é obrigatório
    IF p_novo_email IS NULL OR TRIM(p_novo_email) = '' THEN
        RAISE EXCEPTION
            'Regra semântica violada: o e-mail do cliente não pode ser nulo ou vazio.';
    END IF;

    -- Regra semântica 2b: novo e-mail não pode já pertencer a outro cliente
    IF EXISTS (
        SELECT 1 FROM customer
        WHERE email = p_novo_email
          AND customer_id <> p_customer_id
    ) THEN
        RAISE EXCEPTION
            'Regra semântica violada: o e-mail "%" já está cadastrado para outro cliente.',
            p_novo_email;
    END IF;

    UPDATE customer
    SET email = p_novo_email
    WHERE customer_id = p_customer_id;

    RAISE NOTICE 'E-mail do cliente id=% atualizado para "%".', 
        p_customer_id, p_novo_email;
END;
$$;


/* ===================================================================
   PASSO 4 — Conceder EXECUTE nas procedures ao usuário restrito
   =================================================================== */
GRANT EXECUTE ON PROCEDURE sp_inserir_customer(
    INTEGER, VARCHAR, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR, INTEGER
) TO usr_customer_app;

GRANT EXECUTE ON PROCEDURE sp_atualizar_email_customer(
    INTEGER, VARCHAR
) TO usr_customer_app;


/* ===================================================================
   PASSO 5 — Testes (Simulando o ambiente real do usuário restrito)
   =================================================================== */

-- Vamos mudar o papel atual para o usuário restrito para provar que funciona
SET ROLE usr_customer_app;

-- TESTE EXTRA: Tentar dar um SELECT ou INSERT direto na tabela (DEVE FALHAR por falta de privilégio)
-- SELECT * FROM customer; 

-- TESTE 1: inserção válida via procedure — DEVE FUNCIONAR por causa do SECURITY DEFINER
CALL sp_inserir_customer(
    999, 'Maria', 'Silva', 'maria.silva@email.com',
    'Empresa X', 'Rua das Flores, 123', 'Niterói', 'RJ', 'Brazil', '24000-000',
    '+55 21 99999-0001', NULL, NULL
);

-- TESTE 2: e-mail duplicado — deve lançar exceção
CALL sp_inserir_customer(
    998, 'João', 'Souza', 'maria.silva@email.com'
);

-- TESTE 3: e-mail nulo — deve lançar exceção
CALL sp_inserir_customer(
    997, 'Carlos', 'Lima', NULL
);

-- TESTE 4: atualização com e-mail já usado por outro cliente — deve lançar exceção
CALL sp_atualizar_email_customer(1, 'maria.silva@email.com');

-- TESTE 5: atualização válida — deve funcionar
CALL sp_atualizar_email_customer(999, 'maria.novo@email.com');

-- Voltamos para o usuário administrador para fazer a limpeza
RESET ROLE;

-- Limpeza do cliente de teste
DELETE FROM customer WHERE customer_id = 999;

SELECT 'Parte 3 implementada e testada com sucesso.' AS status;
