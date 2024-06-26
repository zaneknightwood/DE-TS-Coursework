-- Excercise - Basic SQL Queries
USE retail_db;



-- Excercise 1 - Customer Order Count
SELECT
	c.customer_id AS [Customer ID #],
	c.customer_fname AS [First Name],
	c.customer_lname AS [Last Name], 
	count(o.order_id) AS [Order Count]
FROM customers c
JOIN orders o ON c.customer_id = o.order_customer_id
WHERE format(order_date, 'yyyy-MM') LIKE '2014-01%'
GROUP BY c.customer_id, c.customer_fname, c.customer_lname
ORDER BY [Order Count] DESC, c.customer_id ASC;

-- Excercise 2 - Dormant Customers
SELECT
	c.customer_id AS [Customer ID #],
	c.customer_fname AS [First Name],
	c.customer_lname AS [Last Name],
	c.customer_email AS [Email],
	c.customer_password AS [Password],
	c.customer_street AS [Street Address],
	c.customer_city AS [City],
	c.customer_state AS [State],
	c.customer_zipcode AS [Zipcode]
FROM customers c
JOIN orders o ON c.customer_id = o.order_customer_id
WHERE o.order_customer_id NOT IN (SELECT order_customer_id FROM orders WHERE format(order_date, 'yyyy-MM') LIKE '2014-01%')
GROUP BY c.customer_id, c.customer_fname, c.customer_lname, c.customer_email, c.customer_password, c.customer_street, c.customer_city, c.customer_state, c.customer_zipcode
ORDER BY c.customer_id;

-- Exercise 3 - Revenue Per Customer
SELECT
	c.customer_id AS [Customer ID #],
	c.customer_fname AS [First Name],
	c.customer_lname AS [Last Name],
	SUM(oi.order_item_subtotal) [Customer Revenue]
FROM customers c
JOIN orders o ON c.customer_id = o.order_customer_id
JOIN order_items oi ON o.order_id = oi.order_item_order_id
WHERE (o.order_status LIKE 'COMPLETE%' OR o.order_status LIKE 'CLOSED%') AND format(order_date, 'yyyy-MM') LIKE '2014-01%'
GROUP BY c.customer_id, c.customer_fname, c.customer_lname
ORDER BY [Customer Revenue] DESC, c.customer_id ASC;


-- Exercise 4 - Revenue Per Category
SELECT
	cat.category_id AS [Category ID #],
	cat.category_department_id AS [Category Department ID #],
	cat.category_name AS [Category Name],
	SUM(oi.order_item_subtotal) [Category Revenue]
FROM categories cat
JOIN products p ON cat.category_id = p.product_category_id
JOIN order_items oi ON p.product_id = oi.order_item_product_id
JOIN orders o ON o.order_id = oi.order_item_order_id
WHERE (o.order_status LIKE 'COMPLETE%' OR o.order_status LIKE 'CLOSED%') AND format(o.order_date, 'yyyy-MM') LIKE '2014-01%'
GROUP BY cat.category_id, cat.category_department_id, cat.category_name
ORDER BY cat.category_id ASC;

-- Exercise 5 - Product Count Per Department
SELECT
	d.department_id AS [Department ID #],
	d.department_name AS [Department Name],
	COUNT(p.product_id) [Product Count]
FROM departments d
JOIN categories cat ON d.department_id = cat.category_department_id
JOIN products p ON cat.category_id = p.product_category_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id ASC;