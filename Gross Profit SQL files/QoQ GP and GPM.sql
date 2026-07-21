/* Objective: Compaing GP and GPM QoQ */

WITH CurrentQtrSales AS
	(SELECT
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year,
		DATE_TRUNC('quarter', sales.orderdate) AS CurrentQtr,
		sum(sales.sales) AS CQSales,
		sum(sales.cost) AS CQCost
	FROM	
		sales
	GROUP BY
		EXTRACT(QUARTER FROM orderdate), EXTRACT(YEAR FROM orderdate), CurrentQtr),

	PreviousQtrSales AS
	(SELECT 
		*,
		-- to compare against previous quarter --
		sum(CQsales) OVER(ORDER BY CurrentQtr RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQsales,
		sum(CQcost) OVER(ORDER BY CurrentQtr RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQcost
	FROM
		CurrentQtrSales
	ORDER BY
		CurrentQtr DESC),

	VarianceAnalysisQtr AS
	(SELECT 
		quarter_year, 
		CQsales - CQcost AS CQGP,
		PQsales - PQcost AS PQGP,
		ROUND(((CQsales - CQcost)/nullif(CQsales,0))*100,2) AS CQGM, -- nullif safeguard --
		ROUND(((PQsales - PQcost)/nullif(PQsales,0))*100,2) AS PQGM  -- nullif safeguard --
	FROM
		PreviousQtrSales)

SELECT
	quarter_year,
	TO_CHAR(CQGP,'FM999,999,999,999.99') AS CQGP, -- convert to text for readability -- 
	TO_CHAR(PQGP,'FM999,999,999,999.99') AS PQGP,
	TO_CHAR(CQGP - PQGP,'FM999,999,999,999.99') AS QoQGP,
	CQGM,
	PQGM
FROM
	VarianceAnalysisQtr
