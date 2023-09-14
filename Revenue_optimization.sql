use Sports_DA
-- loading the data  --   
select * from dbo.brands_v2 ;
    -- the tables brand_v2 contains product_id and brands 
select DISTINCT BRAND FROM dbo.brands_v2;
    -- it contains only two brands Adidad and nike, few null values too 

select * from dbo.finance;
    -- The table finance contains Product_id, listing_price, sale_price, discount, revenue
select * from dbo.info_v2;
    -- The table info_v2 contains product_name, product_id, desription of the product
select * from dbo.reviews_v2;
    -- The table reviews_v2 contains product_id, rating, reviews  
select * from dbo.traffic_v3; 
    -- The table traffic_v3 contains product_id, last_visited 
-- It can be concluded that product_id is a primery key


-- Measuring the % of missing values in the data in each table for some specific values 
SELECT COUNT(*) AS TOTAL_ROWS,
CAST(ROUND(((COUNT(*)-COUNT(LISTING_PRICE))/CAST(COUNT(*) AS decimal(18,4)))*100 , 4) AS decimal(18,4)) AS percent_fin_miss,
CAST(ROUND(((COUNT(*)-COUNT(description))/CAST(COUNT(*) AS decimal(18,4)))*100 , 4) AS decimal(18,4)) AS percent_des_miss,
CAST(ROUND(((COUNT(*)-COUNT(last_visited))/CAST(COUNT(*) AS decimal(18,4)))*100 , 4) AS decimal(18,4)) AS percent_lv_miss
FROM info_v2 
JOIN finance ON info_v2.product_id = finance.product_id 
JOIN traffic_v3 ON info_v2.product_id = traffic_v3.product_id 
  --- from the above calculation there are nearly 8% of data is missing from the last_vistied column and nearly 2% data in other both of them
  

SELECT brand, CAST(listing_price as int) as listing_price,count(listing_price) as count_
from brands_v2
JOIN finance ON brands_v2.product_id = finance.product_id 
where listing_price > 0
GROUP BY CAST(listing_price as int),brand 
ORDER BY CAST(listing_price as int) DESC ; 
  -- From given data it can be concluded that the among top 10 prices listed, 8 are addidas 

                        --- Checking the revenues 
SELECT SUM(revenue) FROM finance 
JOIN brands_v2 ON finance.product_id = brands_v2.product_id 
WHERE  brand = 'Adidas' ; 
 ---- 11526619.0840302 revenue of ADIDAS
 
 SELECT SUM(revenue) FROM finance 
JOIN brands_v2 ON finance.product_id = brands_v2.product_id 
WHERE  brand = 'Nike' ; 
--- 802283.25894165 revenue of Nike 
                ---- IN THE GIVEN DATA REVENUE OF ADIDAS IS MORE THAN NIKE
				

				---  Creating different cateogories based on price
SELECT b.brand, COUNT(*) as count , SUM(f.revenue) as total_revenue,
CASE WHEN f.listing_price < 42 THEN 'Budget'
     WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
     WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
     ELSE 'Elite' END AS price_category
FROM finance as f 
INNER JOIN brands_v2 as b
ON b.product_id = f.product_id
GROUP BY b.brand,
         CASE WHEN f.listing_price < 42 THEN 'Budget'
     WHEN f.listing_price >= 42 AND f.listing_price < 74 THEN 'Average'
     WHEN f.listing_price >= 74 AND f.listing_price < 129 THEN 'Expensive'
     ELSE 'Elite' END
HAVING b.brand IS NOT NULL
ORDER BY total_revenue DESC;
---The company can increase Elite products as it has scope of generating high revenue  

 
        --- Checking the average discount
SELECT b.brand,  AVG(f.discount)*100 as average_discount
FROM brands_v2 as b 
JOIN finance as f
ON b.product_id = f.product_id
GROUP BY b.brand
HAVING b.brand IS NOT NULL;  

--- From the data given Adidas gives more discount than compared to nike which give no discount.


        --- Calcualting the correlation between revenue and review 
SELECT
    SUM((f.revenue - f_avg) * (r.reviews - r_avg)) / 
    (SQRT(SUM(POWER(f.revenue - f_avg, 2)) * SUM(POWER(r.reviews - r_avg, 2)))) AS review_revenue_corr
FROM finance AS f
INNER JOIN reviews_v2 AS r ON f.product_id = r.product_id
CROSS APPLY (SELECT AVG(revenue) AS f_avg FROM finance) AS f_avg
CROSS APPLY (SELECT AVG(reviews) AS r_avg FROM reviews_v2) AS r_avg;
 --- there is a nice correlation between the revenue and reviews 

 SELECT
    SUM((f.revenue - f_avg) * (r.rating - r_avg)) / 
    (SQRT(SUM(POWER(f.revenue - f_avg, 2)) * SUM(POWER(r.rating - r_avg, 2)))) AS rating_revenue_corr
FROM finance AS f
INNER JOIN reviews_v2 AS r ON f.product_id = r.product_id
CROSS APPLY (SELECT AVG(revenue) AS f_avg FROM finance) AS f_avg
CROSS APPLY (SELECT AVG(rating) AS r_avg FROM reviews_v2) AS r_avg;

            --- there is no correlation between the revenue and rating 0.114493354449688


    --- Investigating number of reviews
SELECT b.brand, DATEPART(month, t.last_visited) AS month,
    COUNT(r.reviews) AS num_reviews
FROM traffic_v3 as t
INNER JOIN brands_v2 as b ON t.product_id = b.product_id
INNER JOIN reviews_v2 as r ON t.product_id = r.product_id
GROUP BY b.brand, DATEPART(month, t.last_visited)
HAVING b.brand IS NOT NULL 
AND DATEPART(month, t.last_visited) IS NOT NULL
ORDER BY b.brand, month; 

           -- Creating cte to finding revenue of foot wear and clothewear 

WITH footwear AS (
    SELECT i.description, f.revenue,b.brand
    FROM info_v2 i JOIN finance f ON i.product_id = f.product_id
	JOIN brands_v2 b on i.product_id = b.product_id
    WHERE i.description LIKE '%shoe%' OR 
    i.description LIKE '%trainer%' OR 
    i.description LIKE '%foot%' AND
    i.description IS NOT NULL
)
SELECT count(*) as count , AVG(Revenue) as AVG_Revenue FROM footwear
 WHERE brand ='Adidas'; 


WITH clothing AS (
    SELECT i.description, f.revenue, b.brand
    FROM info_v2 i  JOIN finance f ON i.product_id = f.product_id
	JOIN brands_v2 b on i.product_id = b.product_id
    WHERE i.description NOT LIKE '%shoe%' AND 
    i.description NOT LIKE '%trainer%' AND 
    i.description NOT LIKE '%foot%' AND
    i.description IS NOT NULL
)
SELECT count(*) as count, AVG(revenue) as AVG_REVENUE FROM clothing 
 WHERE brand = 'Adidas';

--- AVG revenue of foot wear product is more than clothing by nearly 2000 $ 


