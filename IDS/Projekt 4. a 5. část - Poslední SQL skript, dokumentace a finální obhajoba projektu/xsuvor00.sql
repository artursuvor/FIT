spool  ARTUR.txt  
  DROP TABLE accomodation;
  DROP TABLE payment;
  DROP TABLE room;
  DROP TABLE reservation;
  DROP TABLE customer;
  DROP TABLE receptionist;

  --ROOM
  CREATE TABLE room (
    nmbr INT NOT NULL PRIMARY KEY,
    availableness VARCHAR(80) NOT NULL,
    type VARCHAR(80) NOT NULL,
    price FLOAT NOT NULL,
    number_of_beds INT NOT NULL
  );

  --CUSTOMER
  CREATE TABLE customer (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    birthdate DATE NOT NULL,
    phone_number VARCHAR(12) NOT NULL,
    address VARCHAR(80) NOT NULL,
    email VARCHAR(80) NOT NULL
  );

  --RECEPTION
  CREATE TABLE receptionist (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    birthdate DATE NOT NULL,
    phone_number VARCHAR(12) NOT NULL,
    address VARCHAR(80) NOT NULL,
    email VARCHAR(80) NOT NULL
  );

  --REZERVATION
  CREATE TABLE reservation (
    id_reservation INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    user_id INT NOT NULL ,
    CONSTRAINT customer_id_fk 
      FOREIGN KEY (user_id) REFERENCES customer (id)
        ON DELETE CASCADE,
        id_receptionist INT NOT NULL ,
    CONSTRAINT receptionist_id_fk 
      FOREIGN KEY (id_receptionist) REFERENCES receptionist (id)
        ON DELETE CASCADE,
     check_in DATE NOT NULL,
     check_out DATE NOT NULL,
     number_of_people INT NOT NULL,
     number_of_rooms INT NOT NULL,
     serv_req VARCHAR(80) NOT NULL,
     state VARCHAR(80) NOT NULL
    
  );

  --PAYING 
  CREATE TABLE payment (
    payment_id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    user_id INT NOT NULL ,
    CONSTRAINT payment_id_fk 
      FOREIGN KEY (user_id) REFERENCES customer (id)
        ON DELETE CASCADE,
         id_reservation INT NOT NULL ,
    CONSTRAINT reservation_id_fk 
      FOREIGN KEY (id_reservation) REFERENCES reservation (id_reservation)
        ON DELETE CASCADE,
     amount INT NOT NULL,
     type VARCHAR(20) NOT NULL
  );

  --LENGTH OF STAY
  CREATE TABLE accomodation (
    accomodation_id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    reservation_id  INT NOT NULL, 
    CONSTRAINT reserv_id_fk 
     FOREIGN KEY (reservation_id) REFERENCES reservation (id_reservation)
       ON DELETE CASCADE,
    number_room INT NOT NULL,
    CONSTRAINT number_room_fk 
      FOREIGN KEY (number_room) REFERENCES room (nmbr)
        ON DELETE CASCADE,
     check_in DATE NOT NULL,
     check_out DATE NOT NULL,
     number_of_people INT NOT NULL,
     number_of_rooms INT NOT NULL,
     state VARCHAR(80) NOT NULL
  );

  -- PROCEDURE --
CREATE OR REPLACE PROCEDURE PAY_ROOM AUTHID DEFINER
IS
v_idres RESERVATION.id_reservation%TYPE;
v_pay PAYMENT.amount%TYPE;
v_name CUSTOMER.name%TYPE;
v_email CUSTOMER.email%TYPE;
v_price ROOM.price%TYPE;
v_number ROOM.nmbr%TYPE;
----Procedura PAY_ROOM porovnava zaplacene rezervace z cenou pokoje 
--- pokud zaplaceno < ceny pokoje, 
---- vypise se email a text, ze suma nestaci

CURSOR c1 IS select  cust.name,cust.email,reserv.id_reservation,sum(pay.amount)as sum_pay from RESERVATION reserv,PAYMENT pay,customer cust 
where reserv.user_id = pay.user_id and reserv.ID_RESERVATION = pay.ID_RESERVATION and  cust.id=reserv.user_id 
group by cust.name,cust.email,reserv.id_reservation order by 1;

CURSOR r1 is select nmbr,price from room where availableness='available';

begin
OPEN c1;
LOOP
  EXIT WHEN c1%NOTFOUND;
  FETCH c1 INTO v_name,v_email,v_idres, v_pay;
  EXIT WHEN c1%NOTFOUND;
   OPEN r1;
   LOOP
   EXIT WHEN r1%NOTFOUND;
   FETCH r1 INTO v_number,v_price ;
   EXIT WHEN r1%NOTFOUND;
   if v_pay < v_price then 
        dbms_output.put_line(v_email||' Payment is not sufficient. Was paid = '||v_pay);
       EXIT; 
    end if;
  END LOOP; 
  CLOSE r1;
END LOOP;
CLOSE c1;
 END;    
 /
 
 ----------------------------TRIGGER----------------------------
 --adds 'complete' status in the STATE column of the RESERVATION table
CREATE OR REPLACE TRIGGER TRIG_RESERV
AFTER INSERT ON accomodation
FOR EACH ROW
BEGIN
UPDATE reservation state1
   SET state1.STATE = 'complete'
   WHERE  state1.id_reservation = :NEW.reservation_id;
   END;

  ----------------------------FILLING DATABASE TABLES----------------------------

  --CUSTOMER
  INSERT INTO customer (name, birthdate, phone_number, address, email)
  VALUES (
    'Yaqub Turner',
    TO_DATE('1993-03-21', 'yyyy/mm/dd'),
    '4201111111', 'Bauerova 4, Brno',
    'turner@gmail.com'
  );

  INSERT INTO customer (name, birthdate, phone_number, address, email)
  VALUES (
    'Dan Pokorny',
    TO_DATE('1996-12-11', 'yyyy/mm/dd'),
    '4201111112', 'Technicka 6, Brno',
    'pokr@gmail.com'
  );

  INSERT INTO customer (name, birthdate, phone_number, address, email)
  VALUES (
   'Shana Snider',
    TO_DATE('1981-05-29', 'yyyy/mm/dd'),
    '4201111113', 'Beethovenova 44, Brno',
    'snider@gmail.com'
  );

  --RECEPTIONIST
  INSERT INTO receptionist (name, birthdate , phone_number, address, email)
  VALUES (
    'Adrienne Merritt',
    TO_DATE('1993-07-29', 'yyyy/mm/dd'), 
    '4201111114', 'Brandlova 55, Brno',
    'errit@gmail.com'
  );

  --RESEVATION
  INSERT INTO reservation (user_id, id_receptionist, check_in, check_out, number_of_people, number_of_rooms, serv_req, state)
  VALUES (
    1,
    1,
    TO_DATE('2021/04/01', 'yyyy/mm/dd'),
    TO_DATE('2021/04/10', 'yyyy/mm/dd'),
    2,
    1,
    'must contain at least three chairs',
    'canceled'
  );

  INSERT INTO reservation (user_id, id_receptionist, check_in, check_out, number_of_people, number_of_rooms, serv_req, state)
  VALUES (
    2,
    1,
    TO_DATE('2022/04/01', 'yyyy/mm/dd'),
    TO_DATE('2022/04/10', 'yyyy/mm/dd'),
    4,
    2,
    'null', 
    'paid'
  );

  --PAYMENT
  INSERT INTO payment (user_id, id_reservation, amount, type)
  VALUES (
    1,
    1,
    500, 
    'card'
  );

  INSERT INTO payment (user_id, id_reservation, amount, type)
  VALUES (
    2,
    2,
    1000,
    'cash'
  );

  --ROOM
  INSERT INTO room (nmbr, availableness, type, price, number_of_beds)
  VALUES (
    4,
    'available',
    '1 beds',
    350,
    1
  );

  INSERT INTO room (nmbr, availableness, type, price, number_of_beds)
  VALUES (
    5,
    'available',
    '2 bed',
    700,
    2
  );

  --ACCOMDATION
  INSERT INTO accomodation (reservation_id, number_room, check_in, check_out, number_of_people, number_of_rooms, state)
  VALUES (
    1,
    4,
    TO_DATE('2021/04/01', 'yyyy/mm/dd'),
    TO_DATE('2021/04/10', 'yyyy/mm/dd'),
    2,
    1,
    'ended'
  );

  INSERT INTO accomodation (reservation_id, number_room, check_in, check_out, number_of_people, number_of_rooms, state)
  VALUES (
    2,
    5,
    TO_DATE('2022-04-01', 'yyyy/mm/dd'),
    TO_DATE('2022-04-10', 'yyyy/mm/dd'),
    3,
    2,
    'current'
  );
exec PAY_ROOM;

  --Select customers who have not made a reservation 
  SELECT * FROM customer cstmr
  LEFT JOIN reservation rsvtn ON cstmr.ID=rsvtn.user_id 
  WHERE rsvtn.user_id is NULL;

  --Reservation status
  SELECT rsvtn.id_reservation, pay.payment_id, pay.amount 
  FROM payment pay
  RIGHT JOIN reservation rsvtn ON pay.ID_reservation = rsvtn.id_reservation 
  ORDER BY 1;
 
  --Which customers worked with which recipients
  SELECT DISTINCT  cstmr.name as customer_name,rsp.name as reseptionist_name
  FROM customer cstmr
  INNER JOIN  reservation rsvtn 
    ON cstmr.id = rsvtn.user_id 
  INNER JOIN receptionist rsp 
    ON rsp.id =rsvtn.id_receptionist ;
    
  --How many reservations did each of the recipients serve:
  SELECT rsp.id,rsp.name, count(rsvtn.id_receptionist) as count_res 
  FROM reservation rsvtn 
  RIGHT JOIN receptionist rsp ON rsp.id = rsvtn.id_receptionist 
  GROUP BY rsp.id,rsp.name;

  --How much each customer paid
  SELECT cust.id,cust.name, reserv.id_reservation, sum(pay.amount) as sum_pay 
  FROM RESERVATION reserv
  LEFT JOIN PAYMENT pay ON reserv.user_id = pay.user_id and reserv.ID_RESERVATION = pay.ID_RESERVATION
  JOIN customer cust ON cust.id=reserv.user_id
  GROUP BY cust.id,cust.name,reserv.id_reservation
  ORDER BY 1;
   
  --Which rooms are '2 bed'
  SELECT accomodation_id,number_room FROM accomodation WHERE number_room in (SELECT nmbr FROM room WHERE type='2 bed');

--explain plan
EXPLAIN PLAN FOR 
SELECT DISTINCT cu.name AS customer_name, rsp.name AS reseptionist_name
FROM customer cu
INNER JOIN reservation rsv ON cu.id = rsv.user_id 
INNER JOIN receptionist rsp ON rsp.id =rsv.id_receptionist ;
SELECT * FROM TABLE(dbms_xplan.display);
  
EXPLAIN PLAN FOR 
SELECT * FROM TABLE(dbms_xplan.display);

CREATE INDEX index_paym ON payment(user_id,payment_id,id_reservation);
CREATE INDEX index_reserv ON reservation (user_id,id_reservation);

--- select n i?eiaiaieai iaiiai eiaaena eiaaenia
---Iauay noieiinou cai?ina COST=7 (auaiaa)
---n eniieuciaaieai eiaaenia COST=2 :
---INDEX RANGE SCAN  |INDEX_PAYM

 explain plan for
select cust.id,cust.name,reserv.id_reservation,sum(pay.amount)as sum_pay from RESERVATION reserv
left join PAYMENT pay on reserv.user_id = pay.user_id and reserv.ID_RESERVATION = pay.ID_RESERVATION
join  customer cust on  cust.id=reserv.user_id and pay.user_id=2
group by cust.id,cust.name,reserv.id_reservation order by 1;
 select * from table(dbms_xplan.display);


  
delete from reservation where user_id=1;
delete from customer where id=2;
  commit;
spool off;  

