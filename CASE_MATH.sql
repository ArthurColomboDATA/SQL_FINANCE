CREATE SEQUENCE id_cliente_numero INCREMENT BY 1 START WITH 1;

CREATE TABLE TbCliente (
    cd_cliente INTEGER PRIMARY KEY DEFAULT nextval('id_cliente_numero'),
    nm_cliente VARCHAR(30) NOT NULL
);


CREATE TABLE TbTransacoes (
    cd_cliente INTEGER NOT NULL,
    dt_transacao DATE NOT NULL,
    cd_transacao INTEGER NOT NULL, -- 000: Cashback, 110: Cash In, 220: Cash Out
    vr_transacao NUMERIC(10, 2) NOT NULL,
    CONSTRAINT fk_cliente FOREIGN KEY (cd_cliente) REFERENCES TbCliente(cd_cliente)
);


INSERT INTO TbCliente (nm_cliente) VALUES
('João'),
('Maria'),
('José'),
('Adilson'),
('Cleber');


INSERT INTO TbTransacoes (cd_cliente, dt_transacao, cd_transacao, vr_transacao) VALUES
(1, '2021-08-28', 000, 20.00),
(1, '2021-09-09', 110, 78.90),
(1, '2021-09-17', 220, 58.00),
(1, '2021-11-15', 110, 178.90),
(1, '2021-12-24', 220, 110.37),
(5, '2021-10-28', 110, 220.00),
(5, '2021-11-07', 110, 380.00),
(5, '2021-12-05', 220, 398.86),
(5, '2021-12-14', 220, 33.90),
(5, '2021-12-21', 220, 16.90),
(3, '2021-10-05', 110, 720.90),
(3, '2021-11-05', 110, 720.90),
(3, '2021-12-05', 110, 720.90),
(4, '2021-10-09', 000, 50.00);

SELECT * FROM TbTransacoes
SELECT * FROM TbCliente

-- Perguntas do Teste

--1° Resultado
SELECT 
    t.cd_cliente,
    c.nm_cliente,
    AVG(t.vr_transacao) AS saldo_medio
FROM 
    TbTransacoes t
JOIN 
    TbCliente c ON t.cd_cliente = c.cd_cliente
WHERE 
    EXTRACT(MONTH FROM t.dt_transacao) = 11
GROUP BY 
    t.cd_cliente, c.nm_cliente
ORDER BY 
    saldo_medio DESC
LIMIT 1;

--2° Resultado
SELECT 
    t.cd_cliente,
    c.nm_cliente,
    SUM(CASE 
            WHEN t.cd_transacao = 110 THEN t.vr_transacao -- Cash In
            WHEN t.cd_transacao = 220 THEN -t.vr_transacao -- Cash Out
            ELSE 0 -- Cashback
        END) AS saldo
FROM 
    TbTransacoes t
JOIN 
    TbCliente c ON t.cd_cliente = c.cd_cliente
GROUP BY 
    t.cd_cliente, c.nm_cliente;

--3° Resultado
SELECT 
    AVG(s.saldo) AS saldo_medio
FROM (
    SELECT 
        t.cd_cliente,
        SUM(CASE 
                WHEN t.cd_transacao = 110 THEN t.vr_transacao -- Cash In
                WHEN t.cd_transacao = 220 THEN -t.vr_transacao -- Cash Out
                ELSE 0 -- Cashback
            END) AS saldo
    FROM 
        TbTransacoes t
    WHERE 
        EXISTS (
            SELECT 1 
            FROM TbTransacoes t2 
            WHERE t2.cd_cliente = t.cd_cliente AND t2.cd_transacao = 0
        )
    GROUP BY 
        t.cd_cliente
) s;

--3° Resultado
SELECT 
    t.cd_cliente,
    c.nm_cliente,
    AVG(t.vr_transacao) AS ticket_medio
FROM (
    SELECT 
        cd_cliente, vr_transacao, 
		ROW_NUMBER() OVER (PARTITION BY cd_cliente ORDER BY dt_transacao DESC) <= 4
    FROM 
        TbTransacoes
	WHERE
		cd_transacao = 110 -- Puxei apenas o Cash In para medir o ticket médio
) t
JOIN 
    TbCliente c ON t.cd_cliente = c.cd_cliente
GROUP BY 
    t.cd_cliente, c.nm_cliente;


--4° Resultado
SELECT 
    EXTRACT(MONTH FROM dt_transacao) AS mes,
    SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) AS total_cash_in,
    SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END) AS total_cash_out,
	COALESCE(
        SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) / NULLIF(SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END),0),
        0
    ) AS proporcao_in_out
FROM 
    TbTransacoes
GROUP BY 
    EXTRACT(MONTH FROM dt_transacao)
ORDER BY mes ASC;

--5° Resultado
SELECT 
    c.nm_cliente, 
    t.cd_cliente, 
    CASE 
        WHEN t.cd_transacao = 110 THEN 'Cash IN'
        WHEN t.cd_transacao = 220 THEN 'Cash Out'
        ELSE 'CashBack'
    END AS tipo_transacao
FROM 
    TbTransacoes t
JOIN 
    TbCliente c ON c.cd_cliente = t.cd_cliente
WHERE 
    t.dt_transacao = (
        SELECT MAX(t2.dt_transacao)
        FROM TbTransacoes t2
        WHERE t2.cd_cliente = t.cd_cliente
    )
ORDER BY 
    c.nm_cliente;

--6° Resultado
SELECT 
    c.nm_cliente, 
    t.cd_cliente, 
	EXTRACT(MONTH FROM t.dt_transacao) as mes,
    CASE 
        WHEN t.cd_transacao = 110 THEN 'Cash IN'
        WHEN t.cd_transacao = 220 THEN 'Cash Out'
        ELSE 'CashBack'
    END AS tipo_transacao
FROM 
    TbTransacoes t
JOIN 
    TbCliente c ON c.cd_cliente = t.cd_cliente
WHERE 
    t.dt_transacao = (
        SELECT MAX(t2.dt_transacao)
        FROM TbTransacoes t2
        WHERE 
            t2.cd_cliente = t.cd_cliente
            AND DATE_PART('month', t2.dt_transacao) = DATE_PART('month', t.dt_transacao)
    )
ORDER BY 
    c.nm_cliente;

--7° Resultado
SELECT COUNT(DISTINCT cd_cliente)
FROM TbTransacoes

--8° Resultado
SELECT 
    SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) AS total_cash_in,
    SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END) AS total_cash_out,
    SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) 
    - SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END) AS balanco_final
FROM 
    TbTransacoes;

--9° Resultado
SELECT COUNT(DISTINCT t.cd_cliente) AS usuarios_ativos_com_cashback
FROM TbTransacoes t
WHERE t.cd_cliente IN (
    SELECT t2.cd_cliente
    FROM TbTransacoes t2
    WHERE t2.cd_transacao = 0 -- Identifica os clientes que receberam CashBack
    AND EXISTS (
        SELECT 1
        FROM TbTransacoes t3
        WHERE t3.cd_cliente = t2.cd_cliente
        AND t3.dt_transacao > t2.dt_transacao -- Verifica se há transações posteriores
    )
);

--10° Resultado
SELECT 
    c.nm_cliente,
    MIN(t.dt_transacao) AS primeira_transacao,
    MAX(t.dt_transacao) AS ultima_transacao
FROM TbTransacoes t
JOIN TbCliente c ON c.cd_cliente = t.cd_cliente
WHERE 
	vr_transacao > 100
GROUP BY c.nm_cliente

--11° Resultado
SELECT 
    t.cd_cliente,
    c.nm_cliente,
    SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) AS total_cash_in,
    SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END) AS total_cash_out,
    SUM(CASE WHEN cd_transacao = 110 THEN vr_transacao ELSE 0 END) 
    - SUM(CASE WHEN cd_transacao = 220 THEN vr_transacao ELSE 0 END) AS balanco_final
FROM (
    SELECT 
        cd_cliente, vr_transacao, cd_transacao, dt_transacao,
        ROW_NUMBER() OVER (PARTITION BY cd_cliente ORDER BY dt_transacao DESC) AS transacoes
    FROM 
        TbTransacoes
    WHERE
        cd_transacao IN (110, 220)  -- Inclui tanto Cash In quanto Cash Out
) t
JOIN 
    TbCliente c ON t.cd_cliente = c.cd_cliente
WHERE 
    t.transacoes <= 4  -- Filtra as 4 últimas transações
GROUP BY 
    t.cd_cliente, c.nm_cliente;


--A 4° Pergunta e a última são iguais.