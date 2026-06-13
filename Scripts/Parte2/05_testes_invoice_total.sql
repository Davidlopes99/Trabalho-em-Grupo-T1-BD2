/**********************************************************************
TESTES DA REGRA SEMÂNTICA:

invoice.total =
SUM(invoice_line.unit_price * invoice_line.quantity)

Executar este arquivo após:
04_trigger_invoice_total.sql
**********************************************************************/


BEGIN;


-- ====================================================================
-- 1. Preparação
-- ====================================================================

/*
    Guarda o próximo identificador disponível para invoice_line.

    O valor será reutilizado nos testes de INSERT, UPDATE e DELETE.
*/

CREATE TEMP TABLE dados_teste_invoice AS
SELECT
    COALESCE(MAX(invoice_line_id), 0) + 1 AS invoice_line_id_teste
FROM invoice_line;


SELECT
    i.invoice_id,
    i.total AS total_armazenado,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'TESTE APROVADO'
        ELSE 'TESTE REPROVADO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY
    i.invoice_id,
    i.total;

/*
Resultado esperado:
- total_armazenado igual a total_calculado;
- resultado igual a TESTE APROVADO.
*/


-- ====================================================================
-- TESTE 2
-- INSERT de uma nova invoice_line
-- ====================================================================

INSERT INTO invoice_line (
    invoice_line_id,
    invoice_id,
    track_id,
    unit_price,
    quantity
)
SELECT
    invoice_line_id_teste,
    1,
    1,
    10.00,
    2
FROM dados_teste_invoice;


SELECT
    i.invoice_id,
    i.total AS total_armazenado,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'TESTE APROVADO'
        ELSE 'TESTE REPROVADO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY
    i.invoice_id,
    i.total;

/*
Resultado esperado:
- o total da invoice deve aumentar em 20.00;
- total_armazenado deve continuar igual ao total_calculado;
- resultado deve ser TESTE APROVADO.
*/


-- ====================================================================
-- TESTE 3
-- UPDATE da quantidade
-- ====================================================================

UPDATE invoice_line
SET quantity = 3
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);


SELECT
    i.invoice_id,
    i.total AS total_armazenado,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'TESTE APROVADO'
        ELSE 'TESTE REPROVADO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY
    i.invoice_id,
    i.total;

/*
Resultado esperado:
- o item passa a representar 10.00 * 3 = 30.00;
- o total deve ser recalculado automaticamente;
- resultado deve ser TESTE APROVADO.
*/


-- ====================================================================
-- TESTE 4
-- UPDATE do preço unitário
-- ====================================================================

UPDATE invoice_line
SET unit_price = 15.00
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);


SELECT
    i.invoice_id,
    i.total AS total_armazenado,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'TESTE APROVADO'
        ELSE 'TESTE REPROVADO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY
    i.invoice_id,
    i.total;

/*
Resultado esperado:
- o item passa a representar 15.00 * 3 = 45.00;
- o total deve ser recalculado automaticamente;
- resultado deve ser TESTE APROVADO.
*/


-- ====================================================================
-- TESTE 5
-- DELETE da invoice_line criada para teste
-- ====================================================================

DELETE FROM invoice_line
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);


SELECT
    i.invoice_id,
    i.total AS total_armazenado,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'TESTE APROVADO'
        ELSE 'TESTE REPROVADO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY
    i.invoice_id,
    i.total;

/*
Resultado esperado:
- o valor da linha removida deve ser retirado do total;
- o total deve voltar ao valor anterior ao INSERT;
- resultado deve ser TESTE APROVADO.
*/


-- ====================================================================
-- TESTE 6
-- Verificação geral de todas as invoices
-- ====================================================================

SELECT
    COUNT(*) AS quantidade_invoices_incorretas
FROM (
    SELECT
        i.invoice_id
    FROM invoice i
    LEFT JOIN invoice_line il
        ON il.invoice_id = i.invoice_id
    GROUP BY
        i.invoice_id,
        i.total
    HAVING i.total <> COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    )
) inconsistencias;

/*
Resultado esperado:

quantidade_invoices_incorretas = 0
*/

ROLLBACK;