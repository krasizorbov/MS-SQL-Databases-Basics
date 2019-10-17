--Section 1. DDL (30 pts)
CREATE TABLE Planes
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(30) NOT NULL,
	Seats INT NOT NULL,
	[Range] INT NOT NULL
)

CREATE TABLE Flights
(
	Id INT PRIMARY KEY IDENTITY,
	DepartureTime DATETIME,
	ArrivalTime DATETIME,
	Origin VARCHAR(50) NOT NULL,
	Destination VARCHAR(50) NOT NULL,
	PlaneId INT FOREIGN KEY REFERENCES Planes(Id) NOT NULL
)

CREATE TABLE Passengers
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(30) NOT NULL,
	LastName VARCHAR(30) NOT NULL,
	Age INT NOT NULL,
	[Address] VARCHAR(30) NOT NULL, 
	PassportId CHAR(11) NOT NULL
)

CREATE TABLE LuggageTypes
(
	Id INT PRIMARY KEY IDENTITY,
	[Type] VARCHAR(30)
)

CREATE TABLE Luggages
(
	Id INT PRIMARY KEY IDENTITY,
	LuggageTypeId INT FOREIGN KEY REFERENCES LuggageTypes(Id) NOT NULL,
	PassengerId INT FOREIGN KEY REFERENCES Passengers(Id) NOT NULL
)

CREATE TABLE Tickets
(
	Id INT PRIMARY KEY IDENTITY,
	PassengerId INT FOREIGN KEY REFERENCES Passengers(Id) NOT NULL,
	FlightId INT FOREIGN KEY REFERENCES Flights(Id) NOT NULL,
	LuggageId INT FOREIGN KEY REFERENCES Luggages(Id) NOT NULL,
	Price DECIMAL(15,2) NOT NULL
)

--Section 2. DML (10 pts)
INSERT INTO Planes VALUES
('Airbus 336', 112, 5132),
('Airbus 330', 432, 5325),
('Boeing 369', 231, 2355),
('Stelt 297', 254, 2143),
('Boeing 338', 165, 5111),
('Airbus 558', 387, 1342),
('Boeing 128', 345, 5541)

INSERT INTO LuggageTypes VALUES
('Crossbody Bag'),
('School Backpack'),
('Shoulder Bag')

--3.	Update
UPDATE Tickets
SET Price = Price * 1.13
WHERE FlightId = (SELECT TOP(1) Id FROM Flights WHERE Destination = 'Carlsbad')

--4.	Delete
DELETE FROM Tickets
WHERE FlightId = (SELECT TOP(1) Id FROM Flights WHERE Destination = 'Ayn Halagim')

DELETE FROM Flights
WHERE Destination = 'Ayn Halagim'

--5.	Trips
SELECT Origin, Destination FROM Flights
ORDER BY Origin, Destination

--6.	The "Tr" Planes
SELECT Id, [Name], Seats, [Range] FROM Planes
WHERE [Name] LIKE '%tr%'
ORDER BY Id, [Name], Seats, [Range]

--7.	Flight Profits
SELECT FlightId, SUM(Price) FROM Tickets
GROUP BY FlightId
ORDER BY SUM(Price) DESC, FlightID 

--8.	Passengers and Prices
SELECT TOP(10) p.FirstName, p.LastName, t.Price FROM Passengers As p
JOIN Tickets As t ON t.PassengerId = p.Id
ORDER BY t.Price DESC, p.FirstName, p.LastName

--9.	Most Used Luggage's
SELECT lt.[Type], COUNT(l.LuggageTypeId) As MostUsedLuggage FROM LuggageTypes As lt
JOIN Luggages As l ON l.LuggageTypeId = lt.Id
GROUP BY lt.[Type]
ORDER BY MostUsedLuggage DESC, lt.[Type]

--10.	Passenger Trips
SELECT p.FirstName + ' ' + p.LastName As [Full Name],
f.Origin, f.Destination
FROM Passengers As p
JOIN Tickets As t ON t.PassengerId = p.Id
JOIN Flights As f ON f.Id = t.FlightId
ORDER BY [Full Name], Origin, Destination

--11.	Non Adventures People
SELECT p.FirstName, p.LastName, p.Age FROM Passengers As p
LEFT JOIN Tickets As t ON t.PassengerId = p.Id
WHERE t.Price IS NULL
ORDER BY p.Age DESC, p.FirstName, p.LastName

--12.	Lost Luggage's
SELECT p.PassportId, p.[Address] FROM Passengers As p
LEFT JOIN Luggages As l ON l.PassengerId = p.Id
WHERE l.LuggageTypeId IS NULL
ORDER BY p.PassportId, p.[Address]

--13.	Count of Trips
SELECT p.FirstName, p.LastName, COUNT(t.PassengerId) As [Total Trips] FROM Passengers As p
LEFT JOIN Tickets As t ON t.PassengerId = p.Id
GROUP BY p.FirstName, p.LastName
ORDER BY [Total Trips] DESC, p.FirstName, p.LastName

--14.	Full Info
SELECT p.FirstName + ' ' + p.LastName  As [Full Name], pl.[Name] As [Plane Name],
f.Origin + ' - ' + f.Destination As Trip, lt.[Type] As [Luggage Type]
FROM Passengers As p
JOIN Tickets As t ON t.PassengerId = p.Id
JOIN Flights As f ON f.Id = t.FlightId
JOIN Planes As pl ON pl.Id = f.PlaneId
JOIN Luggages As l ON l.Id = t.LuggageId
JOIN LuggageTypes As lt ON lt.Id = l.LuggageTypeId
ORDER BY [Full Name], [Name], Origin, Destination, [Type]

--15.	Most Expensive Trips
SELECT k.FirstName, k.LastName, k.Destination, k.Price As Price
FROM (
SELECT p.FirstName, p.LastName, f.Destination, t.Price,
DENSE_RANK() OVER(PARTITION BY p.FirstName, p.LastName ORDER BY t.Price DESC) As PriceRank
FROM Passengers As p
JOIN Tickets As t ON t.PassengerId = p.Id
JOIN Flights As f ON f.Id = t.FlightId) As k
WHERE k.PriceRank = 1
ORDER BY Price DESC, k.FirstName, k.LastName, k.Destination

--16.	Destinations Info
SELECT f.Destination, COUNT(t.Id) As [Count] FROM Flights As f
LEFT JOIN Tickets As t ON t.FlightId = f.Id
GROUP BY f.Destination
ORDER BY [Count] DESC, f.Destination

--17.	 PSP
SELECT p.Name, p.Seats, COUNT(t.Id) As PassengersCount FROM Planes As p
LEFT JOIN Flights As f ON f.PlaneId = p.Id
LEFT JOIN Tickets As t ON t.FlightId = f.Id
GROUP BY p.Name, p.Seats
ORDER BY PassengersCount DESC, p.Name, p.Seats

GO

--18.	Vacation
CREATE FUNCTION udf_CalculateTickets(@origin VARCHAR(50), @destination VARCHAR(50), @peopleCount INT)
RETURNS VARCHAR(100) As

BEGIN

IF (@peopleCount <= 0)
BEGIN
	RETURN 'Invalid people count!'
END

DECLARE @tripId INT = 
(SELECT f.Id FROM Flights As f
JOIN Tickets As t ON t.FlightId = f.Id
WHERE Origin = @origin AND Destination = @destination)

IF @tripId IS NULL
BEGIN
	RETURN 'Invalid flight!'
END

DECLARE @ticketPrice DECIMAL(15,2) = 
(SELECT t.Price FROM Flights AS f
JOIN Tickets AS t ON t.FlightId = f.Id 
WHERE Destination = @destination AND Origin = @origin)

DECLARE @totalPrice DECIMAL(15, 2) = @ticketPrice * @peoplecount

RETURN 'Total price ' + CAST(@totalPrice as VARCHAR(30))

END

GO

--19.	Wrong Data
CREATE PROC usp_CancelFlights
AS
UPDATE Flights
SET DepartureTime = NULL, ArrivalTime = NULL
WHERE ArrivalTime > DepartureTime
GO

--20.	 Deleted Planes
CREATE TABLE DeletedPlanes
(
	Id INT,
	Name VARCHAR(30),
	Seats INT,
	Range INT
)

GO

CREATE TRIGGER tr_DeletedPlanes ON Planes 
AFTER DELETE AS
INSERT INTO DeletedPlanes 
(Id, Name, Seats, Range) 
(SELECT Id, Name, Seats, Range FROM deleted)