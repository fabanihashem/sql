/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */


SELECT 
product_name || ', ' || COALESCE( product_size,'')|| ' (' || COALESCE(product_qty_type,'unit') || ')'
FROM product;

--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

select customer_id ,  market_date , ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number
 from customer_purchases group by market_date, customer_id order by customer_id ;

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */



 
 create TEMPORARY TABLE temp_ranked_visit as 
 select customer_id,market_date, row_number()  over (partition by customer_id order by market_date desc) as visit_number from customer_purchases;
 
 select customer_id,market_date from temp_ranked_visit where visit_number=1;
 
 


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

 select  product_id,customer_id, count() As number_purchases from customer_purchases group by product_id, customer_id;


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
select product_name,
case when instr(product_name,'-') = 0 then '' 
else 
trim(ltrim(substr(product_name,instr(product_name,'-')) ,'-')) 
end as Description
from product;




/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

select product_name,
case when instr(product_name,'-') = 0 then '' 
else 
trim(ltrim(substr(product_name,instr(product_name,'-')) ,'-')) 
end as Description,product_size
from product where product_size regexp '[0-9]';


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

create  temporary table if not exists total_sale as
select market_date,sum(quantity*cost_to_customer_per_qty) as sale from customer_purchases  group by market_date ;
create TEMPORARY table if not exists  day_performance as
select rank() over (order by sale  asc) as wrost_day ,rank() over (order by sale  desc) as best_day, market_date, sale from total_sale ;


select market_date,sale,'wrost day' as label from day_performance
where wrost_day=1
union
select market_date,sale,'best day' as label  from day_performance
where best_day=1;

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */


SELECT
    v.vendor_name,
    p.product_name,
    (5 * count(distinct c.customer_id) * vi.original_price) as total_money_earned
from  vendor_inventory vi
join vendor v on vi.vendor_id = v.vendor_id
join product p ON vi.product_id = p.product_id
cross join customer c
group BY v.vendor_name, p.product_name, vi.original_price
order BY v.vendor_name, p.product_name;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

create table product_units as 
select  * , CURRENT_TIMESTAMP as snapshot_timestamp
from product where product_qty_type='unit';

/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

insert into product_units
select * , CURRENT_TIMESTAMP as snapshot_timestamp from product
where product_name = 'Apple Pie';

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/


delete from product_units where ROWID =(select ROWID from product_units where product_name ='Apple Pie'  
order by snapshot_timestamp asc 
limit 1);


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */




update product_units   
set current_quantity= coalesce((select quantity from vendor_inventory  where product_units.product_id= vendor_inventory.product_id order by market_date desc limit 1)  ,0);