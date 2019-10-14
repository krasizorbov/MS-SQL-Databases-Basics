CREATE DATABASE Bitbucket

USE Bitbucket

--1.Database Design--
CREATE TABLE Users
(
	Id INT PRIMARY KEY IDENTITY,
	Username VARCHAR(30) NOT NULL,
	[Password] VARCHAR(30) NOT NULL,
	Email VARCHAR(50) NOT NULL
)

CREATE TABLE Repositories
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL
)

CREATE TABLE RepositoriesContributors
(
	RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id),
	ContributorId INT FOREIGN KEY REFERENCES Users(Id),
	CONSTRAINT PK_RepositoryId_ContributorId PRIMARY KEY(RepositoryId, ContributorId)
)

CREATE TABLE Issues
(
	Id INT PRIMARY KEY IDENTITY,
	Title VARCHAR(255) NOT NULL,
	IssueStatus CHAR(6) NOT NULL,
	RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id),
	AssigneeId INT FOREIGN KEY REFERENCES Users(Id)
)

CREATE TABLE Commits
(
	Id INT PRIMARY KEY IDENTITY,
	[Message] VARCHAR(255) NOT NULL,
	IssueId INT FOREIGN KEY REFERENCES Issues(Id),
	RepositoryId INT FOREIGN KEY REFERENCES Repositories(Id),
	ContributorId INT FOREIGN KEY REFERENCES Users(Id)
)

CREATE TABLE Files
(
	Id INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(100) NOT NULL,
	Size DECIMAL(15,2) NOT NULL,
	ParentId INT FOREIGN KEY REFERENCES Files(Id),
	CommitId INT FOREIGN KEY REFERENCES Commits(Id)
)

--2.Insert--
INSERT INTO Files VALUES
('Trade.idk',	2598.0,	1,	1),
('menu.net',	9238.31,	2,	2),
('Administrate.soshy',	1246.93,	3,	3),
('Controller.php',	7353.15,	4,	4),
('Find.java',	9957.86,	5,	5),
('Controller.json',	14034.87,	3,	6),
('Operate.xix',	7662.92,	7,	7)

INSERT INTO Issues VALUES
('Critical Problem with HomeController.cs file',	'open',	1,	4),
('Typo fix in Judge.html',	'open',	4,	3),
('Implement documentation for UsersService.cs',	'closed',	8,	2),
('Unreachable code in Index.cs',	'open',	9,	8)

--3.Update--
UPDATE Issues
SET IssueStatus = 'closed' where AssigneeId = 6

--4.Delete--
DELETE FROM Files
WHERE CommitId IN 
(SELECT Id FROM Commits WHERE RepositoryId IN 
(SELECT Id FROM Repositories WHERE Id = RepositoryId AND [Name] = 'Softuni-Teamwork'))

DELETE FROM Commits
WHERE RepositoryId IN (SELECT Id FROM Repositories WHERE Id = RepositoryId AND [Name] = 'Softuni-Teamwork')

DELETE FROM RepositoriesContributors
WHERE RepositoryId IN (SELECT Id FROM Repositories WHERE Id = RepositoryId AND [Name] = 'Softuni-Teamwork')

DELETE FROM Issues
WHERE RepositoryId IN (SELECT Id FROM Repositories WHERE Id = RepositoryId AND [Name] = 'Softuni-Teamwork')

DELETE FROM Repositories
WHERE [Name] = 'Softuni-Teamwork'

--5.Commits--
SELECT c.Id, c.Message, c.RepositoryId, c.ContributorId FROM Commits AS c
ORDER BY c.Id, c.Message, c.RepositoryId, c.ContributorId

--6.Heavy HTML--
SELECT f.Id, f.Name, f.Size FROM Files AS f
WHERE Size > 1000 AND Name LIKE '%html%'
ORDER BY Size DESC, Id, Name

--7.Issues and Users--
SELECT i.Id, u.Username + ' : ' + i.Title AS IssueAssignee FROM Users AS u
JOIN Issues AS i ON i.AssigneeId = u.Id
ORDER BY I.Id DESC, IssueAssignee

--8.Non-Directory Files
WITH CTE_NewTable(Id, Name, Size) As
(
	SELECT f.Id, f.Name, f.Size
	FROM Files As f
	WHERE Id IN (SELECT ParentId FROM Files)
)
SELECT Id, Name, CAST(Size AS VARCHAR(20)) + 'KB' As Size FROM Files
WHERE Id NOT IN (SELECT Id FROM CTE_NewTable)

--9.Most Contributed Repositories--
SELECT TOP(5) r.Id, r.Name, COUNT(c.ContributorId) AS Commits FROM Repositories As r
JOIN RepositoriesContributors As rc ON rc.RepositoryId = r.Id
JOIN Commits As c ON c.RepositoryId = r.Id
GROUP BY r.Id, r.Name
ORDER BY Commits DESC, r.Id, r.Name

--10.User and Files--
SELECT u.Username, AVG(f.Size) As Size FROM Users As u
JOIN Commits As c ON c.ContributorId = u.Id
JOIN Files As f ON f.CommitId = c.Id
GROUP BY u.Username
ORDER BY Size DESC, u.Username
GO

--11.User Total Commits--
CREATE FUNCTION udf_UserTotalCommits(@username VARCHAR(30))
RETURNS INT AS

BEGIN 

	DECLARE @count INT = 
	(SELECT COUNT(c.ContributorId) FROM Commits As c
	JOIN Users As u ON u.Id = c.ContributorId
	WHERE u.Username = @username)
	RETURN @count

END

GO

--12.Find by Extensions--
CREATE PROCEDURE usp_FindByExtension(@extension VARCHAR(5)) AS
SELECT k.Id, k.Name, k.Size FROM(
SELECT Id, Name, CAST(Size AS VARCHAR(20)) + 'KB' AS Size FROM Files
WHERE Name LIKE '%' + @extension + '%') As k
ORDER BY Id, Name, Size DESC




