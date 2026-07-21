/* Objective: Compare QoQ decline in GP for top 3 contributing countries (US, UK and France) by channel for Mountain Bikes subcategory */

WITH channelsalescost AS
	(SELECT
		DATE_TRUNC('Quarter',orderdate) AS qtrdate,
		CONCAT('Q',EXTRACT(QUARTER FROM orderdate),'-',EXTRACT(YEAR FROM orderdate)) AS quarter_year,
		businesstype,
		country,
		sales.sales,
		cost,
		(sales.sales - cost) AS GP,
		(sales.sales - cost)*100/nullif(sales.sales,0) AS GPM, -- nullif safeguard --
		product.subcategory,
		quantity
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
	ORDER BY
		qtrdate DESC),

	Channelprofit AS
	(SELECT
		qtrdate,
		quarter_year,
		businesstype,
		subcategory,
		country,
		ROUND(sum(sales),2) AS CQsales,
		ROUND(sum(cost),2) AS CQcost,
		sum(GP) AS CQGP,
		ROUND(sum(quantity),2) AS CQqtysold
	FROM
		channelsalescost
	GROUP BY
		qtrdate, quarter_year, businesstype, country, subcategory),

	Compiled AS
	(SELECT 
		*,
		CQsales/nullif(CQqtysold,0) AS CQunitprice, 
		sum(CQsales) OVER(PARTITION BY businesstype, subcategory,country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQsales,
		sum(CQcost) OVER(PARTITION BY businesstype, subcategory,country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQcost,
		sum(CQGP) OVER(PARTITION BY businesstype, subcategory,country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQGP,
		sum(CQqtysold) OVER(PARTITION BY businesstype, subcategory,country ORDER BY qtrdate RANGE BETWEEN INTERVAL '3' MONTH PRECEDING AND INTERVAL '3' MONTH PRECEDING) AS PQqtysold
	FROM
		Channelprofit),

	Finalisedoutput AS
	(SELECT
		*,
		PQsales/nullif(PQqtysold,0) AS PQunitprice
	FROM
		Compiled)
	
SELECT
	quarter_year,
	businesstype,
	subcategory,
	country,
	TO_CHAR(CQsales,'FM999,999,999,999.00') AS CQsales,
	TO_CHAR(CQcost,'FM999,999,999,999.00') AS CQcost,
	TO_CHAR(CQGP,'FM999,999,999,999.00') AS CQGP,
	TO_CHAR(PQsales,'FM999,999,999,999.00') AS PQsales,
	TO_CHAR(PQcost,'FM999,999,999,999.00') AS PQcost,
	TO_CHAR(PQGP,'FM999,999,999,999.00') AS PQGP,
	ROUND(CQGP/nullif(CQsales,0)*100,2) AS CQGPM,
	ROUND(PQGP/nullif(PQsales,0)*100,2) AS PQGPM,
	ROUND(CQunitprice,2) AS CQunitprice,
	ROUND(PQunitprice,2) AS PQunitprice,
	ROUND(CQqtysold,0) AS CQqtysold,
	ROUND(PQqtysold,0) AS PQqtysold
FROM
	Finalisedoutput
ORDER BY
	qtrdate DESC, country
