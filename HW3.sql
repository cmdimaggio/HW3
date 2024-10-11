-- DB Assignmnet 3
-- Christina DiMaggio
-- October 8 2024



use examples;

-- Contraints and PK and FK

ALTER TABLE products
ADD CONSTRAINT chk_product_name 
CHECK (name IN 
('Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop', 'Router', 'Network Card', 'Super Drive', 'Monitor'));

ALTER TABLE products
ADD CONSTRAINT chk_product_category 
CHECK (category IN ('Peripheral', 'Networking', 'Computer'));

ALTER TABLE sell
ADD CONSTRAINT chk_sell_price 
CHECK (price BETWEEN 0 AND 100000);

ALTER TABLE sell
ADD CONSTRAINT chk_quantity_available 
CHECK (quantity_available BETWEEN 0 AND 1000);

ALTER TABLE orders
ADD CONSTRAINT chk_shipping_method 
CHECK (shipping_method IN ('UPS', 'FedEx', 'USPS'));

ALTER TABLE orders
ADD CONSTRAINT chk_shipping_cost 
CHECK (shipping_cost BETWEEN 0 AND 500);

ALTER TABLE place
MODIFY order_date DATETIME;

ALTER TABLE place
ADD CONSTRAINT chk_order_date 
CHECK (order_date <= GETDATE());

ALTER TABLE merchants ADD PRIMARY KEY (mid);
ALTER TABLE products ADD PRIMARY KEY (pid);
ALTER TABLE sell ADD PRIMARY KEY (mid, pid);
ALTER TABLE orders ADD PRIMARY KEY (oid);
ALTER TABLE contain ADD PRIMARY KEY (oid, pid);
ALTER TABLE customers ADD PRIMARY KEY (cid);
ALTER TABLE place ADD PRIMARY KEY (cid, oid);

ALTER TABLE sell
ADD CONSTRAINT fk_sell_merchants FOREIGN KEY (mid) REFERENCES merchants(mid),
ADD CONSTRAINT fk_sell_products FOREIGN KEY (pid) REFERENCES products(pid);

ALTER TABLE contain
ADD CONSTRAINT fk_contain_orders FOREIGN KEY (oid) REFERENCES orders(oid),
ADD CONSTRAINT fk_contain_products FOREIGN KEY (pid) REFERENCES products(pid);

ALTER TABLE place
ADD CONSTRAINT fk_place_customers FOREIGN KEY (cid) REFERENCES customers(cid),
ADD CONSTRAINT fk_place_orders FOREIGN KEY (oid) REFERENCES orders(oid);

-- 1. List names and sellers of products that are no longer available (quantity=0)
		-- need to combine products and merchants
			-- chain broken if there is no link with primary keys, everything has to be conneceted
					-- sell has foreign keys 
		-- need names of the products 
        -- need names of sellers (merchants) 
        -- setting quantity to zero only gives back products that are not available anymore, which is what we want
SELECT p.name AS product_name, m.name AS seller_name -- create alias
FROM products p -- universal set
JOIN sell s ON p.pid = s.pid 
JOIN merchants m ON s.mid = m.mid
WHERE s.quantity_available = 0; -- to filter rows


-- 2. List names and descriptions of products that are not sold.
		-- need to combine products with sells 
			-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell has foreign keys 
		-- need names of the products 
        -- need descriptions of products 
        -- using where is null returns only the products that there was no sale for 
SELECT p.name AS product_name, p.description AS product_description -- create alias
FROM products p -- universal set
LEFT JOIN sell s ON p.pid = s.pid -- LEFT JOIN
WHERE s.mid IS NULL; -- to filter rows


-- 3. How many customers bought SATA drives but not any routers?
		-- need to combine customers with place, orders, contain and products 
			-- chain broken if there is no link with primary keys, everything has to be connected
					-- place, orders, contain and products have foreign keys needed
		-- need count of customers who bought SATA drives 
        -- need to find customers who bought routers
        -- once both are found 'subtract' people who bought SATA drives from people that have a router 
				-- cid of someone who bought SATA but not  router
SELECT COUNT(DISTINCT c.cid) AS customer_count -- alias and counts unqiue customers
FROM customers c -- universal set
JOIN place p ON c.cid = p.cid
JOIN orders o ON p.oid = o.oid
JOIN contain co ON o.oid = co.oid
JOIN products prod ON co.pid = prod.pid
WHERE prod.category = 'SATA Drive' -- filter rows
  AND c.cid NOT IN ( -- acts as excpet
      SELECT DISTINCT c.cid
      FROM customers c -- universal set
      JOIN place p ON c.cid = p.cid
      JOIN orders o ON p.oid = o.oid
      JOIN contain co ON o.oid = co.oid
      JOIN products prod ON co.pid = prod.pid
      WHERE prod.category = 'Router' -- filter rows
);

-- 4. HP has a 20% sale on all its Networking products.
		-- need to combine products with sells 
			-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell has foreign keys 
		-- need names of the products 
        -- need original price of products
        -- calculate the discounted price
        -- using where HP and Networking returns only the products that will have sale

SELECT p.name AS product_name, FORMAT(s.price, 2) AS original_price, FORMAT(s.price * 0.8, 2) AS discounted_price -- create alias
	--  calculate percentage 0.8 to obtain 20% off original price
    -- format to show table with two decimal places
FROM products p -- universal set
JOIN sell s ON p.pid = s.pid
JOIN merchants m ON s.mid = m.mid
WHERE m.name = 'HP' AND p.category = 'Networking'; -- filter rows


-- 5. What did Uriel Whitney order from Acer? (make sure to at least retrieve product names and prices).
		-- need to combine customers with plce, orders, contain, products, sells, and merchants
			-- chain broken if there is no link with primary keys, everything has to be connected
					-- place, orders, contain, products, sells, and merchants have foreign keys needed
		-- need name of customers 
        -- need price of products 
        -- where to ensure query only returns what Uriel Whitney bought from Acer
SELECT DISTINCT p.name AS product_name, s.price AS product_price -- alias and unique customers
FROM customers c -- universal set
JOIN place pl ON c.cid = pl.cid
JOIN orders o ON pl.oid = o.oid
JOIN contain co ON o.oid = co.oid
JOIN products p ON co.pid = p.pid
JOIN sell s ON p.pid = s.pid
JOIN merchants m ON s.mid = m.mid
WHERE c.fullname = 'Uriel Whitney' AND m.name = 'Acer'; -- filter rows


-- 6. List the annual total sales for each company (sort the results along the company and the year attributes).
		-- need merchants to combine with sell, contain, and place
			-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell, contain and place have foreign keys needed
        -- need year to determine annual sales
        -- need merchant name
        -- need sales to determine the amount of money made

SELECT m.name AS company, YEAR(p.order_date) AS year, FORMAT(SUM(s.price * s.quantity_available), 2) AS total_sales
FROM merchants m -- universal set
JOIN sell s ON m.mid = s.mid
JOIN contain c ON s.pid = c.pid
JOIN place p ON c.oid = p.oid
GROUP BY m.name, YEAR(p.order_date) -- filter
ORDER BY m.name, YEAR(p.order_date); -- how data is ordered in grid


-- 7. Which company had the highest annual revenue and in what year?
		-- need to create CTE of total revenue 
			-- need to combine merchants with sell, contain and place 
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell and products have foreign keys needed
		-- select to use CTE and determine highest revenue
WITH yearly_revenue AS ( -- creat CTE
    SELECT m.name AS company, YEAR(p.order_date) AS year, SUM(s.price * s.quantity_available) AS total_revenue -- alias
    FROM merchants m -- universal set
    JOIN sell s ON m.mid = s.mid
    JOIN contain c ON s.pid = c.pid
    JOIN place p ON c.oid = p.oid
    GROUP BY m.name, YEAR(p.order_date) -- filter rows
)
SELECT company, year, total_revenue
FROM yearly_revenue
WHERE total_revenue = (SELECT MAX(total_revenue) FROM yearly_revenue); -- only return max value



-- 8. On average, what was the cheapest shipping method used ever?
	-- select orders
    -- no need to join anything since just comparing shipping cost 
    -- need method, and cost
SELECT shipping_method, FORMAT(AVG(shipping_cost), 2) AS average_shipping_cost
FROM orders -- universal set
GROUP BY shipping_method
ORDER BY average_shipping_cost ASC -- smallest to greatest
LIMIT 1; -- will only show the cheapest method

-- 9. What is the best sold ($) category for each company?
	--  need to create CTE of total revenue 
			-- need to combine merchants with sell and procuts
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell and products have foreign keys needed
	-- select to use CTE and determine best sold category for ech company
WITH TotalRevenue AS ( -- Create CTE
    SELECT m.mid, p.category, FORMAT(SUM(s.price * s.quantity_available), 2) AS revenue
    FROM merchants m 
    JOIN sell s ON m.mid = s.mid
    JOIN products p ON s.pid = p.pid
    GROUP BY m.mid, p.category
),
RankedCategories AS (
    SELECT mid, category, revenue, 
           ROW_NUMBER() OVER (PARTITION BY mid ORDER BY revenue DESC) AS category_rank
    FROM TotalRevenue
)
SELECT mid, category AS best_sold_category, revenue
FROM RankedCategories 
WHERE category_rank = 1; -- filter rows


-- 10. For each company find out which customers have spent the most and the least amounts.
		--  need to create CTE of total revenue 
			-- need to combine merchants with sell, contain, orders, place, customers 
				-- chain broken if there is no link with primary keys, everything has to be connected
					-- sell, contain, orders, place, customers products have foreign keys needed
		-- select to use CTE and determine the mid with their customer that has spend the most and least amount of money at the company 
WITH customer_spending AS ( -- create CTE
    SELECT m.mid, c.cid, c.fullname, SUM(s.price * s.quantity_available) AS total_spent
    FROM merchants m -- universal set
    JOIN sell s ON m.mid = s.mid
    JOIN contain ct ON s.pid = ct.pid
    JOIN orders o ON ct.oid = o.oid
    JOIN place p ON o.oid = p.oid
    JOIN customers c ON p.cid = c.cid
    GROUP BY m.mid, c.cid, c.fullname
),

ranked_spending AS (
    SELECT mid, cid, fullname, total_spent,
        RANK() OVER (PARTITION BY mid ORDER BY total_spent DESC) AS spending_rank, -- rank is used to order
        RANK() OVER (PARTITION BY mid ORDER BY total_spent ASC) AS spending_rank_asc
    FROM customer_spending
)

SELECT mid,
    MAX(CASE WHEN spending_rank = 1 THEN fullname END) AS highest_spender, -- alias
    MAX(CASE WHEN spending_rank_asc = 1 THEN fullname END) AS lowest_spender -- alias
FROM ranked_spending
GROUP BY mid; -- filter




