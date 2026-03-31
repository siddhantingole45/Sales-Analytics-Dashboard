--🧹 1. DATA CLEANING QUERIES

--🔹 1. Remove Duplicates
DELETE o1 FROM orders o1
JOIN orders o2 
ON o1.order_id = o2.order_id 
AND o1.rowid > o2.rowid;

--🔹 2. Handle NULL Values
-- Replace NULL sales/profit/quantity with 0
UPDATE orders
SET 
    sales = IFNULL(sales, 0),
    profit = IFNULL(profit, 0),
    quantity = IFNULL(quantity, 0);
-- Remove rows with critical NULLs
DELETE FROM orders
WHERE order_date IS NULL OR customer_id IS NULL;

--🔹 3. Standardize Date Format
UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%Y-%m-%d');

--🔹 4. Remove Negative or Invalid Values
DELETE FROM orders
WHERE sales < 0 OR quantity <= 0;

--🔹 5. Trim and Clean Text Fields
UPDATE customers
SET customer_name = TRIM(customer_name);

UPDATE products
SET category = TRIM(category),
    sub_category = TRIM(sub_category);
    
--🔹 6. Create Derived Columns (Helpful for Tableau)
-- Year & Month
ALTER TABLE orders ADD order_year INT;
ALTER TABLE orders ADD order_month INT;

UPDATE orders
SET 
    order_year = YEAR(order_date),
    order_month = MONTH(order_date);

--📊 2. IMPORTANT DATA ANALYSIS QUERIES

--🔹 1. KPI Overview (Current vs Previous Year)
SELECT 
    order_year,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity
FROM orders
GROUP BY order_year
ORDER BY order_year;

--🔹 2. Monthly Sales Trends (YoY)
SELECT 
    order_year,
    order_month,
    SUM(sales) AS monthly_sales
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month;

--🔹 3. Highest & Lowest Sales Month
SELECT order_month, SUM(sales) AS total_sales
FROM orders
GROUP BY order_month
ORDER BY total_sales DESC;

--🔹 4. Product Subcategory Performance
SELECT 
    p.sub_category,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY total_sales DESC;

--🔹 5. Weekly Sales & Profit
SELECT 
    WEEK(order_date) AS week_no,
    SUM(sales) AS weekly_sales,
    SUM(profit) AS weekly_profit
FROM orders
GROUP BY week_no
ORDER BY week_no;

--🔹 6. Average Weekly Sales
SELECT 
    AVG(weekly_sales) AS avg_weekly_sales
FROM (
    SELECT WEEK(order_date) AS week_no,
           SUM(sales) AS weekly_sales
    FROM orders
    GROUP BY week_no
) t;

--🔹 7. Customer KPIs
SELECT 
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(sales)/COUNT(DISTINCT customer_id) AS sales_per_customer,
    COUNT(order_id) AS total_orders
FROM orders;

--🔹 8. Customer Distribution (Order Count)
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
ORDER BY total_orders DESC;

--🔹 9. Top 10 Customers by Profit
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.sales) AS total_sales,
    SUM(o.profit) AS total_profit,
    MAX(o.order_date) AS last_order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_profit DESC
LIMIT 10;

--🔹 10. Region-wise Sales
SELECT 
    l.region,
    SUM(o.sales) AS total_sales
FROM orders o
JOIN location l ON o.location_id = l.location_id
GROUP BY l.region
ORDER BY total_sales DESC;

-- YoY Growth Calculation
SELECT 
    order_year,
    SUM(sales) AS total_sales,
    LAG(SUM(sales)) OVER (ORDER BY order_year) AS prev_year_sales,
    ROUND(
        (SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY order_year)) 
        / LAG(SUM(sales)) OVER (ORDER BY order_year) * 100, 2
    ) AS yoy_growth_percent
FROM orders
GROUP BY order_year;
