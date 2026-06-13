/**********************************************************************
4. A base original do Chinook possui uma coluna Total na tabela Invoice representada
de forma redundante com as informações contidas nas colunas UnitPrice e
Quantity na tabela InvoiceLine. Podemos identificar nesse caso uma regra
semântica onde o valor Total de um Invoice deve ser igual à soma de UnitPrice *
Quantity de todos os registros de InvoiceLine relacionados a um Invoice.
Implementar uma solução que garanta a integridade dessa regra.
**********************************************************************/


/*
=======================================================================
REGRA SEMÂNTICA
=======================================================================

O valor armazenado em invoice.total deve ser igual a:

SUM(invoice_line.unit_price * invoice_line.quantity)

A solução utiliza uma trigger executada após operações de INSERT,
UPDATE ou DELETE na tabela invoice_line.

Sempre que os itens de uma fatura forem alterados, o total da invoice
correspondente será recalculado automaticamente.
*/


DROP TRIGGER IF EXISTS trg_atualiza_total_invoice
ON invoice_line;

DROP FUNCTION IF EXISTS trg_recalcula_total_invoice();


CREATE OR REPLACE FUNCTION trg_recalcula_total_invoice()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_id INTEGER;
    v_total NUMERIC(10,2);
BEGIN

    IF TG_OP = 'DELETE' THEN
        v_invoice_id := OLD.invoice_id;
    ELSE
        v_invoice_id := NEW.invoice_id;
    END IF;

    SELECT COALESCE(
        SUM(unit_price * quantity),
        0
    )
    INTO v_total
    FROM invoice_line
    WHERE invoice_id = v_invoice_id;


    UPDATE invoice
    SET total = v_total
    WHERE invoice_id = v_invoice_id;

    IF TG_OP = 'UPDATE'
       AND OLD.invoice_id IS DISTINCT FROM NEW.invoice_id THEN

        SELECT COALESCE(
            SUM(unit_price * quantity),
            0
        )
        INTO v_total
        FROM invoice_line
        WHERE invoice_id = OLD.invoice_id;

        UPDATE invoice
        SET total = v_total
        WHERE invoice_id = OLD.invoice_id;
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_atualiza_total_invoice
AFTER INSERT OR UPDATE OR DELETE
ON invoice_line
FOR EACH ROW
EXECUTE FUNCTION trg_recalcula_total_invoice();


UPDATE invoice i
SET total = (
    SELECT COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    )
    FROM invoice_line il
    WHERE il.invoice_id = i.invoice_id
);


SELECT
    i.invoice_id,
    i.total AS total_invoice,
    COALESCE(
        SUM(il.unit_price * il.quantity),
        0
    ) AS total_calculado,
    CASE
        WHEN i.total = COALESCE(
            SUM(il.unit_price * il.quantity),
            0
        )
        THEN 'CORRETO'
        ELSE 'INCORRETO'
    END AS resultado
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY
    i.invoice_id,
    i.total
ORDER BY
    i.invoice_id;


SELECT
    'Trigger de integridade de invoice.total criada com sucesso.'
    AS status;