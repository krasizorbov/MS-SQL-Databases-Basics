--Problem 1. Records’ Count
SELECT COUNT(*) AS [Count] FROM WizzardDeposits

--Problem 2. Longest Magic Wand
SELECT MAX(MagicWandSize) AS LongestMagicWand FROM WizzardDeposits

--Problem 3. Longest Magic Wand per Deposit Groups
SELECT DepositGroup, MAX(MagicWandSize) AS LongestMagicWand 
FROM WizzardDeposits
GROUP BY DepositGroup

--Problem 4. * Smallest Deposit Group per Magic Wand Size
SELECT TOP(2) DepositGroup FROM WizzardDeposits
GROUP BY DepositGroup
ORDER BY AVG(MagicWandSize)

--Problem 5. Deposits Sum
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum 
FROM WizzardDeposits
GROUP BY DepositGroup

--Problem 6. Deposits Sum for Ollivander Family
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum 
FROM WizzardDeposits
WHERE MagicWandCreator = 'Ollivander family'
GROUP BY DepositGroup

--Problem 7. Deposits Filter
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum 
FROM WizzardDeposits
WHERE MagicWandCreator = 'Ollivander family'
GROUP BY DepositGroup
HAVING SUM(DepositAmount) < 150000
ORDER BY TotalSum DESC

--Problem 8. Deposit Charge
SELECT DepositGroup, MagicWandCreator, MIN(DepositCharge) AS MinDepositCharge 
FROM WizzardDeposits
GROUP BY DepositGroup, MagicWandCreator
ORDER BY MagicWandCreator, DepositGroup

--Problem 9. Age Groups
SELECT *, COUNT(*) AS WizardCount FROM
(SELECT
CASE
WHEN Age >= 0 AND Age <= 10 THEN '[0-10]'
WHEN Age >= 11 AND Age <= 20 THEN '[11-20]'
WHEN Age >= 21 AND Age <= 30 THEN '[21-30]'
WHEN Age >= 31 AND Age <= 40 THEN '[31-40]'
WHEN Age >= 41 AND Age <= 50 THEN '[41-50]'
WHEN Age >= 51 AND Age <= 60 THEN '[51-60]'
WHEN Age >= 61 THEN '[61+]'
END AS AgeGroup 
FROM WizzardDeposits) AS t
GROUP BY AgeGroup

--Problem 10. First Letter
SELECT LEFT(FirstName, 1) AS FirstLetter FROM WizzardDeposits
WHERE DepositGroup = 'Troll Chest'
GROUP BY LEFT(FirstName, 1)

--Problem 11. Average Interest
SELECT DepositGroup, IsDepositExpired, AVG(DepositInterest) AS AverageInterest 
FROM WizzardDeposits
WHERE DATEPART(YEAR, DepositStartDate) >= 1985
GROUP BY DepositGroup, IsDepositExpired
ORDER BY DepositGroup DESC, IsDepositExpired

--Problem 12. * Rich Wizard, Poor Wizard
SELECT SUM([Difference]) FROM 
	   (SELECT w1.FirstName AS [Host Wizard], 
	   w1.DepositAmount AS [Host Wizard Deposit],
	   w2.FirstName AS [Guest Wizard],
	   w2.DepositAmount AS [Guest Wizard Deposit],
	   w1.DepositAmount - w2.DepositAmount AS [Difference]
       FROM WizzardDeposits AS w1
       JOIN WizzardDeposits AS w2
       ON w1.Id = w2.Id - 1) AS t

--Problem 13. Departments Total Salaries
SELECT DepartmentID, SUM(Salary) AS TotalSalary FROM Employees
GROUP BY DepartmentID
ORDER BY DepartmentID

--Problem 14. Employees Minimum Salaries
SELECT DepartmentID, MIN(Salary) AS MinimumSalary FROM Employees
WHERE DATEPART(YEAR, HireDate) > 2000
GROUP BY DepartmentID
HAVING DepartmentID IN(2,5,7)

--Problem 15. Employees Average Salaries
SELECT * INTO EmployeesWithSalary FROM Employees
where Salary > 30000

Delete from EmployeesWithSalary
where ManagerID = 42

Update EmployeesWithSalary
Set Salary += 5000
Where DepartmentID = 1

SELECT DepartmentID, AVG(Salary) AS AverageSalary 
FROM EmployeesWithSalary
GROUP BY DepartmentID

--Problem 16. Employees Maximum Salaries
Select DepartmentID, Max(Salary) As MaxSalary From Employees
Group by DepartmentID
Having Max(Salary) Not Between 30000 And 70000

--Problem 17. Employees Count Salaries
Select Count(Salary) As [Count] From Employees
Group By ManagerID
Having ManagerID Is Null

--Problem 18. *3rd Highest Salary
