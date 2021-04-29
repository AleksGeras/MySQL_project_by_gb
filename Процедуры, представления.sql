DROP PROCEDURE  IF EXISTS post_processing_time_first;
delimiter //
-- Процедура меняет год в во временных столблах таблиц (кроме даты рождения) на 2019 и 2020, чтобы сильно 
-- не расстягивать статистику по времени 
CREATE PROCEDURE post_processing_time_first ()
BEGIN
	UPDATE users SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
	UPDATE goods SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
	UPDATE goods_photo SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
	UPDATE goods_comments SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
	UPDATE orders SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
	UPDATE orders SET updated_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(updated_at, '%m-%d %T') ) ;
	UPDATE orders SET updated_at = created_at WHERE created_at > updated_at;
	UPDATE guest_session SET created_at = concat(2019 + FLOOR(RAND() * 2), '-',date_format(created_at, '%m-%d %T') ) ;
END //

DROP PROCEDURE  IF EXISTS post_processing_goods_photo_time//

-- Процедура меняет дату создания фото товара, чтобы она была в соответствии с датой создания товара

CREATE PROCEDURE post_processing_goods_photo_time()
BEGIN
	UPDATE goods_photo SET created_at = 
	IF((SELECT created_at FROM goods WHERE goods.id = goods_photo.goods_id AND goods_photo.created_at > goods.created_at) IS NULL
	,(SELECT created_at FROM goods WHERE goods.id = goods_photo.goods_id),
	(SELECT created_at FROM goods WHERE goods.id = goods_photo.goods_id AND goods_photo.created_at > goods.created_at)
	); 
END //

DROP PROCEDURE  IF EXISTS post_processing_goods_comments_time//

-- Процедура меняет дату создания отзыва о товара, чтобы она была в соответствии с 
-- датой создания товара и датой регистрации пользователя

CREATE PROCEDURE post_processing_goods_comments_time()
BEGIN
	CREATE OR REPLACE VIEW goods_comments_time(id, time_good, time_user, time_comment) AS 
	SELECT goods_comments.id,goods.created_at,  users.created_at, goods_comments.created_at 
	FROM goods_comments
	LEFT JOIN goods 
	ON goods.id = goods_comments.goods_id AND goods_comments.created_at < goods.created_at 
	LEFT JOIN users 
	ON users.id = goods_comments.user_id AND goods_comments.created_at < users.created_at;
	
	CREATE OR REPLACE VIEW right_time_for_goods_comments(id,right_time) AS
	SELECT id,
		CASE
	    WHEN time_good > time_user THEN time_good
	    WHEN time_good < time_user THEN time_user
	    WHEN time_good IS NOT NULL AND time_user IS NULL THEN time_good
	    WHEN time_user IS NOT NULL AND time_good IS NULL THEN time_user
	    WHEN time_user IS NULL AND time_good IS NULL THEN time_comment
		END AS right_time
	FROM goods_comments_time;
	
	DROP TABLE IF EXISTS right_time_for_goods_comments_temp;
	CREATE TEMPORARY TABLE right_time_for_goods_comments_temp SELECT id, right_time FROM right_time_for_goods_comments;
	
	UPDATE goods_comments SET created_at = 
		(SELECT right_time 
		 FROM right_time_for_goods_comments_temp 
		 WHERE goods_comments.id = right_time_for_goods_comments_temp.id);
END //

DROP PROCEDURE  IF EXISTS post_processing_orders_time//

-- Процедура меняет дату создания заказа, чтобы она была в соответствии с датой создания товаров в 
-- заказе и датой регистрации пользователя

CREATE PROCEDURE post_processing_orders_time()
BEGIN
	CREATE OR REPLACE VIEW right_time_for_orders (id, right_time) AS 	
	SELECT id, MAX(right_time) AS right_time FROM
	(SELECT orders.id AS id ,
	orders.created_at AS time_order , 
	MAX(goods.created_at) AS time_goods, 
	users.created_at AS time_user,
	IF (MAX(goods.created_at) > users.created_at,MAX(goods.created_at),users.created_at) AS right_time
	FROM orders 
	JOIN goods_in_orders 
	ON goods_in_orders.order_id = orders.id
	JOIN goods 
	ON goods.id = goods_in_orders.goods_id 
	JOIN users 
	ON users.id = orders.user_id
	GROUP BY goods_id
	HAVING time_order < time_goods OR time_order < time_user) AS right_time_for_orders
	GROUP BY id;

	UPDATE orders SET created_at = 
		(SELECT right_time 
		FROM right_time_for_orders 
		WHERE orders.id = right_time_for_orders.id) 
	WHERE orders.id 
	IN (SELECT id FROM right_time_for_orders) ;
END //

DROP PROCEDURE  IF EXISTS post_processing_guest_session_time//

-- Процедура приравнивает время создания сессии и время создания заказа (первые 100 заказов соотвествуют первым 100 сессиям)
-- таким образом в первых 100 сессиях безусловно были заказы 

CREATE PROCEDURE post_processing_guest_session_time()
BEGIN
	UPDATE guest_session SET created_at = 
	(SELECT created_at 
	FROM orders 
	WHERE orders.id = guest_session.id);
END //

DROP PROCEDURE  IF EXISTS post_processing_guest_session_goods//

-- Процедура добавляет в таблицу goods_in_session товары которые находятся в таблице orders в соотвествии с таблицей guest_session 

CREATE PROCEDURE post_processing_guest_session_goods()
BEGIN
	
	DECLARE i INT DEFAULT 0;
	DECLARE goods INT DEFAULT 0;

	DROP TABLE IF EXISTS goods_add_for_session_temp;

	CREATE TEMPORARY TABLE goods_add_for_session_temp SELECT num, session_id, goods_id  FROM(
	SELECT @i := @i + 1 AS num, session_id, goods_id FROM 
	(SELECT  DISTINCT session_id , goods_orders AS goods_id FROM 
	(SELECT  orders.session_id ,  goods_in_orders.goods_id AS goods_orders , goods_in_session.goods_id AS goods_session FROM orders 
	 JOIN guest_session 
	ON orders.session_id = guest_session.id
	JOIN goods_in_orders 
	ON goods_in_orders.order_id = orders.id
	JOIN goods_in_session 
	ON goods_in_session.session_id = guest_session.id
	HAVING goods_orders NOT IN (SELECT goods_id 
								FROM goods_in_session 
								WHERE session_id = guest_session.id)) AS goods_add_for_session) AS unique_val, 
								(select @i:=0) AS num) AS temp;

							

	SET i = 1;
	SET goods = 1;
	
 
	WHILE i < (SELECT count(*) FROM goods_add_for_session_temp)+1 DO
		SET goods:= (SELECT goods_id  FROM goods_add_for_session_temp WHERE num = i);
	 	INSERT INTO goods_in_session (session_id, goods_id) 
	    VALUES (
	   	 (SELECT session_id FROM goods_add_for_session_temp WHERE num = i),
		 goods
	    	);
     	SET i = i + 1;
	END WHILE;
END //


DROP PROCEDURE  IF EXISTS post_processing_guest_session_records//

-- Процедура добавляет новые записи в таблицы guest_session и goods_in_session

CREATE PROCEDURE post_processing_guest_session_records()
BEGIN
	
	DECLARE i INT DEFAULT 0;		
	DECLARE j INT DEFAULT 0;

	SET i = 0;



	SET @min_date ='2019-05-01 00:00:00';
	SET @max_date ='2020-12-31 00:00:00';

	
	WHILE i < 400+FLOOR(RAND() * 600) DO
	 	INSERT INTO guest_session (ip_adress , created_at , session_type ) 
	    VALUES (
	   	 5000 + FLOOR(RAND() * 200000),
		 TIMESTAMPADD(SECOND, FLOOR(RAND()* TIMESTAMPDIFF(SECOND,@min_date,@max_date)),@min_date),
		 1+FLOOR(RAND() * 3)
	    	);
	    		SET j = 0;
	    		WHILE j < 1+FLOOR(RAND() * 8) DO
	    			SET @goods_id = 1+FLOOR(RAND() * (SELECT count(*) FROM goods));
	    			IF ( (SELECT created_at FROM guest_session  ORDER BY id DESC LIMIT 1) > (SELECT created_at FROM goods WHERE id = @goods_id) ) 
	    			THEN
	    				IF j = 0 THEN
	    				INSERT INTO goods_in_session (session_id , goods_id , time_session ) 
							   		VALUES (
										   	 (SELECT id FROM guest_session  ORDER BY id DESC LIMIT 1),
											 @goods_id,
											 60+FLOOR(RAND() * 180)
										    	);
	    				     	SET j = j + 1;
	    				END IF;
	    				IF j > 0 THEN
	    					IF @goods_id NOT IN (SELECT goods_id FROM goods_in_session WHERE session_id = (SELECT id FROM guest_session  ORDER BY id DESC LIMIT 1)) THEN
	    					    				INSERT INTO goods_in_session (session_id , goods_id , time_session ) 
							   		VALUES (
										   	 (SELECT id FROM guest_session  ORDER BY id DESC LIMIT 1),
											 @goods_id,
											 60+FLOOR(RAND() * 180)
										    	);
	    				     	SET j = j + 1;
	    					END IF;
	    				END IF;
	    				
	    			END IF;
	    		END WHILE;
     	SET i = i + 1;
	END WHILE;
END //

delimiter ;



CALL post_processing_time_first();
CALL post_processing_goods_photo_time();
CALL post_processing_goods_comments_time();
CALL post_processing_orders_time();
CALL post_processing_guest_session_time();
CALL post_processing_guest_session_goods();
CALL post_processing_guest_session_records();







