DROP TRIGGER IF EXISTS phoneTrigger_bef_ins;
delimiter //

-- Триггер проверяет правильность номера телефона, например 89876543221

CREATE TRIGGER phoneTrigger_bef_ins BEFORE INSERT ON users
FOR EACH ROW
BEGIN
	IF(REGEXP_LIKE(NEW.phone, '^[0-9]{11}$')=0) 
	THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Trigger Warning! Not correct phone number!';
	END IF;

END //
delimiter ;

/* пробуем вставить - срабатывает триггер

INSERT INTO `users` VALUES (1,'Dewitt','Dooley',
'ojohnson@example.com',
'(544)027-76','817bc0453d4cab981c4ee9b739fde63124babc81',
'2009-03-22','Christiansenshire',
'772 Wade Crescent',
'f',
'1973-03-05 22:13:59');

*/

-- Триггер не опзволяет добавить пользователя младше 18 лет

DROP TRIGGER IF EXISTS NotYoungTrigger_bef_ins;
delimiter //
CREATE TRIGGER NotYoungTrigger_bef_ins BEFORE INSERT ON users
FOR EACH ROW
BEGIN
	IF(((TO_DAYS(NOW()) - TO_DAYS(NEW.birthday)) / 365.25)<18) 
	THEN
   		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Trigger Warning! The user must be over 18 years old';
	END IF;

END //
delimiter ;

 -- пробуем вставить - срабатывает триггер
/*
INSERT INTO `users` VALUES (102,'Dewitt','Dooley',
'ojohnson@exmple.com',
'81234567891','817bc0453d4cab981c4ee9b739fde63124babc81',
'2020-03-22','Christiansenshire',
'772 Wade Crescent',
'f',
'1973-03-05 22:13:59');
*/

-- триггер не позволяет добавить в заказ товар, если требуется больше чем есть на складе

DROP TRIGGER IF EXISTS CheckQuantityTrigger_bef_ins;
delimiter //
CREATE TRIGGER CheckQuantityTrigger_bef_ins BEFORE INSERT ON goods_in_orders
FOR EACH ROW
BEGIN
	IF(NEW.quantity > (SELECT quantity FROM goods WHERE id = NEW.goods_id)) 
	THEN
   		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Trigger Warning! Exceeded quantity';
	END IF;

END //
delimiter ;

-- пробуем вставить - срабатывает триггер

-- INSERT INTO goods_in_orders VALUES (1,1,300);

-- триггер умешьшает количество товара на складе в соответствии с количеством товара в заказе

DROP TRIGGER IF EXISTS quantityTrigger_after_upd;
delimiter //
CREATE TRIGGER quantityTrigger_after_upd AFTER INSERT ON goods_in_orders
FOR EACH ROW
BEGIN
	UPDATE  goods SET quantity = quantity - NEW.quantity WHERE id = NEW.goods_id;
END //
delimiter ;

/* проверяем работу триггера
 * 
SELECT quantity FROM goods WHERE id =1;

INSERT INTO goods_in_orders VALUES (1,1,1);

SELECT quantity FROM goods WHERE id = 1;

*/



