USE projects;

-- data cleaning and modification --


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
        PERCENT_RANK() OVER ( ORDER BY tenure ) AS ranking
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
    WHEN tenure BETWEEN 0 AND 5   THEN '0-5 months'
    WHEN tenure BETWEEN 6 AND 10  THEN '6-10 months'
    WHEN tenure BETWEEN 11 AND 20 THEN '11-20 months'
    WHEN tenure BETWEEN 21 AND 30 THEN '21-30 months'
    WHEN tenure > 30 THEN '30+ months'
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


-- verifying update for customer 4472-LVYGI
SELECT customer_id,
       total_charges,
       monthly_charges
    FROM telco_customers_churn
    WHERE customer_id = '4472-LVYGI'
LIMIT 1;




-- found some discrepancies for total and monthly charges for some customers --

SELECT tenure,
       tenure_categories,
    monthly_charges,
    total_charges
FROM telco_customers_churn
WHERE total_charges < monthly_charges;


-- update total_charges with monthly charges for such discrepancies

UPDATE telco_customers_churn
SET total_charges = monthly_charges
WHERE total_charges < monthly_charges;

-- verifying the updates --

SELECT tenure,
       tenure_categories,
    monthly_charges,
    total_charges
FROM telco_customers_churn
WHERE total_charges < monthly_charges;




-- inspecting other columns --
SELECT
streaming_movies,
streaming_tv,
internet_service,
tech_support,
online_backup,
online_security

FROM telco_customers_churn;



ALTER TABLE telco_customers_churn
ADD COLUMN churn_status INT AFTER churn;

-- updating churn as Yes = 1, No = 0 --
UPDATE telco_customers_churn
SET churn_status = CASE
    WHEN churn =  'No' THEN 0
    WHEN  churn = 'Yes' THEN 1
END;


ALTER TABLE telco_customers_churn
ADD COLUMN streaming_movies_status INT AFTER streaming_movies;

UPDATE telco_customers_churn
SET streaming_movies_status = CASE
WHEN streaming_movies = 'Yes' THEN 1
WHEN streaming_movies = 'No' OR
     streaming_movies = 'No internet service' THEN 0
END;


-- verifying updates --

SELECT streaming_movies,
    streaming_movies_status
FROM telco_customers_churn;


ALTER TABLE telco_customers_churn
ADD COLUMN streaming_tv_status INT AFTER streaming_tv;

UPDATE telco_customers_churn
SET streaming_tv_status = CASE
WHEN streaming_tv = 'Yes' THEN 1
WHEN streaming_tv = 'No' OR
     streaming_tv = 'No internet service' THEN 0
END;

-- verifying update --
SELECT streaming_tv,
    streaming_tv_status
FROM telco_customers_churn;

-- adding additional columns --
ALTER TABLE telco_customers_churn
ADD COLUMN tech_support_status INT AFTER tech_support,
ADD COLUMN online_backup_status INT AFTER online_backup,
ADD COLUMN online_security_status INT AFTER online_security,
ADD COLUMN device_protection_status INT AFTER device_protection;

-- populating the additional columns --

-- 1. tech_support_status --
UPDATE telco_customers_churn
SET tech_support_status = CASE
WHEN tech_support = 'Yes' THEN 1
WHEN tech_support = 'No' OR
     tech_support = 'No internet service' THEN 0
END;

-- 2.  online_backup_status --
UPDATE telco_customers_churn
SET online_backup_status = CASE
WHEN online_backup = 'Yes' THEN 1
WHEN online_backup = 'No' OR
     online_backup = 'No internet service' THEN 0
END;

-- 3.  online_security_status --
UPDATE telco_customers_churn
SET online_security_status = CASE
WHEN online_security = 'Yes' THEN 1
WHEN online_security = 'No' OR
     online_security = 'No internet service' THEN 0
END;


-- 4. device_protection_status --
UPDATE telco_customers_churn
SET device_protection_status = CASE
WHEN device_protection = 'Yes' THEN 1
WHEN device_protection = 'No' OR
     device_protection = 'No internet service' THEN 0
END;


-- verifying updates --
SELECT  tech_support_status,
       online_backup_status,
       device_protection_status,
       online_security_status
FROM telco_customers_churn;


-- determining the number of services each customer has --

ALTER TABLE telco_customers_churn
ADD COLUMN service_count INT;


UPDATE telco_customers_churn
SET service_count = online_security_status
                    + online_backup_status
                    + device_protection_status
                    + tech_support_status
                    + streaming_tv_status
                    + streaming_movies_status;


-- verifying updates --
SELECT
    customer_id,
    service_count
FROM telco_customers_churn
# WHERE customer_id ='9237-HQITU'
LIMIT 100;


-- selecting the max and min number of services to determine service labeling --

SELECT MAX(service_count) AS max_num,
       MIN(service_count) AS min_num
FROM telco_customers_churn;

-- applying  labels to service_counts --

ALTER TABLE telco_customers_churn
ADD COLUMN service_count_label VARCHAR(10);


UPDATE telco_customers_churn
SET service_count_label = CASE
WHEN service_count = 1 THEN 'One'
WHEN service_count = 2 THEN 'Two'
WHEN service_count = 3 THEN 'Three'
WHEN service_count = 4 THEN 'Four'
WHEN service_count = 5 THEN 'Five'
WHEN service_count = 6 THEN 'Six'
ELSE 'None'
END;


-- verifying the update --
SELECT service_count,
       service_count_label
FROM telco_customers_churn;


-- end of data cleaning  😁 --