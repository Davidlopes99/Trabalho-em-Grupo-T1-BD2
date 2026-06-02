SELECT version() AS versao_postgresql;

SELECT current_database() AS banco_atual;
SELECT current_schema() AS schema_atual;

SELECT
    table_schema AS schema,
    table_name AS tabela,
    table_type AS tipo
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'customer',
      'employee',
      'invoice',
      'invoice_line'
  )
ORDER BY table_name;

-- Verificar colunas usadas nas regras
SELECT
    table_name AS tabela,
    column_name AS coluna,
    data_type AS tipo,
    is_nullable AS aceita_nulo
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN (
      'customer',
      'employee',
      'invoice',
      'invoice_line'
  )
ORDER BY table_name, ordinal_position;

-- Verificar se há inconsistência em employee
SELECT
    employee_id,
    first_name,
    last_name,
    birth_date,
    hire_date
FROM employee
WHERE hire_date < birth_date;

-- Verificar se há e-mails repetidos em customer
SELECT
    email,
    COUNT(*) AS quantidade
FROM customer
GROUP BY email
HAVING COUNT(*) > 1;

-- Verificar se invoice.total está consistente com invoice_line
SELECT
    i.invoice_id,
    i.total AS total_invoice,
    COALESCE(SUM(il.unit_price * il.quantity), 0) AS total_calculado,
    i.total - COALESCE(SUM(il.unit_price * il.quantity), 0) AS diferenca
FROM invoice i
LEFT JOIN invoice_line il
    ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id, i.total
HAVING i.total <> COALESCE(SUM(il.unit_price * il.quantity), 0)
ORDER BY i.invoice_id;

SELECT 'Ambiente da Parte 2 verificado com sucesso.' AS status;