/* Objective: Analyzing Mountain Bikes subcategory to determine top countries contributing to the decline in QoQ decline of GP */

WITH
	-- setting master tables to account for 0 transactions --
	PeriodMaster AS
	(SELECT 
		DISTINCT(DATE_TRUNC('Quarter',orderdate)) AS qtrdate,
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year
	FROM
		Sales),
	CountryMaster AS
	(Select
		country
	FROM
		region),
	SubcategoryMaster AS
	(Select
		DISTINCT(subcategory) AS subcategory
	FROM
		Product),

	VAFORMAT AS
	(SELECT
		qtrdate,
		CONCAT('Q',EXTRACT(QUARTER FROM qtrdate),'-',EXTRACT(YEAR FROM qtrdate)) AS quarter_year,
		SubcategoryMaster.subcategory,
		CountryMaster.country
	FROM
		PeriodMaster
	CROSS JOIN
		CountryMaster
	CROSS JOIN
		SubcategoryMaster
	GROUP BY
		qtrdate, CountryMaster.country, SubcategoryMaster.subcategory),

	FILTEREDVAFORMAT AS
	(SELECT
		qtrdate,
		quarter_year,
		subcategory,
		country
	FROM VAFORMAT
	WHERE
		EXTRACT('YEAR' FROM(qtrdate)) IN (2019, 2020)
		AND subcategory IN ('Touring Bikes','Mountain Bikes','Road Frames')),

	Combinedtrxn AS
	(SELECT
		*,
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year
	FROM
		Sales
	JOIN
		Product ON sales.productkey = product.productkey
	JOIN
		Region ON sales.salesterritorykey = Region.salesterritorykey
	),

	CurrentQtrMargin AS
	(SELECT
		filteredvaformat.qtrdate,
		filteredvaformat.quarter_year,
		Filteredvaformat.subcategory,
		filteredvaformat.country,
		COALESCE(sum(sales),0) AS CQSales,
		COALESCE(sum(cost),0) AS CQCost,
		COALESCE(sum(quantity),0) AS CQQtySold
	FROM
		FILTEREDVAFORMAT
	LEFT JOIN
		Combinedtrxn ON Combinedtrxn.country = Filteredvaformat.country
		AND Combinedtrxn.subcategory = Filteredvaformat.subcategory
		AND Filteredvaformat.quarter_year = Combinedtrxn.quarter_year
	GROUP BY
		filteredvaformat.qtrdate,
		filteredvaformat.quarter_year,
		Filteredvaformat.subcategory,
		filteredvaformat.country),

	QoQAnalysis AS
	(SELECT 
		*,
		SUM(CQsales) OVER(PARTITION BY subcategory, country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQsales,
		SUM(CQcost) OVER(PARTITION BY subcategory, country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQcost,
		SUM(CQqtysold) OVER(PARTITION BY subcategory, country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQqtysold,
		CQsales-CQcost AS CQGP,
		COALESCE((CQsales-CQcost)*100/NULLIF(CQsales,0),0) AS CQGPM
	FROM 
		CurrentQtrMargin),

	GPOutput AS
	(SELECT 
	qtrdate,
	quarter_year,
	subcategory,
	country,
	CQGP,
	(PQsales - PQCost) AS PQGP,
	ROUND(CQGPM,2) AS CQGPM,
	ROUND(COALESCE((PQsales - PQCost)*100/NULLIF(PQsales,0),0),2) AS PQGPM,
	CQQtySold AS CQQtySold,
	PQQtySold
FROM
	QoQAnalysis)

SELECT 
	quarter_year,
	subcategory,
	country,
	TO_CHAR(ROUND((CQGP - PQGP),0),'FM999,999,999,999') AS QoQGP, -- format readability -- 
	CQGPM,
	PQGPM,
	TO_CHAR(CQQtySold,'FM999,999,999,999') AS CQQtySold,
	TO_CHAR(PQQtySold,'FM999,999,999,999') AS PQQtySold
FROM 
	GPOutput
ORDER BY
	qtrdate DESC, subcategory, abs(CQGP - PQGP) DESC, country
