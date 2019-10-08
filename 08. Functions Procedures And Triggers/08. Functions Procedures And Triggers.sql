--Problem 1. Employees with Salary Above 35000
CREATE PROCEDURE usp_GetEmployeesSalaryAbove35000 
AS
SELECT FirstName, LastName FROM Employees
WHERE Salary > 35000

EXEC usp_GetEmployeesSalaryAbove35000

GO

--Problem 2. Employees with Salary Above Number
CREATE PROCEDURE usp_GetEmployeesSalaryAboveNumber(@number DECIMAL(15,2)) AS
SELECT FirstName, LastName FROM Employees
WHERE Salary >= @number

EXEC usp_GetEmployeesSalaryAboveNumber 35000.35

GO

--Problem 3. Town Names Starting With
CREATE PROCEDURE usp_GetTownsStartingWith(@myString VARCHAR(50)) AS
SELECT [Name] FROM Towns
WHERE [Name] LIKE @myString + '%'

EXEC usp_GetTownsStartingWith b

GO

--Problem 4. Employees from Town
CREATE PROCEDURE usp_GetEmployeesFromTown(@townName VARCHAR(30)) AS
SELECT e.FirstName, e.LastName FROM Employees As e
JOIN Addresses As a ON a.AddressID = e.AddressID
JOIN Towns As t ON t.TownID = a.TownID
WHERE t.Name = @townName

EXEC usp_GetEmployeesFromTown Sofia

GO

--Problem 5. Salary Level Function
CREATE FUNCTION ufn_GetSalaryLevel(@salary DECIMAL(18,4))
RETURNS VARCHAR(10) AS

BEGIN
	DECLARE @text VARCHAR(10)

	SET @text =

		CASE
			WHEN @salary < 30000 THEN 'Low'
			WHEN @salary BETWEEN 30000 AND 50000 THEN 'Average'
			WHEN @salary > 50000 THEN 'High'
		END

	RETURN @text
END

GO

SELECT Salary, dbo.ufn_GetSalaryLevel(Salary) AS [Salary Level] FROM Employees

GO

--Problem 6. Employees by Salary Level
CREATE PROCEDURE usp_EmployeesBySalaryLevel(@text VARCHAR(10)) AS
SELECT FirstName, Lastname FROM Employees
WHERE dbo.ufn_GetSalaryLevel(Salary) = @text

EXEC usp_EmployeesBySalaryLevel 'High'

GO

--Problem 7. Define Function
CREATE FUNCTION ufn_IsWordComprised(@setOfLetters VARCHAR(20), @word VARCHAR(20))
RETURNS BIT AS

BEGIN
	DECLARE @WordLength INT = LEN(@word)
	DECLARE @Index INT = 1

	WHILE (@Index <= @WordLength)
	BEGIN
		IF (CHARINDEX(SUBSTRING(@word, @Index, 1), @setOfLetters) = 0)
		BEGIN
			RETURN 0
		END

		SET @Index += 1
	END

	RETURN 1
END

GO

SELECT dbo.ufn_IsWordComprised('oistmiahf', 'Sofia')
SELECT dbo.ufn_IsWordComprised('oistmiahf', 'halves')
SELECT dbo.ufn_IsWordComprised('bobr', 'Rob')
SELECT dbo.ufn_IsWordComprised('pppp', 'Guy')

GO

--Problem 8. * Delete Employees and Departments
CREATE PROC usp_DeleteEmployeesFromDepartment (@departmentId INT) AS
ALTER TABLE Employees
DROP CONSTRAINT FK_Employees_Employees

ALTER TABLE EmployeesProjects
DROP CONSTRAINT FK_EmployeesProjects_Employees

ALTER TABLE EmployeesProjects
ADD CONSTRAINT FK_EmployeesProjects_Employees FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE CASCADE

ALTER TABLE Departments
DROP CONSTRAINT FK_Departments_Employees

ALTER TABLE Departments
ALTER COLUMN ManagerID INT NULL

UPDATE Departments
SET ManagerID = NULL
WHERE DepartmentID = @departmentId

UPDATE Employees
SET ManagerID = NULL
WHERE DepartmentID = @departmentId

DELETE FROM Employees
WHERE DepartmentID = @departmentId AND ManagerID IS NULL

DELETE FROM Departments
WHERE DepartmentID = @departmentId

IF OBJECT_ID('[Employees].[FK_Employees_Employees]') IS NULL
    ALTER TABLE [Employees] WITH NOCHECK
        ADD CONSTRAINT [FK_Employees_Employees] FOREIGN KEY ([ManagerID]) REFERENCES [Employees]([EmployeeID]) ON DELETE NO ACTION ON UPDATE NO ACTION

IF OBJECT_ID('[Departments].[FK_Departments_Employees]') IS NULL
    ALTER TABLE [Departments] WITH NOCHECK
        ADD CONSTRAINT [FK_Departments_Employees] FOREIGN KEY ([ManagerID]) REFERENCES [Employees]([EmployeeID]) ON DELETE NO ACTION ON UPDATE NO ACTION

SELECT COUNT(*) FROM Employees
WHERE DepartmentID = @departmentId

EXEC usp_DeleteEmployeesFromDepartment 4
GO

--Problem 9. Find Full Name
CREATE PROCEDURE usp_GetHoldersFullName AS
SELECT FirstName + ' ' + LastName As [Full Name] FROM AccountHolders

EXEC usp_GetHoldersFullName
GO

--Problem 10. People with Balance Higher Than
CREATE PROCEDURE usp_GetHoldersWithBalanceHigherThan(@total DECIMAL(15,2)) AS
WITH CTE_AcountHolderBalance(AccountHolderId, Balance) As
(SELECT AccountHolderId, SUM(Balance) As TotalBalance FROM Accounts
GROUP BY AccountHolderId)

SELECT FirstName, LastName FROM AccountHolders As ah
JOIN CTE_AcountHolderBalance As cab ON cab.AccountHolderId = ah.Id
WHERE CAB.Balance > @total
ORDER BY FirstName, LastName

EXEC usp_GetHoldersWithBalanceHigherThan 20000
GO

--Problem 11. Future Value Function
CREATE FUNCTION ufn_CalculateFutureValue(@sum DECIMAL(15,2), @yearlyInterestRate FLOAT, @years INT)
RETURNS DECIMAL(20,4) AS

BEGIN
	DECLARE @futureValue DECIMAL(20,4) =@sum * POWER(1 + @yearlyInterestRate, @years)
	RETURN @futureValue
END

GO 

SELECT dbo.ufn_CalculateFutureValue(1000, 0.1, 5)

GO

--Problem 12. Calculating Interest
CREATE PROCEDURE usp_CalculateFutureValueForAccount(@AccountId INT, @interestRate FLOAT) AS
SELECT a.AccountHolderId, ah.FirstName, ah.LastName, a.Balance,
dbo.ufn_CalculateFutureValue(a.Balance, @interestRate, 5)
FROM AccountHolders As ah
JOIN Accounts As a ON a.AccountHolderId = ah.Id AND a.Id = @AccountId

EXEC usp_CalculateFutureValueForAccount 1, 0.1

GO

--Problem 13. *Scalar Function: Cash in User Games Odd Rows
CREATE FUNCTION ufn_CashInUsersGames(@gameName VARCHAR(MAX))
RETURNS TABLE AS
RETURN	SELECT SUM(Cash) AS SumCash FROM
	(
		SELECT ug.Cash, ROW_NUMBER() OVER(ORDER BY Cash DESC) AS RowNum FROM UsersGames AS ug
		JOIN Games AS g
		ON g.Id = ug.GameId
		WHERE g.Name = @gameName
	) AS AllGameRows
	WHERE RowNum % 2 = 1
GO

SELECT * FROM dbo.ufn_CashInUsersGames('Lily Stargazer')

--Problem 14. Create Table Logs

CREATE TABLE Logs
(
	LogID INT PRIMARY KEY IDENTITY,
	AccountID INT FOREIGN KEY REFERENCES Accounts(Id),
	OldSum MONEY NOT NULL,
	NewSum MONEY NOT NULL
)

GO

CREATE TRIGGER tr_AccountsUpdate ON Accounts FOR UPDATE
AS
  INSERT INTO Logs
  SELECT inserted.Id, deleted.Balance, inserted.Balance FROM inserted
  JOIN deleted
  ON inserted.Id = deleted.Id

UPDATE Accounts
SET Balance -= 10
WHERE Id = 1

SELECT * FROM Logs

--Problem 15. Create Table Emails
CREATE TABLE NotificationEmails
(
	Id INT PRIMARY KEY IDENTITY,
	Recipient INT FOREIGN KEY REFERENCES Accounts(Id),
	Subject VARCHAR(100),
	Body VARCHAR(200)
)
GO

CREATE TRIGGER tr_LogsInsert ON Logs FOR INSERT
AS
	INSERT INTO NotificationEmails
	SELECT AccountId,  
		'Balance change for account: ' + CAST(AccountID AS varchar(20)),
		'On ' + CONVERT(VARCHAR(50), GETDATE(), 100) + ' your balance was changed from ' + 
		CAST(OldSum AS varchar(20)) + ' to ' + CAST(NewSum AS varchar(20))
		FROM inserted

UPDATE Accounts
SET Balance -= 10
WHERE Id = 1

SELECT * FROM NotificationEmails
GO

--Problem 16. Deposit Money
CREATE PROC usp_DepositMoney (@AccountId INT, @MoneyAmount MONEY) AS
BEGIN
	BEGIN TRAN
		IF (@MoneyAmount > 0)
		BEGIN
			UPDATE Accounts
			SET Balance += @MoneyAmount
			WHERE Id = @AccountId

			IF @@ROWCOUNT != 1
			BEGIN
				ROLLBACK
				RAISERROR('Invalid account!', 16, 1)
				RETURN
			END
		END
	COMMIT
END 

EXEC usp_DepositMoney 1, 10
SELECT * FROM Accounts
GO

--Problem 17. Withdraw Money
CREATE PROC usp_WithdrawMoney (@AccountId INT, @MoneyAmount MONEY) AS
BEGIN
	BEGIN TRAN
		IF (@MoneyAmount > 0)
		BEGIN
			UPDATE Accounts
			SET Balance -= @MoneyAmount
			WHERE Id = @AccountId

			IF @@ROWCOUNT != 1
			BEGIN
				ROLLBACK
				RAISERROR('Invalid account!', 16, 1)
				RETURN
			END
		END
	COMMIT
END

EXEC usp_WithdrawMoney 5, 25
SELECT * FROM Accounts
GO

--Problem 18. Money Transfer
CREATE PROC usp_TransferMoney(@SenderId INT, @ReceiverId INT, @Amount money) AS
BEGIN 
	BEGIN TRAN
		IF(@Amount > 0)
		BEGIN
			EXEC usp_WithdrawMoney @SenderId, @Amount
			EXEC usp_DepositMoney @ReceiverId, @Amount
		END
	COMMIT
END

EXEC usp_TransferMoney 5, 1, 5000

SELECT * FROM Accounts
GO

--Problem 19. Trigger
USE Diablo
GO

CREATE TRIGGER tr_UserGameItems ON UserGameItems INSTEAD OF INSERT AS
BEGIN 
	INSERT INTO UserGameItems
	SELECT i.Id, ug.Id FROM inserted
	JOIN UsersGames AS ug
	ON UserGameId = ug.Id
	JOIN Items AS i
	ON ItemId = i.Id
	WHERE ug.Level >= i.MinLevel
END
GO

UPDATE UsersGames
SET Cash += 50000
FROM UsersGames AS ug
JOIN Users AS u
ON ug.UserId = u.Id
JOIN Games AS g
ON ug.GameId = g.Id
WHERE g.Name = 'Bali' AND u.Username IN('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos')
GO

CREATE PROC usp_BuyItems(@Username VARCHAR(100)) AS
BEGIN
	DECLARE @UserId INT = (SELECT Id FROM Users WHERE Username = @Username)
	DECLARE @GameId INT = (SELECT Id FROM Games WHERE Name = 'Bali')
	DECLARE @UserGameId INT = (SELECT Id FROM UsersGames WHERE UserId = @UserId AND GameId = @GameId)
	DECLARE @UserGameLevel INT = (SELECT Level FROM UsersGames WHERE Id = @UserGameId)

	DECLARE @counter INT = 251

	WHILE(@counter <= 539)
	BEGIN
		DECLARE @ItemId INT = @counter
		DECLARE @ItemPrice MONEY = (SELECT Price FROM Items WHERE Id = @ItemId)
		DECLARE @ItemLevel INT = (SELECT MinLevel FROM Items WHERE Id = @ItemId)
		DECLARE @UserGameCash MONEY = (SELECT Cash FROM UsersGames WHERE Id = @UserGameId)

		IF(@UserGameCash >= @ItemPrice AND @UserGameLevel >= @ItemLevel)
		BEGIN
			UPDATE UsersGames
			SET Cash -= @ItemPrice
			WHERE Id = @UserGameId

			INSERT INTO UserGameItems VALUES
			(@ItemId, @UserGameId)
		END

		SET @counter += 1
		
		IF(@counter = 300)
		BEGIN
			SET @counter = 501
		END
	END
END

EXEC usp_BuyItems 'baleremuda'
EXEC usp_BuyItems 'loosenoise'
EXEC usp_BuyItems 'inguinalself'
EXEC usp_BuyItems 'buildingdeltoid'
EXEC usp_BuyItems 'monoxidecos'
GO

SELECT * FROM Users AS u
JOIN UsersGames AS ug
ON u.Id = ug.UserId
JOIN Games AS g
ON ug.GameId = g.Id
JOIN UserGameItems AS ugi
ON ug.Id = ugi.UserGameId
JOIN Items AS i
ON ugi.ItemId = i.Id
WHERE g.Name = 'Bali'
ORDER BY u.Username, i.Name
GOC

--20. *Massive Shopping 
DECLARE @UserId INT = (SELECT Id FROM Users WHERE Username = 'Stamat')
DECLARE @GameId INT = (SELECT Id FROM Games WHERE Name = 'Safflower')
DECLARE @UserGameId INT = (SELECT Id FROM UsersGames WHERE UserId = @UserId AND GameId = @GameId)
DECLARE @UserGameLevel INT = (SELECT Level FROM UsersGames WHERE Id = @UserGameId)
DECLARE @ItemStartLevel INT = 11
DECLARE @ItemEndLevel INT = 12
DECLARE @AllItemsPrice MONEY = (SELECT SUM(Price) FROM Items WHERE (MinLevel BETWEEN @ItemStartLevel AND @ItemEndLevel)) 
DECLARE @StamatCash MONEY = (SELECT Cash FROM UsersGames WHERE Id = @UserGameId)

IF(@StamatCash >= @AllItemsPrice)
BEGIN
	BEGIN TRAN	
		UPDATE UsersGames
		SET Cash -= @AllItemsPrice
		WHERE Id = @UserGameId
	
		INSERT INTO UserGameItems
		SELECT i.Id, @UserGameId  FROM Items AS i
		WHERE (i.MinLevel BETWEEN @ItemStartLevel AND @ItemEndLevel)
	COMMIT
END

SET @ItemStartLevel = 19
SET @ItemEndLevel = 21
SET @AllItemsPrice = (SELECT SUM(Price) FROM Items WHERE (MinLevel BETWEEN @ItemStartLevel AND @ItemEndLevel)) 
SET @StamatCash = (SELECT Cash FROM UsersGames WHERE Id = @UserGameId)

IF(@StamatCash >= @AllItemsPrice)
BEGIN
	BEGIN TRAN
		UPDATE UsersGames
		SET Cash -= @AllItemsPrice
		WHERE Id = @UserGameId
	
		INSERT INTO UserGameItems
		SELECT i.Id, @UserGameId  FROM Items AS i
		WHERE (i.MinLevel BETWEEN @ItemStartLevel AND @ItemEndLevel)
	COMMIT
END

SELECT i.Name AS [Item Name] FROM Users AS u
JOIN UsersGames AS ug
ON u.Id = ug.UserId
JOIN Games AS g
ON ug.GameId = g.Id
JOIN UserGameItems AS ugi
ON ug.Id = ugi.UserGameId
JOIN Items AS i
ON ugi.ItemId = i.Id
WHERE u.Username = 'Stamat' AND g.Name = 'Safflower'
ORDER BY i.Name

--21. Employees with Three Projects
USE SoftUni
GO

CREATE PROC usp_AssignProject(@employeeId INT, @projectID INT) AS
BEGIN
	BEGIN TRAN
		INSERT INTO EmployeesProjects VALUES
		(@employeeId, @projectID)
		DECLARE @EmployeeProjectsCount INT = (SELECT COUNT(*) FROM EmployeesProjects WHERE EmployeeId = @employeeId)
		IF(@EmployeeProjectsCount > 3)
		BEGIN
			ROLLBACK
			RAISERROR('The employee has too many projects!', 16, 1)
			RETURN
		END
	COMMIT
END 

--Problem 22. Delete Employees
CREATE TABLE Deleted_Employees
(
	EmployeeId INT PRIMARY KEY IDENTITY,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	MiddleName VARCHAR(50),
	JobTitle VARCHAR(50) NOT NULL,
	DepartmentID INT NOT NULL,
	Salary MONEY NOT NULL
)
GO

CREATE TRIGGER tr_DeleteEmployees ON Employees AFTER DELETE AS
	INSERT INTO Deleted_Employees
	SELECT FirstName, LastName, MiddleName, JobTitle, DepartmentID, Salary FROM deleted