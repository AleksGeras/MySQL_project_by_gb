   ALTER TABLE goods 
  ADD CONSTRAINT goods_subcategory_id_fk
  FOREIGN KEY (subcategory_id) REFERENCES subcategory(id)
    ON DELETE SET NULL;
   
    ALTER TABLE goods 
  ADD CONSTRAINT goods_manufacturer_id_fk
  FOREIGN KEY (manufacturer_id) REFERENCES manufacturer(id)
    ON DELETE SET NULL;  
 
    ALTER TABLE goods_photo 
  ADD CONSTRAINT goods_photo_goods_id_fk
  FOREIGN KEY (goods_id) REFERENCES goods(id)
    ON DELETE CASCADE;
   
    ALTER TABLE goods_comments 
  ADD CONSTRAINT goods_comments_user_id_fk
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE SET NULL;   
   
    ALTER TABLE goods_comments 
  ADD CONSTRAINT goods_comments_goods_id_fk
  FOREIGN KEY (goods_id) REFERENCES goods(id)
    ON DELETE CASCADE;  
   
     ALTER TABLE orders 
  ADD CONSTRAINT orders_user_id_fk
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE;   
   
   ALTER TABLE orders DROP FOREIGN KEY orders_order_status_type_fk;

     ALTER TABLE orders 
  ADD CONSTRAINT orders_order_delivery_type_fk
  FOREIGN KEY (order_delivery_type) REFERENCES delivery_type(id)
    ON DELETE CASCADE;
   
     ALTER TABLE orders 
  ADD CONSTRAINT orders_order_status_type_fk
  FOREIGN KEY (order_status_type) REFERENCES status_type(id)
    ON DELETE CASCADE;
   
        ALTER TABLE orders 
  ADD CONSTRAINT orders_session_id_fk
  FOREIGN KEY (session_id) REFERENCES guest_session(id)
    ON DELETE SET NULL;
   
     ALTER TABLE goods_in_orders 
  ADD CONSTRAINT goods_in_orders_order_id_fk
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON DELETE CASCADE;
   
     ALTER TABLE goods_in_orders 
  ADD CONSTRAINT goods_in_orders_goods_id_fk
  FOREIGN KEY (goods_id) REFERENCES goods(id)
    ON DELETE CASCADE;  
   
     ALTER TABLE guest_session 
  ADD CONSTRAINT guest_session_session_type_fk
  FOREIGN KEY (session_type) REFERENCES session_types(id)
    ON DELETE CASCADE;  
   
     ALTER TABLE goods_in_session 
  ADD CONSTRAINT goods_in_session_session_id_fk
  FOREIGN KEY (session_id) REFERENCES guest_session(id)
    ON DELETE CASCADE; 
   
     ALTER TABLE goods_in_session 
  ADD CONSTRAINT goods_in_goods_id_fk
  FOREIGN KEY (goods_id) REFERENCES goods(id)
    ON DELETE CASCADE; 