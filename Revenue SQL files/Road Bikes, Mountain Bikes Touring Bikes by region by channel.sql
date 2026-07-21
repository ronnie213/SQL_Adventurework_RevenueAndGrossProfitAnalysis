/* Objective: QoQ analysis for Revenue of top 3 contributors for subcategory for US, by channel for 2019 and 2020*/

WITH CurrentQtrMargin AS
	(SELECT
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year,
		DATE_TRUNC('Quarter',orderdate) AS qtrdate,
		subcategory,
		country,
		businesstype,
		sum(sales) AS CQSales,
		sum(cost) AS CQCost,
		sum(quantity) AS CQQtySold
	FROM
		sales
	JOIN
		Product ON sales.productkey = product.productkey
	JOIN
		region ON region.salesterritorykey = sales.salesterritorykey
	JOIN
		reseller ON reseller.resellerkey  = sales.resellerkey
	WHERE
		EXTRACT('YEAR' FROM(orderdate)) IN (2019, 2020) 
		AND subcategory IN ('Touring Bikes', 'Mountain Bikes', 'Road Bikes')
		AND country = 'United States'
	GROUP BY
		quarter_year, qtrdate,subcategory, country, businesstype, EXTRACT(YEAR FROM orderdate), EXTRACT(QUARTER FROM orderdate)),

	CurQtrVSPrevQtr AS
	(SELECT
		*,
		sum(CQSales) OVER(PARTITION BY subcategory, country, businesstype ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQSales,
		sum(CQCost) OVER(PARTITION BY subcategory, country, businesstype ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQCost,
		sum(CQQtySold) OVER(PARTITION BY subcategory, country, businesstype ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQQtySold
	FROM CurrentQtrMargin
	ORDER BY
		qtrdate DESC)

SELECT 
	quarter_year,
	subcategory,
	country,
	businesstype,
	TO_CHAR(CQsales,'FM999,999,999,999.00') AS CQsales,
	TO_CHAR(PQsales,'FM999,999,999,999.00') AS PQsales,
	TO_CHAR(CQsales-PQsales,'FM999,999,999,999.00') AS QoQSales,
	TO_CHAR(CQqtysold,'FM999,999,999') AS CQqtysold,
	TO_CHAR(PQqtysold,'FM999,999,999') AS PQqtysold,
	ROUND((CQsales/NULLIF(CQqtysold,0)),2) AS CQASP, -- nullif safeguard --
	ROUND((PQsales/NULLIF(PQqtysold,0)),2) AS PQASP  -- nullif safeguard --
FROM
	CurQtrVSPrevQtr
ORDER BY
	qtrdate DESC, subcategory, ABS(CQsales-PQsales) DESC -- sorting using absolute figures to determine largest flux contributors --
