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
SELECT * FROM orders
WHERE order_customer_id IN (
	SELECT order_customer_id
	FROM orders
	GROUP BY order_customer_id
	HAVING COUNT(1) > 10)


-- Exercise 3: 


