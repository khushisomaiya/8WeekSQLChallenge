-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,
		SUM(price) as 'Amount Spent'
FROM sales
	 INNER JOIN 
     menu
     ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id,
	   COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT customer_id,
	   product_name
FROM
(
	SELECT customer_id,
		   product_name,
		   DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as rank_num
	FROM sales
		 INNER JOIN menu
		 ON sales.product_id = menu.product_id
)as ranked
WHERE rank_num = 1
GROUP BY customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name,
	   COUNT(product_name) as number_of_purchases
FROM  sales
	  LEFT JOIN menu
      ON sales.product_id = menu.product_id
GROUP BY  product_name
ORDER BY number_of_purchases DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH purchases as
(
	SELECT customer_id,
			product_name,
		   COUNT(product_name) as number_of_purchases,
           DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) as rank_num
	FROM  sales
		  LEFT JOIN menu
		  ON sales.product_id = menu.product_id
	GROUP BY  customer_id,product_name
	ORDER BY number_of_purchases DESC
)
SELECT customer_id,
		product_name,
        number_of_purchases
FROM purchases
WHERE rank_num =1
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?

SELECT customer_id,
	   product_name
FROM
(
	SELECT members.customer_id,
		   product_id,
		   DENSE_RANK() OVER (PARTITION BY members.customer_id ORDER BY order_date) as rank_num
	FROM members
		 INNER JOIN sales
         ON members.customer_id = sales.customer_id
	WHERE order_date>join_date
)as ranked
INNER JOIN menu
ON ranked.product_id = menu.product_id
WHERE rank_num = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id,
	   product_name
FROM
(
	SELECT members.customer_id,
		   product_id,
		   DENSE_RANK() OVER (PARTITION BY members.customer_id ORDER BY order_date DESC) as rank_num
	FROM members
		 INNER JOIN sales
         ON members.customer_id = sales.customer_id
	WHERE order_date<join_date
)as ranked
INNER JOIN menu
ON ranked.product_id = menu.product_id
WHERE rank_num = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?

WITH before_members as
(
	SELECT sales.customer_id as cust_id,
		   product_id
    FROM members
    INNER JOIN sales 
    ON members.customer_id = sales.customer_id
    WHERE order_date<join_date
)
SELECT before_members.cust_id,
	   COUNT(before_members.product_id) as total_items,
       SUM(price) as amount_spent
FROM before_members
	 LEFT JOIN menu
     ON before_members.product_id = menu.product_id
GROUP BY 1;
-- OR
SELECT sales.customer_id,
	   COUNT(sales.product_id) as total_items,
       SUM(price) as amount_spent
FROM members
    INNER JOIN sales 
    ON members.customer_id = sales.customer_id
    LEFT JOIN menu
     ON sales.product_id = menu.product_id
WHERE order_date<join_date
GROUP BY 1;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
	   SUM(points) as total_points
FROM 
(
	SELECT customer_id,
		   product_name,
		   CASE WHEN product_name = 'sushi' THEN price*20
		   ELSE price*10
		   END AS points
	FROM sales
	LEFT JOIN menu
	ON sales.product_id = menu.product_id
) as point_table
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT sales.customer_id,
	   order_date,
       join_date
FROM members
INNER JOIN sales
ON members.customer_id = sales.customer_id
WHERE order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 7 DAY) ;

SELECT customer_id,
	   SUM(points) as total_points
FROM 
(
	SELECT members.customer_id,
		   product_name,
           order_date,
		   CASE 
				WHEN order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 7 DAY) THEN price*20
                ELSE
					CASE
					WHEN product_name='sushi' THEN price*20
                    ELSE price*10
				END
			END AS points
	FROM members
    INNER JOIN sales 
    ON members.customer_id = sales.customer_id
    LEFT JOIN menu
     ON sales.product_id = menu.product_id
	
) as point_table
WHERE MONTH(order_date)=1
GROUP BY customer_id;

	SELECT members.customer_id,
		   product_name,
           order_date,
		   CASE 
				WHEN order_date >= join_date AND order_date < DATE_ADD(join_date, INTERVAL 7 DAY) THEN price*20
                ELSE
					CASE
					WHEN product_name='sushi' THEN price*20
                    ELSE price*10
				END
			END AS points
	FROM members
    INNER JOIN sales 
    ON members.customer_id = sales.customer_id
    LEFT JOIN menu
     ON sales.product_id = menu.product_id
     WHERE MONTH(order_date)=1;
	
-- Bonus Questions
-- Join All The Things
-- The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
-- Recreate the following table output using the available data:customer_id, order_date, product_name, price,member

SELECT  s.customer_id,
	    order_date,
        product_name,
        price,
        CASE 
        WHEN (m.customer_id IS NOT NULL AND order_date>=join_date) THEN  'Y'
        ELSE 'N'
        END AS member
FROM sales as s 
	 LEFT JOIN members as m
     ON s.customer_id = m.customer_id
     LEFT JOIN menu as mn
     ON s.product_id = mn.product_id;
     
CREATE TABLE dannys_diner_data AS
SELECT  s.customer_id,
	    order_date,
        product_name,
        price,
        CASE 
        WHEN (m.customer_id IS NOT NULL AND order_date>=join_date) THEN  'Y'
        ELSE 'N'
        END AS member
FROM sales as s 
	 LEFT JOIN members as m
     ON s.customer_id = m.customer_id
     LEFT JOIN menu as mn
     ON s.product_id = mn.product_id;
    
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

SELECT *,
	   CASE 
       WHEN member = 'N' THEN NULL
       ELSE
	   RANK() OVER (PARTITION BY customer_id,member ORDER BY order_date) 
       END AS ranking
FROM dannys_diner_data;
       
       
