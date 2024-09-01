USE projects;

-- inspecting the table --
SELECT COUNT(*)
FROM telco_customers_churn;


-- checking for duplicates --
SELECT customer_id,
       gender
FROM (
    SELECT customer_id,
           gender,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS row_num
    FROM telco_customers_churn
     ) AS duplicates

WHERE row_num > 1;

-- the query above returned an empty output this means there's no duplicate in the dataset--

-- creating buckets for tenure -- by adding a new column to the table

ALTER TABLE telco_customers_churn
ADD COLUMN tenure_categories VARCHAR(255) NULL;


-- analysing data distribution before categorising customers by tenure --

-- 1. calculate percentiles
WITH ranked_tenure AS (
    SELECT
        tenure,
        PERCENT_RANK() OVER ( ORDER BY tenure) AS ranking
    FROM telco_customers_churn
),
percentiles AS ( SELECT
    MAX(CASE WHEN ranking <= 0.25 THEN tenure END) AS p25,
    MAX(CASE WHEN ranking <= 0.50 THEN tenure END) AS p50,
    MAX(CASE WHEN ranking <= 0.75 THEN tenure END) AS p75
FROM ranked_tenure
)
SELECT p25 AS 25th_percentile,
     p50 AS 50th_percentile,
     p75 AS 75th_percentile
FROM percentiles;



-- updating the new column based on the analyses of the data distribution--
UPDATE telco_customers_churn
SET tenure_categories = CASE
    WHEN tenure <= 9  THEN '0-9 months'
    WHEN tenure <= 29 THEN '10-29 months'
    WHEN tenure <= 55 THEN '30-55 months'
ELSE '56+ months'
END;

-- verifying the update --
SELECT customer_id,
       tenure,
       tenure_categories

FROM telco_customers_churn;


-- modifying the data types for  monthly_charges and total_charges columns

ALTER TABLE telco_customers_churn
    MODIFY COLUMN total_charges DECIMAL(10,2) NULL,
    MODIFY COLUMN monthly_charges DECIMAL(10,2) NULL;


-- found a blank value in total_charges for customer_id 4472-LVYGI --

-- updating total_charges to value of monthly charges  for customer 4472-LVYGI  --

UPDATE telco_customers_churn
SET total_charges = monthly_charges
WHERE customer_id = '4472-LVYGI';


SELECT customer_id,
       total_charges,
       monthly_charges
    FROM telco_customers_churn
LIMIT 489;



