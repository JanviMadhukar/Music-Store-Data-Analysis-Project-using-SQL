/* Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */
SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;


/* Q2: Which countries have the most Invoices? */
SELECT COUNT(*) AS invoice_count, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;


/* Q3: What are top 3 values of total invoice? */
SELECT total 
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spending
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spending DESC
LIMIT 1;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM invoice AS i
JOIN customer AS c ON i.customer_id = c.customer_id
JOIN invoice_line AS il ON il.invoice_id = i.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT a.name AS artist_name, COUNT(t.track_id) AS track_count
FROM artist AS a
JOIN album AS al ON a.artist_id = al.artist_id
JOIN track AS t ON al.album_id = t.album_id
JOIN genre AS g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY a.artist_id, a.name
ORDER BY track_count DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM track)
ORDER BY milliseconds DESC;


/* Question Set 3 - Advance */

/* Q1: Which customers spent the most money on the best-selling artist?
Write a query to return each customer's name, the best-selling artist's name, and the total amount they spent on that artist.
Order the results by total spent in descending order. */

WITH best_selling_artist AS (
    SELECT a.artist_id, a.name AS artist_name, 
           SUM(il.unit_price * il.quantity) AS total_sales
    FROM artist AS a
    JOIN album AS al ON a.artist_id = al.artist_id
    JOIN track AS t ON al.album_id = t.album_id
    JOIN invoice_line AS il ON t.track_id = il.track_id
    GROUP BY a.artist_id, a.name
    ORDER BY total_sales DESC
    LIMIT 1
)
SELECT c.first_name, c.last_name, bsa.artist_name, 
       SUM(il.unit_price * il.quantity) AS total_spent
FROM customer AS c
JOIN invoice AS i ON c.customer_id = i.customer_id
JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
JOIN track AS t ON il.track_id = t.track_id
JOIN album AS al ON t.album_id = al.album_id
JOIN best_selling_artist AS bsa ON al.artist_id = bsa.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY total_spent DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Method 1: Using CTE with RANK to handle ties */
WITH genre_purchases AS (
    SELECT c.country, g.name AS genre_name, 
           COUNT(il.invoice_line_id) AS purchase_count,
           DENSE_RANK() OVER(PARTITION BY c.country ORDER BY COUNT(il.invoice_line_id) DESC) AS rank
    FROM invoice AS i
    JOIN customer AS c ON i.customer_id = c.customer_id
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
)
SELECT country, genre_name, purchase_count
FROM genre_purchases
WHERE rank = 1
ORDER BY country, purchase_count DESC;

/* Method 2: Using MAX with JOIN */
WITH country_genre_purchases AS (
    SELECT c.country, g.name AS genre_name, 
           COUNT(il.invoice_line_id) AS purchase_count
    FROM invoice AS i
    JOIN customer AS c ON i.customer_id = c.customer_id
    JOIN invoice_line AS il ON i.invoice_id = il.invoice_id
    JOIN track AS t ON il.track_id = t.track_id
    JOIN genre AS g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
),
max_purchases AS (
    SELECT country, MAX(purchase_count) AS max_purchase
    FROM country_genre_purchases
    GROUP BY country
)
SELECT cgp.country, cgp.genre_name, cgp.purchase_count
FROM country_genre_purchases cgp
JOIN max_purchases mp ON cgp.country = mp.country AND cgp.purchase_count = mp.max_purchase
ORDER BY cgp.country, cgp.purchase_count DESC;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Method 1: Using DENSE_RANK to handle ties */
WITH customer_spending AS (
    SELECT c.country, 
           c.first_name || ' ' || c.last_name AS customer_name,
           SUM(i.total) AS total_spent,
           DENSE_RANK() OVER(PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS rank
    FROM customer AS c
    JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.country, c.first_name, c.last_name
)
SELECT country, customer_name, total_spent
FROM customer_spending
WHERE rank = 1
ORDER BY country, total_spent DESC;

/* Method 2: Using MAX with JOIN */
WITH country_customer_spending AS (
    SELECT c.country, 
           c.first_name || ' ' || c.last_name AS customer_name,
           SUM(i.total) AS total_spent
    FROM customer AS c
    JOIN invoice AS i ON c.customer_id = i.customer_id
    GROUP BY c.country, c.first_name, c.last_name
),
max_spending AS (
    SELECT country, MAX(total_spent) AS max_spent
    FROM country_customer_spending
    GROUP BY country
)
SELECT ccs.country, ccs.customer_name, ccs.total_spent
FROM country_customer_spending ccs
JOIN max_spending ms ON ccs.country = ms.country AND ccs.total_spent = ms.max_spent
ORDER BY ccs.country, ccs.total_spent DESC;