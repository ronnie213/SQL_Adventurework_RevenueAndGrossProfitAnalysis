/* Objective: Compare QoQ decline in GP by country by channel for Mountain Bikes subcategory */

WITH 
	Combinedtable AS
	(SELECT
		DATE_TRUNC('Quarter',orderdate) AS qtrdate,
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate)) AS qtr,
		country,
		product.subcategory,
		businesstype,
		sum(sales) AS CQsales,
		sum(cost) AS CQcost,
		sum(quantity) AS CQqtysold
	FROM
		Sales
	JOIN
		reseller ON reseller.resellerkey = sales.resellerkey
	JOIN
		product ON product.productkey = sales.productkey
	JOIN
		region on region.salesterritorykey = sales.salesterritorykey
	WHERE
		product.subcategory = 'Mountain Bikes'
		AND region.country  IN ('United States','United Kingdom', 'France')
	GROUP BY
		qtrdate, qtr, country, subcategory, businesstype
	ORDER BY
		businesstype),

	CombinedASP AS
	(SELECT 
		*,
		(CQsales - CQcost) AS CQGP,
		ROUND(CQsales/CQqtysold,2) AS CQASP
	FROM
		Combinedtable)

SELECT * FROM CombinedASP
		
