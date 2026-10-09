-- RUN THIS ONCE IN MYSQL WORKBENCH (it recreates the 4 tables to match your entities)
CREATE DATABASE IF NOT EXISTS trainreservation;
USE trainreservation;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS passengers;
DROP TABLE IF EXISTS trains;
SET FOREIGN_KEY_CHECKS = 1;

DROP FUNCTION IF EXISTS calculate_fare;
DROP PROCEDURE IF EXISTS reserve_ticket;
DROP TRIGGER IF EXISTS trg_update_available_seats;

CREATE TABLE trains (
  train_id        INT AUTO_INCREMENT PRIMARY KEY,
  train_name      VARCHAR(100) NOT NULL,
  train_number    VARCHAR(20)  NOT NULL,
  total_seats     INT NOT NULL,
  available_seats INT NOT NULL
);

CREATE TABLE passengers (
  passenger_id   INT AUTO_INCREMENT PRIMARY KEY,
  passenger_name VARCHAR(100) NOT NULL,
  age            INT,
  gender         VARCHAR(10),
  phone          VARCHAR(20)
);

CREATE TABLE routes (
  route_id    INT AUTO_INCREMENT PRIMARY KEY,
  train_id    INT NOT NULL,
  source      VARCHAR(100) NOT NULL,
  destination VARCHAR(100) NOT NULL,
  distance_km DOUBLE NOT NULL,
  FOREIGN KEY (train_id) REFERENCES trains(train_id)
);

CREATE TABLE reservations (
  reservation_id   INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id     INT NOT NULL,
  train_id         INT NOT NULL,
  route_id         INT NOT NULL,
  reservation_date DATE NOT NULL,
  seats_booked     INT NOT NULL,
  fare             DOUBLE NOT NULL,
  FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
  FOREIGN KEY (train_id)     REFERENCES trains(train_id),
  FOREIGN KEY (route_id)     REFERENCES routes(route_id)
);

DELIMITER $$

-- FUNCTION: ticket fare = distance x Rs.1.50 per km x seats
CREATE FUNCTION calculate_fare(p_distance DOUBLE, p_seats INT)
RETURNS DOUBLE
DETERMINISTIC
BEGIN
  RETURN ROUND(p_distance * 1.5 * p_seats, 2);
END$$

-- PROCEDURE: validate, calculate fare, insert reservation
CREATE PROCEDURE reserve_ticket(IN p_passenger_id INT, IN p_train_id INT,
                                IN p_route_id INT, IN p_seats INT)
BEGIN
  DECLARE v_available INT DEFAULT NULL;
  DECLARE v_distance  DOUBLE DEFAULT NULL;
  DECLARE v_route_train INT DEFAULT NULL;

  SELECT available_seats INTO v_available FROM trains WHERE train_id = p_train_id FOR UPDATE;
  SELECT distance_km, train_id INTO v_distance, v_route_train FROM routes WHERE route_id = p_route_id;

  IF p_seats IS NULL OR p_seats < 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Please book at least 1 seat';
  ELSEIF NOT EXISTS (SELECT 1 FROM passengers WHERE passenger_id = p_passenger_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Passenger not found';
  ELSEIF v_available IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Train not found';
  ELSEIF v_route_train IS NULL OR v_route_train <> p_train_id THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This route does not belong to the selected train';
  ELSEIF v_available < p_seats THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough seats available on this train';
  ELSE
    INSERT INTO reservations (passenger_id, train_id, route_id, reservation_date, seats_booked, fare)
    VALUES (p_passenger_id, p_train_id, p_route_id, CURDATE(), p_seats,
            calculate_fare(v_distance, p_seats));
  END IF;
END$$

-- TRIGGER: reduce available seats after each reservation
CREATE TRIGGER trg_update_available_seats
AFTER INSERT ON reservations
FOR EACH ROW
BEGIN
  UPDATE trains
  SET available_seats = available_seats - NEW.seats_booked
  WHERE train_id = NEW.train_id;
END$$

DELIMITER ;

-- Sample data
INSERT INTO trains (train_name, train_number, total_seats, available_seats) VALUES
 ('Pandian Express',  '12637', 120, 120),
 ('Vaigai Express',   '12635', 100, 100),
 ('Nellai Express',   '12631',  90,  90),
 ('Kanyakumari Exp',  '12633',  80,  80);

INSERT INTO passengers (passenger_name, age, gender, phone) VALUES
 ('Arun Kumar', 28, 'Male',   '9876543210'),
 ('Priya S',    24, 'Female', '9123456780'),
 ('Karthik R',  35, 'Male',   '9988776655');

INSERT INTO routes (train_id, source, destination, distance_km) VALUES
 (1, 'Chennai', 'Madurai',      497),
 (2, 'Chennai', 'Madurai',      497),
 (3, 'Chennai', 'Tirunelveli',  650),
 (4, 'Chennai', 'Kanyakumari',  720);
