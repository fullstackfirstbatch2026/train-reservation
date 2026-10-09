# Train Ticket Reservation (RailReserve)

A train ticket reservation web application. Users can manage trains, passengers and routes, and book tickets. All data is stored in MySQL.

## Features
- Add and view **trains**, **passengers** and **routes** from the website
- Book tickets with a live fare preview
- **JOIN**: reservations shown with passenger, train and route details
- **Subquery**: trains with above-average reservations
- **Stored procedure** `reserve_ticket`: validates and books a ticket
- **Function** `calculate_fare`: fare = distance x Rs. 1.50 x seats
- **Trigger** `trg_update_available_seats`: reduces available seats after each booking
- REST API with a HTML/CSS/JavaScript frontend

## Tech stack
| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, JavaScript (fetch API) |
| Backend | Java 21, Spring Boot, Spring Data JPA (Hibernate) |
| Database | MySQL 8 |
| Build | Maven |
| Container | Docker, Docker Compose |

## Project structure
```
src/main/java/com/example/trainreservation
  controller/   REST controllers (Train, Passenger, Route, Reservation)
  entity/       JPA entities mapped to tables
  repository/   Spring Data repositories and custom SQL queries
src/main/resources
  static/       index, trains, routes, passengers, reservation pages, style.css, script.js
  application.properties
database.sql    tables, function, procedure, trigger and sample data
Dockerfile
docker-compose.yml
```

## Database tables
| Table | Columns |
|---|---|
| `trains` | train_id, train_name, train_number, total_seats, available_seats |
| `passengers` | passenger_id, passenger_name, age, gender, phone |
| `routes` | route_id, train_id, source, destination, distance_km |
| `reservations` | reservation_id, passenger_id, train_id, route_id, reservation_date, seats_booked, fare |

## REST API
| Method | URL | Description |
|---|---|---|
| GET | `/api/trains` | List trains |
| POST | `/api/trains` | Add a train |
| GET | `/api/passengers` | List passengers |
| POST | `/api/passengers` | Add a passenger |
| GET | `/api/routes` | List routes |
| POST | `/api/routes` | Add a route |
| POST | `/api/reservations/book?passengerId=&trainId=&routeId=&seats=` | Book a ticket (calls the procedure) |
| GET | `/api/reservations/join` | Reservations with names (JOIN) |
| GET | `/api/reservations/above-average` | Trains above average reservations (subquery) |
| GET | `/api/reservations/fare?distance=&seats=` | Calculate fare (function) |

## Run with Docker (recommended)
Requires Docker Desktop.

```
git clone https://github.com/fullstackfirstbatch2026/train-reservation.git
cd train-reservation
docker compose up --build
```

Open http://localhost:8081/index.html

`database.sql` runs automatically the first time and creates the tables, function, procedure, trigger and sample data.

Stop with `docker compose down` (add `-v` to also delete the database data).

## Run without Docker
1. Install Java 21 and MySQL 8.
2. Run `database.sql` in MySQL (Workbench or the mysql command line).
3. In `src/main/resources/application.properties`, set your MySQL password:
   ```
   spring.datasource.password=YOUR_PASSWORD
   ```
4. Run `TrainreservationApplication` (Eclipse) or `./mvnw spring-boot:run`.
5. Open http://localhost:8081/index.html

## How a booking works
1. The user clicks **Confirm reservation**; `script.js` sends `POST /api/reservations/book`.
2. `ReservationController.bookTicket()` calls the repository, which runs `CALL reserve_ticket(...)`.
3. The procedure checks the seats, passenger, train and route, calculates the fare with `calculate_fare`, and inserts the reservation.
4. The trigger reduces `available_seats` on the train.
5. The page shows the result and refreshes the tables.

## Author
Train Reservation project, Full Stack batch 2026.
