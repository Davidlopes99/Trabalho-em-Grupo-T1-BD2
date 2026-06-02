/*
    Teste de validação de transições de estado da coluna status
    da tabela invoice.

    Este script deve ser executado depois do arquivo:
    05_validar_dte.sql

    Estados utilizados:
    - ABERTA
    - PAGA
    - CANCELADA

    Transições permitidas:
    - ABERTA -> PAGA
    - ABERTA -> CANCELADA
    - PAGA   -> CANCELADA

    Transições inválidas:
    - PAGA -> ABERTA
    - CANCELADA -> ABERTA
    - CANCELADA -> PAGA
*/

ALTER TABLE invoice DISABLE TRIGGER trg_validar_status_invoice;

UPDATE invoice
SET status = 'ABERTA'
WHERE invoice_id IN (1, 2, 3, 4, 5, 6, 7);

ALTER TABLE invoice ENABLE TRIGGER trg_validar_status_invoice;

DROP TABLE IF EXISTS resultado_testes_dte;

CREATE TEMP TABLE resultado_testes_dte (
    id SERIAL PRIMARY KEY,
    teste VARCHAR(100),
    transicao VARCHAR(50),
    resultado_esperado VARCHAR(100),
    resultado_obtido VARCHAR(100),
    status_final VARCHAR(20)
);

DO $$
BEGIN
    UPDATE invoice
    SET status = 'PAGA'
    WHERE invoice_id = 1;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 1',
        'ABERTA -> PAGA',
        'Deve permitir',
        'Permitiu corretamente',
        status
    FROM invoice
    WHERE invoice_id = 1;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        VALUES
            ('Teste 1', 'ABERTA -> PAGA', 'Deve permitir', 'Bloqueou incorretamente', NULL);
END;
$$;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'CANCELADA'
    WHERE invoice_id = 2;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 2',
        'ABERTA -> CANCELADA',
        'Deve permitir',
        'Permitiu corretamente',
        status
    FROM invoice
    WHERE invoice_id = 2;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        VALUES
            ('Teste 2', 'ABERTA -> CANCELADA', 'Deve permitir', 'Bloqueou incorretamente', NULL);
END;
$$;

UPDATE invoice
SET status = 'PAGA'
WHERE invoice_id = 3;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'CANCELADA'
    WHERE invoice_id = 3;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 3',
        'PAGA -> CANCELADA',
        'Deve permitir',
        'Permitiu corretamente',
        status
    FROM invoice
    WHERE invoice_id = 3;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        VALUES
            ('Teste 3', 'PAGA -> CANCELADA', 'Deve permitir', 'Bloqueou incorretamente', NULL);
END;
$$;

UPDATE invoice
SET status = 'PAGA'
WHERE invoice_id = 4;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'ABERTA'
    WHERE invoice_id = 4;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 4',
        'PAGA -> ABERTA',
        'Deve bloquear',
        'Permitiu incorretamente',
        status
    FROM invoice
    WHERE invoice_id = 4;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        SELECT
            'Teste 4',
            'PAGA -> ABERTA',
            'Deve bloquear',
            'Bloqueou corretamente',
            status
        FROM invoice
        WHERE invoice_id = 4;
END;
$$;

UPDATE invoice
SET status = 'CANCELADA'
WHERE invoice_id = 5;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'ABERTA'
    WHERE invoice_id = 5;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 5',
        'CANCELADA -> ABERTA',
        'Deve bloquear',
        'Permitiu incorretamente',
        status
    FROM invoice
    WHERE invoice_id = 5;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        SELECT
            'Teste 5',
            'CANCELADA -> ABERTA',
            'Deve bloquear',
            'Bloqueou corretamente',
            status
        FROM invoice
        WHERE invoice_id = 5;
END;
$$;

UPDATE invoice
SET status = 'CANCELADA'
WHERE invoice_id = 6;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'PAGA'
    WHERE invoice_id = 6;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 6',
        'CANCELADA -> PAGA',
        'Deve bloquear',
        'Permitiu incorretamente',
        status
    FROM invoice
    WHERE invoice_id = 6;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        SELECT
            'Teste 6',
            'CANCELADA -> PAGA',
            'Deve bloquear',
            'Bloqueou corretamente',
            status
        FROM invoice
        WHERE invoice_id = 6;
END;
$$;

DO $$
BEGIN
    UPDATE invoice
    SET status = 'ABERTA'
    WHERE invoice_id = 7;

    INSERT INTO resultado_testes_dte
        (teste, transicao, resultado_esperado, resultado_obtido, status_final)
    SELECT
        'Teste 7',
        'ABERTA -> ABERTA',
        'Deve permitir',
        'Permitiu corretamente',
        status
    FROM invoice
    WHERE invoice_id = 7;

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO resultado_testes_dte
            (teste, transicao, resultado_esperado, resultado_obtido, status_final)
        VALUES
            ('Teste 7', 'ABERTA -> ABERTA', 'Deve permitir', 'Bloqueou incorretamente', NULL);
END;
$$;

SELECT
    teste,
    transicao,
    resultado_esperado,
    resultado_obtido,
    status_final
FROM resultado_testes_dte
ORDER BY id;


SELECT
    invoice_id,
    status
FROM invoice
WHERE invoice_id IN (1, 2, 3, 4, 5, 6, 7)
ORDER BY invoice_id;


/*
    RESULTADOS ESPERADOS:

    TABELA resultado_testes_dte:

    Teste 1:
    Transição: ABERTA -> PAGA
    Resultado esperado: Deve permitir
    Resultado obtido esperado: Permitiu corretamente
    Status final esperado: PAGA

    Teste 2:
    Transição: ABERTA -> CANCELADA
    Resultado esperado: Deve permitir
    Resultado obtido esperado: Permitiu corretamente
    Status final esperado: CANCELADA

    Teste 3:
    Transição: PAGA -> CANCELADA
    Resultado esperado: Deve permitir
    Resultado obtido esperado: Permitiu corretamente
    Status final esperado: CANCELADA

    Teste 4:
    Transição: PAGA -> ABERTA
    Resultado esperado: Deve bloquear
    Resultado obtido esperado: Bloqueou corretamente
    Status final esperado: PAGA

    Teste 5:
    Transição: CANCELADA -> ABERTA
    Resultado esperado: Deve bloquear
    Resultado obtido esperado: Bloqueou corretamente
    Status final esperado: CANCELADA

    Teste 6:
    Transição: CANCELADA -> PAGA
    Resultado esperado: Deve bloquear
    Resultado obtido esperado: Bloqueou corretamente
    Status final esperado: CANCELADA

    Teste 7:
    Transição: ABERTA -> ABERTA
    Resultado esperado: Deve permitir
    Resultado obtido esperado: Permitiu corretamente
    Status final esperado: ABERTA
*/
