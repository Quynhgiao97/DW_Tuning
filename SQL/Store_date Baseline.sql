DECLARE @date AS INT = 20210308

;WITH T0 as (
	SELECT DATE_WID, PLANT_WID, ACTION_TYPE, 
	 count (distinct PERSON_WID) N,
	 AVG(duration) Avg_Duration
	FROM W_PA_ICA_BASELINE_F
	WHERE 1 = 1 
		AND DATE_WID = @date 
		GROUP BY DATE_WID, PLANT_WID,ACTION_TYPE)
,T1 AS (
	SELECT A1.DATE_WID, A1.PLANT_WID, A1.N VISIT, coalesce(A2.interaction,0) INTERACTION,
	A2.Avg_Duration Interact_time,
	coalesce(A3.do_transaction,0) do_transaction
	FROM T0 A1
	 LEFT JOIN (SELECT DATE_WID, PLANT_WID, N  interaction,Avg_Duration From T0 WHERE ACTION_TYPE  = 'interaction')		A2 on A1.DATE_WID = A2.DATE_WID AND A1.PLANT_WID = A2.PLANT_WID
	 LEFT JOIN (SELECT DATE_WID, PLANT_WID, N  do_transaction From T0 WHERE ACTION_TYPE  = 'do_transaction') A3 on A1.DATE_WID = A3.DATE_WID AND A1.PLANT_WID = A3.PLANT_WID
	WHERE A1.ACTION_TYPE = 'visit')
, T2 AS (SELECT F0.INVOICED_ON_DT_WID DATE_WID, F0.PLANT_WID, COUNT (DISTINCT CUSTOMER_SOLD_TO_WID) CUSTOMERS, SUM(F0.NET_AMT * EXCHANGE_RATE) AMT, SUM(INVOICED_QTY) QTY     FROM PNJ_ROLAP.DBO.W_SALES_INVOICE_LINE_F F0
	INNER JOIN (SELECT DISTINCT DATE_WID, PLANT_WID FROM DW_RAW.DBO.W_PA_ICA_BASELINE_F) F1 ON F0.INVOICED_ON_DT_WID = F1.DATE_WID AND F0.PLANT_WID = F1.PLANT_WID
	INNER JOIN (SELECT ROW_WID FROM PNJ_ROLAP.DBO.W_PRODUCT_D WHERE PROD_GRP2 IN ('PG','PD', 'PS', 'PP', 'PT', 'PW','PK','PB'))F3 ON F0.PRODUCT_WID = F3.ROW_WID
	INNER JOIN (SELECT ROW_WID FROM PNJ_ROLAP.DBO.W_CUSTOMER_D WHERE CUST_GRP IN ('Z001', 'ZEPE')) F4 ON F0.CUSTOMER_SOLD_TO_WID = F4.ROW_WID

	WHERE F0.CHANNEL_CODE IN ('10', '20') AND F0.INVOICED_ON_DT_WID = @date
	GROUP BY F0.INVOICED_ON_DT_WID, F0.PLANT_WID)
SELECT S1.*, S2.AMT, S2.CUSTOMERS, S2.QTY FROM T1 S1
	LEFT JOIN T2 S2 ON  S1.DATE_WID = S2.DATE_WID AND S1.PLANT_WID= S2.PLANT_WID