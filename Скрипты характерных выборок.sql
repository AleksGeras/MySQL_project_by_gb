-- Адекватные названия зписей в таблицах status_type, session_types, delivery_type

UPDATE status_type 
    SET name = CASE id
        WHEN 1 THEN 'in_process'
        WHEN 2 THEN 'done'
        WHEN 3 THEN 'cancelled'
    END;

UPDATE session_types 
    SET name = CASE id
        WHEN 1 THEN 'registration'
        WHEN 2 THEN 'sign_in'
        WHEN 3 THEN 'guest'
    END;
    
UPDATE delivery_type 
    SET name = CASE id
        WHEN 1 THEN 'pick-up'
        WHEN 2 THEN 'courier'
        WHEN 3 THEN 'post'
    END;
    
   
-- 1) средний возраст пользователей

SELECT ROUND(AVG((TO_DAYS(NOW()) - TO_DAYS(birthday)) / 365.25), 0) AS AVG_Age FROM users;

-- 2) кто совершил больше всего потратился на покупки, женщины или мужчины

SELECT gender FROM (
SELECT SUM(goods_in_orders.quantity*goods.cost) AS money, gender FROM goods_in_orders
JOIN orders 
ON goods_in_orders.order_id = orders.id AND orders.order_status_type = 2
JOIN users 
ON orders.user_id = users.id
JOIN goods 
ON goods_in_orders.goods_id = goods.id
GROUP BY gender
ORDER BY money DESC
LIMIT 1) AS max_buy
;


-- 3) 5 наиболее продаваемых товаров c их количеством и наименованием производителя

SELECT goods_id, SUM(goods_in_orders.quantity ) AS total_quantity , manufacturer.manufacturer_title AS  manufacturer 
FROM goods_in_orders 
JOIN orders 
ON goods_in_orders.order_id = orders.id AND (orders.order_status_type = 1 OR orders.order_status_type = 2)
JOIN goods 
ON goods_in_orders.goods_id = goods.id 
JOIN manufacturer 
ON goods.manufacturer_id = manufacturer.id 
GROUP BY goods_id  
ORDER BY total_quantity DESC 
LIMIT 5;


-- 4) ниаболее встречающийся товар в отмененных заказах 

SELECT goods_id, COUNT(goods_id) AS rejection FROM goods_in_orders
JOIN orders 
ON goods_in_orders.order_id = orders.id AND (orders.order_status_type = 3)
GROUP BY goods_id
ORDER BY rejection DESC
LIMIT 1;

-- 5) товары количество которых меньше 100

SELECT * FROM goods WHERE quantity <100;

-- 6) id товаров без фотографии

SELECT id FROM goods WHERE id NOT IN (SELECT goods_id FROM goods_photo);

-- 7) вывести товары со средней оценкой больше 3,5 с количеством отзывов и id товара

SELECT AVG(score) AS top, count(score) AS comment_count, goods_id  
FROM goods_comments 
GROUP BY goods_id 
HAVING top > 3.5
ORDER BY top DESC;


-- 8) вывести 5 наиболее активных пользователей 
-- (активноость =  кол-во отзывов пользователя + количество товаров в заказах пользователя)

SELECT CONCAT ('id: ', id, ' - ', first_name, ' ', last_name) AS user,
((SELECT COUNT(*) AS activity FROM goods_comments WHERE goods_comments.user_id = users.id)
+
(SELECT COUNT(*) AS activity FROM orders
JOIN goods_in_orders 
ON orders.id = goods_in_orders.order_id AND orders.user_id = users.id 
AND (orders.order_status_type = 1 OR orders.order_status_type = 2))) AS overal_activity
FROM users
ORDER BY overal_activity DESC
LIMIT 5;

-- 9) категория товаров в которой больше всего просмотров пользователей

SELECT count(*) AS views, subcategory.subcategory_title AS name FROM goods_in_session
JOIN goods ON goods_in_session.goods_id = goods.id 
JOIN subcategory ON goods.subcategory_id = subcategory.id
GROUP BY name 
ORDER BY views DESC
LIMIT 1;


-- 10) категория товаров с набольшим количеством заказов 

SELECT COUNT(*) AS num_goods_in_ord,subcategory_title FROM orders
JOIN goods_in_orders ON goods_in_orders.order_id = orders.id 
JOIN goods ON goods_in_orders.goods_id = goods.id 
JOIN subcategory ON goods.subcategory_id = subcategory.id
WHERE (orders.order_status_type = 1 OR orders.order_status_type = 2)
GROUP BY subcategory_title 
ORDER BY num_goods_in_ord DESC
LIMIT 1;

-- 11) трафик – количество посещений интернет-магазина по месяцам;

SELECT COUNT(*) AS traffic ,
CONCAT(YEAR(created_at),'-', IF(MONTH(created_at)<10,concat('0',(MONTH(created_at))),MONTH(created_at) )) AS time 
FROM guest_session 
GROUP BY time 
ORDER BY time;

-- 12) средняя продолжительность взаимодействия с ресурсом, в секундах;

SELECT AVG(time) FROM (SELECT SUM(time_session) AS time FROM goods_in_session GROUP BY session_id) AS session;

-- 13) процент посетителей, которые просмотрели зашли на сайт и не совершили конверсионное действие(заказ) по месяцам

SELECT order_count/session_count*100 AS conversion, orders.time AS time  FROM
(SELECT count(*) AS order_count , CONCAT(YEAR(created_at),'-', 
IF(MONTH(created_at)<10,concat('0',(MONTH(created_at))),MONTH(created_at) )) AS time 
FROM orders 
WHERE order_status_type = 1 OR order_status_type = 2 
GROUP BY time
ORDER BY time) AS orders
JOIN
(SELECT count(*) AS session_count, CONCAT(YEAR(created_at),'-', 
IF(MONTH(created_at)<10,concat('0',(MONTH(created_at))),MONTH(created_at) )) AS time
FROM guest_session
WHERE session_type =1 OR session_type =2
GROUP BY time
ORDER BY time) AS sessions
ON orders.time = sessions.time; 

-- 14) товарооборот – объем реализации в денежном выражении за отчетный период (2019-2020)

SELECT 
SUM(cost) AS profit,
CONCAT(YEAR(orders.created_at),'-', 
IF(MONTH(orders.created_at)<10,concat('0',(MONTH(orders.created_at))),MONTH(orders.created_at) )) AS time
FROM orders
JOIN goods_in_orders ON orders.id = goods_in_orders.order_id
JOIN goods ON goods_in_orders.goods_id = goods.id
WHERE orders.order_status_type = 2 AND (YEAR(orders.created_at) = 2019 OR YEAR(orders.created_at) = 2020)
GROUP BY time
ORDER BY time;

-- 15) средняя сумма заказа
SELECT AVG(cheque) FROM
(SELECT SUM(cost) AS cheque
FROM orders
JOIN goods_in_orders ON orders.id = goods_in_orders.order_id
JOIN goods ON goods_in_orders.goods_id = goods.id
WHERE orders.order_status_type = 2
GROUP BY orders.id) AS cheques_in_orders;

-- 16) количество уникальных посетителей по месяцам
SELECT count(ip_adress) AS unique_guests, time FROM
(SELECT DISTINCT ip_adress ,CONCAT(YEAR(created_at),'-', 
IF(MONTH(created_at)<10,concat('0',(MONTH(created_at))),MONTH(created_at) )) AS time
FROM guest_session
WHERE session_type !=2) AS ip_by_month
GROUP BY time 
ORDER BY time;




