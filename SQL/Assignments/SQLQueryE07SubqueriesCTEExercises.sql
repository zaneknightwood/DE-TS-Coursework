-- Subqueries and CTE exercises
USE retail_db;


-- Exercise 1: Simple Subquery

SELECT category_name FROM (
	SELECT
		c.category_name,
		c.category_id,
		COUNT(p.product_category_id) p_count
	FROM categories c
	JOIN products p ON c.category_id = p.product_category_id
	GROUP BY category_name, category_id, p.product_category_id
	) sq
WHERE p_count > 5;

SELECT * FROM products


-- Exercise 2: Subquery in WHERE Clause
-- Find all orders placed by customers who have made more than 10 purchases in total.
SELECT * FROM orders
WHERE order_customer_id IN (
	SELECT order_customer_id
	FROM orders
	GROUP BY order_customer_id
	HAVING COUNT(1) > 10)


-- Exercise 3: Subquery in SELECT Clause
-- Display the product names along with the average price of all products that were ordered in October 2013.
SELECT 
	product_name,
	(SELECT 
		CAST(AVG(p.product_price) AS DECIMAL(18,2)) avg_price 
	FROM products p
	JOIN order_items oi ON p.product_id = oi.order_item_product_id
	JOIN orders o ON oi.order_item_order_id = o.order_id
	WHERE FORMAT(o.order_date, 'yyyy-MM') = '2013-10') avg_price
FROM products
ORDER BY product_name;

-- Exercise 4: Subquery with Aggregate Functions
-- List the orders that have a total amount greater than the average order amount.
SELECT * FROM (
	SELECT
		SUM(oi.order_item_subtotal) oi_total,
		AVG(oi.order_item_subtotal) oi_avg
	FROM order_items oi
	) sq
