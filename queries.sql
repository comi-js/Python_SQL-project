--Find different payment methods, number of transactions and quantity sold

SELECT payment_method,COUNT(*) as num_of_payments, SUM(quantity) as quantity_sold
FROM walmart
GROUP BY payment_method

--Find the highest-rated category in each branch

SELECT * 
FROM(	
	SELECT branch, category, AVG(rating) as avg_rating,
	RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
FROM walmart
GROUP BY 1, 2
)
WHERE rank = 1

--Find the busiest day for each branch based on the number of transactions

SELECT * 
FROM(
	SELECT branch, TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') as formated_to_day, COUNT(*) as no_transactions,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart
GROUP BY 1, 2
)
WHERE rank = 1

--Find the total quantity of items sold per payment method

SELECT payment_method, SUM(quantity) as quantity_sold
FROM walmart
GROUP BY payment_method

--Find the average, minimum, and maximum rating of category for each city

SELECT city, category, MIN(rating) as min_rating, MAX(rating) as max_rating, AVG(rating) as avg_rating
FROM walmart
GROUP BY 1, 2

--Find the total profit for each category by considering total_profit as (unit_price * quantity * profit_margin)

SELECT category, SUM(total) as total_revenue, SUM(total * profit_margin) as profit
FROM walmart
GROUP BY 1

--Find the most common payment method for each branch

WITH cte 
AS(
	SELECT branch, payment_method, COUNT(*) as total_transactions,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart
GROUP BY 1, 2
)

SELECT *
FROM cte
WHERE rank = 1

-- Categorize sales into 3 groups: morning, afternoon, evening. 
-- Get total number of invoices for each shift for each branch

SELECT branch,
CASE 
		WHEN EXTRACT(HOUR FROM(time::time)) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM(time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END day_time,
	COUNT(*)
FROM walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC

--Find five branches with the highest decrease in revevenue compared to last year

SELECT *, EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) as formated_date
FROM walmart;

WITH revenue_2022
AS(
	SELECT branch, SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022 
	GROUP BY 1
),
revenue_2023
AS(
	SELECT branch, SUM(total) as revenue
	FROM walmart
	WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
	GROUP BY 1
)

SELECT ls.branch, ls.revenue as last_year_revenue, cs.revenue as current_year_revenue,
	ROUND((ls.revenue - cs.revenue)::numeric/ls.revenue::numeric * 100, 2) as revenue_decrease_ratio
FROM revenue_2022 as ls
JOIN revenue_2023 as cs ON ls.branch = cs.branch
WHERE ls.revenue > cs.revenue
ORDER BY 4 DESC
LIMIT 5