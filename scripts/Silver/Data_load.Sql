CREATE OR ALTER PROCEDURE Silver.load_silver
AS
BEGIN

SET NOCOUNT ON;

DECLARE
@start_time DATETIME,
@End_time DATETIME,
@Batch_start_time DATETIME,
@Batch_End_time DATETIME;

BEGIN TRY

SET @Batch_start_time = GETDATE();

PRINT '============================================'
PRINT 'Loading SILVER LAYER'
PRINT '============================================'

---

 -- 1. Silver.crm_cust_info

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.crm_cust_info'
TRUNCATE TABLE Silver.crm_cust_info;

PRINT 'Inserting data into : Silver.crm_cust_info'

INSERT INTO Silver.crm_cust_info
(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_material_status,
cst_gndr,
cst_create_date
)
SELECT
cst_id,
cst_key,
TRIM(cst_firstname),
TRIM(cst_lastname),
CASE
WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'MARRIED'
WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'SINGLE'
ELSE 'N/A'
END,
CASE
WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
ELSE 'N/A'
END,
cst_create_date
FROM
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS Flag_Last
FROM Bronze.crm_cust_info
WHERE cst_id IS NOT NULL
)t
WHERE Flag_Last = 1;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.crm_cust_info : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- 2. Silver.crm_prd_info

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.crm_prd_info'
TRUNCATE TABLE Silver.crm_prd_info;

PRINT 'Inserting data into : Silver.crm_prd_info'

INSERT INTO Silver.crm_prd_info
(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
)
SELECT
prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_'),
SUBSTRING(prd_key,7,LEN(prd_key)),
prd_nm,
ISNULL(prd_cost,0),
CASE
WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
ELSE 'N/A'
END,
CAST(prd_start_dt AS DATE),
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE)
FROM Bronze.crm_prd_info;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.crm_prd_info : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- 3. Silver.crm_sales_details

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.crm_sales_details'
TRUNCATE TABLE Silver.crm_sales_details;

PRINT 'Inserting data into : Silver.crm_sales_details'

INSERT INTO Silver.crm_sales_details
(
sls_ord_num,
sls_prd_key,
sls_cust_id,
sls_order_dt,
sls_ship_dt,
sls_due_dt,
sls_sales,
sls_quantity,
sls_price
)
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt <=0 OR LEN(sls_order_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END,
CASE
WHEN sls_ship_dt <=0 OR LEN(sls_ship_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END,
CASE
WHEN sls_due_dt <=0 OR LEN(sls_due_dt) != 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END,
CASE
WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
THEN sls_quantity * ABS(sls_price)
ELSE sls_sales
END,
sls_quantity,
CASE
WHEN sls_price IS NULL OR sls_price <=0
THEN sls_sales / NULLIF(sls_quantity,0)
ELSE sls_price
END
FROM Bronze.crm_sales_details;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.crm_sales_details : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- 4. Silver.erp_cust_az12

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.erp_cust_az12'
TRUNCATE TABLE Silver.erp_cust_az12;

PRINT 'Inserting data into : Silver.erp_cust_az12'

INSERT INTO Silver.erp_cust_az12
(
cid,
bdate,
gen
)
SELECT
CASE
WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
ELSE cid
END,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE bdate
END,
CASE
WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'MALE'
WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'FEMALE'
ELSE 'N/A'
END
FROM Bronze.erp_cust_az12;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.erp_cust_az12 : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- 5. Silver.erp_loc_a101

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.erp_loc_a101'
TRUNCATE TABLE Silver.erp_loc_a101;

PRINT 'Inserting data into : Silver.erp_loc_a101'

INSERT INTO Silver.erp_loc_a101
(
cid,
cntry
)
SELECT
REPLACE(cid,'-',''),
CASE
WHEN TRIM(cntry) = 'DE' THEN 'Germany'
WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
ELSE cntry
END
FROM Bronze.erp_loc_a101;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.erp_loc_a101 : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- 6. Silver.erp_px_cat_g1V2

SET @start_time = GETDATE();

PRINT 'Truncating Table : Silver.erp_px_cat_g1V2'
TRUNCATE TABLE Silver.erp_px_cat_g1V2;

PRINT 'Inserting data into : Silver.erp_px_cat_g1V2'

INSERT INTO Silver.erp_px_cat_g1V2
(
id,
cat,
subcat,
maintenance
)
SELECT
id,
cat,
subcat,
maintenance
FROM Bronze.erp_px_cat_g1V2;

SET @End_time = GETDATE();

PRINT 'LOADING DURATION OF Silver.erp_px_cat_g1V2 : '

* CAST(DATEDIFF(SECOND,@start_time,@End_time) AS NVARCHAR) + ' seconds';
  PRINT '--------------------------------------------';

---

 -- Batch Duration

SET @Batch_End_time = GETDATE();

PRINT 'SILVER LAYER LOADED SUCCESSFULLY';
PRINT 'TOTAL LOADING TIME : '

* CAST(DATEDIFF(SECOND,@Batch_start_time,@Batch_End_time) AS NVARCHAR)
* ' seconds';

END TRY

BEGIN CATCH

PRINT '====================================================';
PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE();
PRINT 'ERROR NUMBER : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
PRINT '====================================================';

END CATCH

END;
exec Silver.load_silver;
