/* Questão 2: Implementar triggers que garantam a validação das regras semânticas criadas. */

-- 1. Criação da função da trigger
CREATE OR REPLACE FUNCTION trg_valida_datas_employee()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se a data de contratação é menor (anterior) à data de nascimento
    IF NEW.hire_date < NEW.birth_date THEN
        RAISE EXCEPTION 'Regra semântica violada: a data de contratação (%) não pode ser anterior à data de nascimento (%).', NEW.hire_date, NEW.birth_date;
    END IF;
    
    -- Se estiver tudo certo, permite a operação
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Criação da trigger vinculada à tabela employee
CREATE TRIGGER trg_check_employee_dates
BEFORE INSERT OR UPDATE ON employee
FOR EACH ROW
EXECUTE FUNCTION trg_valida_datas_employee();


-- 3. Teste da regra
-- Deve falhar e disparar a exceção definida acima
INSERT INTO employee (employee_id, last_name, first_name, birth_date, hire_date) 
VALUES (999, 'Souza', 'Pedro', '2000-01-01', '1990-01-01');
