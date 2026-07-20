WITH 
	CurrentQtrSales AS
	(SELECT
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year,
		DATE_TRUNC('quarter', sales.orderdate) AS CurrentQtr,
		sum(sales.sales) AS CQSales
	FROM	
		sales
	GROUP BY
		EXTRACT(QUARTER FROM orderdate), EXTRACT(YEAR FROM orderdate), CurrentQtr
	ORDER BY
		EXTRACT(YEAR FROM orderdate) DESC, EXTRACT(QUARTER FROM orderdate) DESC)

SELECT 
	quarter_year,
	TO_CHAR(CQSales,'FM999,999,999.99') AS CQSales,
	TO_CHAR(PQSales,'FM999,999,999.99') AS PQSales,
	TO_CHAR((CQSales-PQSales),'FM999,999,999.99') AS QoQ,
	ROUND((CQSales-PQSales)/NULLIF(PQSales, 0)*100,2) AS QoQGrowth -- added nullif safeguard --
FROM
	(SELECT 
		quarter_year,
		cqsales,
		-- setting interval to be a quarter earlier for comparison --
		SUM(CQSales) OVER(Order by CurrentQtr RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQSales
	FROM
		CurrentQtrSales
	ORDER BY
		CurrentQtr DESC) Agg_table

