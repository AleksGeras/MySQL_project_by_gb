DROP DATABASE IF EXISTS web_shop;

CREATE DATABASE web_shop;

USE web_shop;



-- 	Хранит основные данные о пользователях 
-- (e-mail, пароль, ФИО, город, номер телефона, 
-- адрес доставки, статус, прочую информацию)

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, -- id пользователя
  first_name VARCHAR(145) NOT NULL, -- имя
  last_name VARCHAR(145) NOT NULL, -- фамилия
  email VARCHAR(145) NOT NULL, -- эл. почта
  phone CHAR(11) NOT NULL, -- телефон
  password_hash CHAR(65) DEFAULT NULL, -- хэш пароля
  birthday DATE NOT NULL, -- дата рождения
  city VARCHAR(130), -- город проживания
  delivery_address VARCHAR(130), -- адрес доставки
  gender ENUM('f', 'm') NOT NULL, -- пол
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- дата регистрации
  UNIQUE INDEX email_unique_idx (email),
  UNIQUE INDEX phone_unique_idx (phone)
) ENGINE=InnoDB;


-- 	Хранит основную информацию о товаре 
-- (название, товара, цена, код подкатегории 
-- количество товара на складе, 

CREATE TABLE goods (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id товара
  subcategory_id INT, -- id подкатегории - ссылка на таблицу subcategory
  title VARCHAR(30) NOT NULL, -- название товара
  description VARCHAR(255), -- описание товара
  cost INT NOT NULL, -- цена товара в руб
  quantity INT NOT NULL, -- количество товара 
  manufacturer_id INT, -- id производителя - ссылка на таблицу manufacturer
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP -- дата регистрации товара
);  

	
-- Хранит информацию о фотографиях товара – 
-- код фотографии, код товара, ссылку на фотографию, 
-- а также параметр который указывает является 
-- ли фотография главной

CREATE TABLE goods_photo (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id фотографии
  goods_id BIGINT UNSIGNED NOT NULL, -- id товара - ссылка на таблицу goods
  photo_link VARCHAR(255), -- ссылка на фото
  photo_description VARCHAR(255), -- описание фото
  photo_is_main BOOLEAN, -- является ли фото главным
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP -- дата загрузки фото
); 

	
-- Хранит об отзывах на товар – текст комментария, 
-- код пользователя оставившего комментарий, 
-- код товара к которому относится данный комментарий, 
-- дату и время создания комментария 

CREATE TABLE goods_comments (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id отзыва
  user_id BIGINT UNSIGNED, -- id пользователя отставившего отзыв - ссылка на таблицу users
  comment VARCHAR(255), -- текст отзыва
  goods_id BIGINT UNSIGNED NOT NULL, -- id товара - ссылка на таблицу goods
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- дата создания отзыва
  score INT NOT NULL -- оценка товара по пятибальной шкале
); 

-- Таблица хринит информацию о подкатегориях товаров (один товар может быть в нескольких подкатегориях)

CREATE TABLE subcategory (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id подкатегории
  subcategory_title VARCHAR(30), -- название подкатегории
  subcategory_descriptio VARCHAR(255) -- описание подкатегории
);

-- Таблица хранит информацию о производителях товаров

CREATE TABLE manufacturer (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id производителя
  manufacturer_title VARCHAR(30) -- наименование производителя
);

-- Таблица хранит основную информацию о заказе 

CREATE TABLE orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id заказа
  user_id BIGINT UNSIGNED, -- id пользователя - ссылка на таблицу users
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- дата заказа
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- дата редакирования заказа
  order_delivery_type INT UNSIGNED NOT NULL, -- тип доставки - ссылка на таблицу delivery_type
  order_status_type  INT UNSIGNED NOT NULL, -- статус заказа  - ссылка на таблицу status_type
  session_id BIGINT UNSIGNED -- id сессии в течение которой был произведен заказ - ссылка на таблицу guest_session
);

-- Таблица типов доставки

CREATE TABLE delivery_type (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id типа типа доставки
	name VARCHAR(30) -- наименование самовывоз, курьер, почта России
);

-- Таблица типов статусов заказа

CREATE TABLE status_type (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id типа статуса
	name VARCHAR(30) -- наименование в обработке, исполнен, отменен
);

-- Таблица содежит информацию и товарах в заказе пользователя (корзина покупателя)

CREATE TABLE goods_in_orders (
  order_id BIGINT UNSIGNED NOT NULL, -- id заказа - ссылка на таблицу order
  goods_id BIGINT UNSIGNED NOT NULL, -- id товара - ссылка на таблицу goods
  PRIMARY KEY(order_id, goods_id),
  quantity INT NOT NULL -- количество товара в заказе
);

-- Таблица содержит информацию о веб-сессиях посетителей интернет-магазина 
-- session_type -- тип сессии посетитель зарегистировался, вошел в аккаунт, 
-- посетитель просто ушел - ссылка на таблицу session_types

CREATE TABLE guest_session (
	id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, -- id сессии
	ip_adress INT UNSIGNED NOT NULL, -- ip-адресс посетителя
	created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- дата начала сессии
	session_type INT UNSIGNED NOT NULL 
);

-- Таблица типов веб-сессий посетителей интернет-магазина 

CREATE TABLE session_types (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id типа сессии
	name VARCHAR(30) -- наименование была произведена регистрация, вход, посетитель просто ушел
);

-- Таблица содержит информацию о товарах просмотренных посетителем в течении сессии

CREATE TABLE goods_in_session (
	session_id BIGINT UNSIGNED, -- id сессии - ссылка на таблицу guest_session
	goods_id BIGINT UNSIGNED NOT NULL, -- id товара просмторенного в сессии - ссылка на таблицу goods
	PRIMARY KEY(session_id, goods_id),
	time_session INT NOT NULL DEFAULT 120 -- время просмтора товара в секундах
);
