/**********************************************************************
TESTES DA REGRA SEMÂNTICA:

invoice.total =
SUM(invoice_line.unit_price * invoice_line.quantity)

Executar este arquivo após:
04_trigger_invoice_total.sql
**********************************************************************/


-- ====================================================================
-- 1. Preparação
-- ====================================================================

DROP TABLE IF EXISTS resultado_testes_invoice_total;
DROP TABLE IF EXISTS dados_teste_invoice;

CREATE TEMP TABLE resultado_testes_invoice_total (
    ordem INTEGER,
    teste VARCHAR(100),
    resultado_esperado VARCHAR(200),
    resultado_obtido VARCHAR(200),
    total_armazenado NUMERIC(10,2),
    total_calculado NUMERIC(10,2),
    situacao VARCHAR(20)
);

CREATE TEMP TABLE dados_teste_invoice AS
SELECT
    1::INTEGER AS invoice_id_teste,
    COALESCE(MAX(invoice_line_id), 0) + 1 AS invoice_line_id_teste,
    (
        SELECT total
        FROM invoice
        WHERE invoice_id = 1
    )::NUMERIC(10,2) AS total_original
FROM invoice_line;


-- ====================================================================
-- TESTE 1
-- Verificação do total inicial
--
-- RESULTADO ESPERADO:
-- - total_armazenado deve ser igual a total_calculado;
-- - situacao deve ser APROVADO.
-- ====================================================================

INSERT INTO resultado_testes_invoice_total
SELECT
    1,
    'Total inicial da invoice',
    'Total armazenado igual ao total calculado',
    CASE
        WHEN i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'Os valores são iguais'
        ELSE 'Os valores são diferentes'
    END,
    i.total,
    COALESCE(SUM(il.unit_price * il.quantity), 0),
    CASE
        WHEN i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY i.invoice_id, i.total;


-- ====================================================================
-- TESTE 2
-- INSERT de uma nova invoice_line
-- Valor inserido: 10.00 * 2 = 20.00
--
-- RESULTADO ESPERADO:
-- - o total da invoice deve aumentar em 20.00;
-- - total_armazenado deve continuar igual a total_calculado;
-- - situacao deve ser APROVADO.
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
    invoice_id_teste,
    1,
    10.00,
    2
FROM dados_teste_invoice;

INSERT INTO resultado_testes_invoice_total
SELECT
    2,
    'INSERT de invoice_line',
    'Total aumentado em 20.00 e mantido consistente',
    CASE
        WHEN i.total = d.total_original + 20.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'Total aumentado e recalculado corretamente'
        ELSE 'Total não corresponde ao valor esperado'
    END,
    i.total,
    COALESCE(SUM(il.unit_price * il.quantity), 0),
    CASE
        WHEN i.total = d.total_original + 20.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM invoice i
JOIN dados_teste_invoice d
    ON d.invoice_id_teste = i.invoice_id
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total, d.total_original;


-- ====================================================================
-- TESTE 3
-- UPDATE da quantidade
-- Valor da linha: 10.00 * 3 = 30.00
--
-- RESULTADO ESPERADO:
-- - o total da invoice deve ficar 30.00 acima do total original;
-- - total_armazenado deve ser igual a total_calculado;
-- - situacao deve ser APROVADO.
-- ====================================================================

UPDATE invoice_line
SET quantity = 3
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);

INSERT INTO resultado_testes_invoice_total
SELECT
    3,
    'UPDATE da quantidade',
    'Total aumentado em 30.00 em relação ao original',
    CASE
        WHEN i.total = d.total_original + 30.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'Quantidade e total atualizados corretamente'
        ELSE 'Total não corresponde ao valor esperado'
    END,
    i.total,
    COALESCE(SUM(il.unit_price * il.quantity), 0),
    CASE
        WHEN i.total = d.total_original + 30.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM invoice i
JOIN dados_teste_invoice d
    ON d.invoice_id_teste = i.invoice_id
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total, d.total_original;


-- ====================================================================
-- TESTE 4
-- UPDATE do preço unitário
-- Valor da linha: 15.00 * 3 = 45.00
--
-- RESULTADO ESPERADO:
-- - o total da invoice deve ficar 45.00 acima do total original;
-- - total_armazenado deve ser igual a total_calculado;
-- - situacao deve ser APROVADO.
-- ====================================================================

UPDATE invoice_line
SET unit_price = 15.00
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);

INSERT INTO resultado_testes_invoice_total
SELECT
    4,
    'UPDATE do preço unitário',
    'Total aumentado em 45.00 em relação ao original',
    CASE
        WHEN i.total = d.total_original + 45.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'Preço e total atualizados corretamente'
        ELSE 'Total não corresponde ao valor esperado'
    END,
    i.total,
    COALESCE(SUM(il.unit_price * il.quantity), 0),
    CASE
        WHEN i.total = d.total_original + 45.00
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM invoice i
JOIN dados_teste_invoice d
    ON d.invoice_id_teste = i.invoice_id
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total, d.total_original;


-- ====================================================================
-- TESTE 5
-- DELETE da linha criada
-- O total deve voltar ao valor original
--
-- RESULTADO ESPERADO:
-- - a linha criada para o teste deve ser removida;
-- - o total da invoice deve voltar ao valor original;
-- - total_armazenado deve ser igual a total_calculado;
-- - situacao deve ser APROVADO.
-- ====================================================================

DELETE FROM invoice_line
WHERE invoice_line_id = (
    SELECT invoice_line_id_teste
    FROM dados_teste_invoice
);

INSERT INTO resultado_testes_invoice_total
SELECT
    5,
    'DELETE de invoice_line',
    'Total restaurado ao valor original',
    CASE
        WHEN i.total = d.total_original
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'Linha removida e total restaurado corretamente'
        ELSE 'Total não voltou ao valor original'
    END,
    i.total,
    COALESCE(SUM(il.unit_price * il.quantity), 0),
    CASE
        WHEN i.total = d.total_original
         AND i.total = COALESCE(SUM(il.unit_price * il.quantity), 0)
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM invoice i
JOIN dados_teste_invoice d
    ON d.invoice_id_teste = i.invoice_id
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total, d.total_original;


-- ====================================================================
-- TESTE 6
-- Verificação geral de todas as invoices
--
-- RESULTADO ESPERADO:
-- - nenhuma invoice deve apresentar inconsistência;
-- - resultado_obtido deve informar 0 inconsistências;
-- - situacao deve ser APROVADO.
-- ====================================================================

INSERT INTO resultado_testes_invoice_total
SELECT
    6,
    'Verificação geral das invoices',
    'Nenhuma invoice inconsistente',
    CASE
        WHEN COUNT(*) = 0
        THEN 'Foram encontradas 0 inconsistências'
        ELSE 'Foram encontradas ' || COUNT(*) || ' inconsistências'
    END,
    NULL,
    NULL,
    CASE
        WHEN COUNT(*) = 0
        THEN 'APROVADO'
        ELSE 'REPROVADO'
    END
FROM (
    SELECT i.invoice_id
    FROM invoice i
    LEFT JOIN invoice_line il
        ON il.invoice_id = i.invoice_id
    GROUP BY i.invoice_id, i.total
    HAVING i.total <> COALESCE(SUM(il.unit_price * il.quantity), 0)
) inconsistencias;


-- ====================================================================
-- RESULTADO FINAL
-- Este é o último comando para que o pgAdmin exiba esta tabela.
--
-- RESULTADO ESPERADO:
--
-- ordem | teste                         | situacao
-- ------|-------------------------------|----------
-- 1     | Total inicial da invoice      | APROVADO
-- 2     | INSERT de invoice_line        | APROVADO
-- 3     | UPDATE da quantidade          | APROVADO
-- 4     | UPDATE do preço unitário      | APROVADO
-- 5     | DELETE de invoice_line        | APROVADO
-- 6     | Verificação geral das invoices| APROVADO
--
-- Nos testes 1 a 5, total_armazenado e total_calculado devem
-- apresentar o mesmo valor. No teste 6, ambos ficam nulos porque
-- a verificação considera a quantidade geral de inconsistências.
-- ====================================================================

SELECT
    ordem,
    teste,
    resultado_esperado,
    resultado_obtido,
    total_armazenado,
    total_calculado,
    situacao
FROM resultado_testes_invoice_total
ORDER BY ordem;
