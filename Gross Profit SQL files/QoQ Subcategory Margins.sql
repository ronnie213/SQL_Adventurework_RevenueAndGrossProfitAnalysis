/* Objective: To determine which subcategory are the top contributors for the fall in GP QoQ */

WITH CurrentQtrMargin AS
	(SELECT
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year,
		DATE_TRUNC('Quarter',orderdate) AS qtrdate,
		subcategory,
		sum(sales.sales) AS CQSales,
		sum(cost) AS CQCost,
		sum(quantity) AS CQQtySold
	FROM
		sales
	JOIN
		Product ON sales.productkey = product.productkey
	WHERE
		EXTRACT('YEAR' FROM(orderdate)) IN (2019, 2020)
	GROUP BY
		quarter_year, qtrdate,subcategory, EXTRACT(YEAR FROM orderdate), EXTRACT(QUARTER FROM orderdate)
	ORDER BY
		EXTRACT(YEAR FROM orderdate) DESC, EXTRACT(QUARTER FROM orderdate) DESC),

	CurQtrVSPrevQtr AS
	(SELECT
		*,
		sum(CQSales) OVER(PARTITION BY subcategory ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQSales,
		sum(CQCost) OVER(PARTITION BY subcategory ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQCost,
		sum(CQQtySold) OVER(PARTITION BY subcategory ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQQtySold
	FROM CurrentQtrMargin
	ORDER BY
		qtrdate DESC),

	VarianceAnalysisBySubcategory AS
	(SELECT 
		quarter_year,
		subcategory,
		CQsales-CQcost AS CQGP,
		PQsales-PQcost AS PQGP,
		(CQsales-CQcost) - (PQsales-PQcost) AS QoQGP,
		((CQsales-CQcost)*100/nullif(CQsales,0)) AS CQGPM,
		((PQsales-PQcost)*100/nullif(PQsales,0)) AS PQGPM,
		CQQtySold,
		PQQtySold,
		ABS((CQsales-CQcost) - (PQsales-PQcost)) AS ABSQoQGP
	FROM
		CurQtrVSPrevQtr
	ORDER BY
		qtrdate DESC, ABSQoQGP DESC, subcategory ASC)

SELECT
	quarter_year,
	subcategory,
	TO_CHAR(CQGP,'FM999,999,999,999.00') AS CQGP,
	TO_CHAR(PQgp,'FM999,999,999,999.00') AS PQGP,
	TO_CHAR(QoQGP,'FM999,999,999,999.00') AS QoQGP,
	ROUND(CQGPM, 2) AS CQGPM,
	ROUND(PQGPM, 2) AS PQGPM,
	TO_CHAR(CQQtySold,'FM999,999,999,999') AS CQQtySold,
	TO_CHAR(PQQtySold,'FM999,999,999,999') AS PQQtySold
FROM
	VarianceAnalysisBySubcategory