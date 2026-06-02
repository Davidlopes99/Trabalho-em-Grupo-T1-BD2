/*
    Questão 5:
    Implemente uma solução através da programação em banco de dados para validar os
    valores de uma coluna que represente uma situação (estado) garantindo que os seus
    valores e suas transições atendam a especificação de um diagrama de transição de
    estados (DTE). Quanto mais genérica e reutilizável for a solução melhor a pontuação
    nessa questão.
*/

ALTER TABLE invoice
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ABERTA' NOT NULL;

DROP TRIGGER IF EXISTS trg_validar_status_invoice ON invoice;

DROP FUNCTION IF EXISTS validar_transicao_estado();

DROP TABLE IF EXISTS regra_transicao_estado;

CREATE TABLE regra_transicao_estado (
    id SERIAL PRIMARY KEY,
    nome_tabela VARCHAR(100) NOT NULL,
    nome_coluna VARCHAR(100) NOT NULL,
    estado_origem VARCHAR(50) NOT NULL,
    estado_destino VARCHAR(50) NOT NULL,

    CONSTRAINT uq_regra_transicao UNIQUE
    (
        nome_tabela,
        nome_coluna,
        estado_origem,
        estado_destino
    )
);

INSERT INTO regra_transicao_estado
    (nome_tabela, nome_coluna, estado_origem, estado_destino)
VALUES
    ('invoice', 'status', 'ABERTA', 'PAGA'),
    ('invoice', 'status', 'ABERTA', 'CANCELADA'),
    ('invoice', 'status', 'PAGA', 'CANCELADA');

CREATE OR REPLACE FUNCTION validar_transicao_estado()
RETURNS TRIGGER AS $$
DECLARE
    coluna_estado TEXT;
    estado_antigo TEXT;
    estado_novo TEXT;
    existe_regra INT;
BEGIN
    coluna_estado := TG_ARGV[0];

    estado_antigo := to_jsonb(OLD) ->> coluna_estado;
    estado_novo := to_jsonb(NEW) ->> coluna_estado;

    IF estado_antigo = estado_novo THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*)
    INTO existe_regra
    FROM regra_transicao_estado
    WHERE nome_tabela = TG_TABLE_NAME
      AND nome_coluna = coluna_estado
      AND estado_origem = estado_antigo
      AND estado_destino = estado_novo;

    IF existe_regra = 0 THEN
        RAISE EXCEPTION
            'Transição de estado inválida: %.% não pode mudar de "%" para "%"',
            TG_TABLE_NAME,
            coluna_estado,
            estado_antigo,
            estado_novo;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

UPDATE invoice
SET status = 'ABERTA'
WHERE invoice_id = 1;

CREATE TRIGGER trg_validar_status_invoice
BEFORE UPDATE OF status ON invoice
FOR EACH ROW
EXECUTE FUNCTION validar_transicao_estado('status');

SELECT invoice_id, status
FROM invoice
WHERE invoice_id = 1;

UPDATE invoice
SET status = 'PAGA'
WHERE invoice_id = 1;

SELECT invoice_id, status
FROM invoice
WHERE invoice_id = 1;

UPDATE invoice
SET status = 'CANCELADA'
WHERE invoice_id = 1;

SELECT invoice_id, status
FROM invoice
WHERE invoice_id = 1;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'ABERTA'
    WHERE invoice_id = 1;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Teste de transição inválida executado com sucesso. Erro gerado: %', SQLERRM;
END;
$$;

SELECT invoice_id, status
FROM invoice
WHERE invoice_id = 1;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'PAGA'
    WHERE invoice_id = 1;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Teste de transição inválida executado com sucesso. Erro gerado: %', SQLERRM;
END;
$$;

SELECT invoice_id, status
FROM invoice
WHERE invoice_id = 1;

SELECT *
FROM regra_transicao_estado
ORDER BY id;
