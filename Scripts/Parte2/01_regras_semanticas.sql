/**********************************************************************
1. Criar regras semânticas, que são regras que não podem ser garantidas pela estrutura
do modelo relacional, usando o esquema exemplo fornecido. As regras criadas também
devem ser descritas textualmente no trabalho a ser entregue.
**********************************************************************/


/*
=======================================================================
REGRA SEMÂNTICA 1
=======================================================================

Tabela envolvida:
- employee

Colunas envolvidas:
- employee.birth_date
- employee.hire_date

Descrição:
A data de contratação de um funcionário não pode ser anterior à sua
data de nascimento.

Justificativa:
O modelo relacional permite armazenar datas nas colunas birth_date e
hire_date, porém a estrutura da tabela não garante automaticamente que
a data de contratação seja posterior à data de nascimento. Dessa forma,
é necessária uma regra semântica para impedir esse tipo de inconsistência.

Exemplo de situação inválida:
birth_date = '2000-01-01'
hire_date  = '1990-01-01'

Forma de implementação:
Esta regra será implementada por meio de trigger, validando operações
de INSERT e UPDATE na tabela employee.
*/


/*
=======================================================================
REGRA SEMÂNTICA 2
=======================================================================

Tabela envolvida:
- customer

Colunas envolvidas:
- customer.customer_id
- customer.email

Descrição:
O e-mail de um cliente deve ser obrigatório e não pode ser repetido
entre clientes diferentes.

Justificativa:
O e-mail representa uma informação importante de contato do cliente.
Apesar de a estrutura da tabela já poder definir a coluna como obrigatória,
a validação da regra de negócio será feita por procedimento armazenado,
centralizando a manipulação desse dado e evitando alterações diretas
indevidas na tabela.

Exemplo de situação inválida:
Dois clientes diferentes cadastrados com o mesmo endereço de e-mail.

Forma de implementação:
Esta regra será implementada por meio de stored procedure. Também será
criado um usuário com permissão apenas para executar o procedimento,
sem acesso direto de alteração à tabela customer.
*/


/*
=======================================================================
REGRA SEMÂNTICA 3
=======================================================================

Tabelas envolvidas:
- invoice
- invoice_line

Colunas envolvidas:
- invoice.invoice_id
- invoice.total
- invoice_line.invoice_id
- invoice_line.unit_price
- invoice_line.quantity

Descrição:
O valor total de uma fatura deve ser igual à soma do preço unitário
multiplicado pela quantidade de todos os itens relacionados à fatura.

Formalmente:

invoice.total = SUM(invoice_line.unit_price * invoice_line.quantity)

Justificativa:
A coluna total da tabela invoice armazena uma informação redundante,
pois esse valor pode ser calculado a partir dos registros da tabela
invoice_line. Por esse motivo, é necessário garantir que o valor
armazenado em invoice.total permaneça consistente com os itens da fatura.

Exemplo de situação inválida:
Uma invoice com total igual a 10.00, mas cujos itens somam 15.00.

Forma de implementação:
Esta regra será implementada por meio de trigger, recalculando o total
da fatura sempre que houver INSERT, UPDATE ou DELETE na tabela
invoice_line.
*/


SELECT 'Regras semânticas da Parte 2 documentadas com sucesso.' AS status;