USE MovingData
GO

SELECT * FROM Moving
SELECT * FROM MovingInfo

/* If you imported data, data types are altered, please execute next:
(do not execute if you used 1st query to get data) */
ALTER TABLE Moving
ALTER COLUMN JobNumber smallint
ALTER TABLE Moving
ALTER COLUMN Date DATE
ALTER TABLE Moving
ALTER COLUMN CubicFoot smallint
ALTER TABLE Moving
ALTER COLUMN Income smallmoney
ALTER TABLE Moving
ALTER COLUMN Income smallmoney
ALTER TABLE MovingInfo
ALTER COLUMN JobNumber smallint

--Check how many moves we have in our database
SELECT
	COUNT(JobNumber) AS Number_of_moves
FROM Moving

--Check total income
SELECT
	SUM(Income) AS Total_Income
FROM Moving

/* What is net income if we know that we are paying movers on commission
(38.5% of income) and other expenses are 30% of income */
SELECT
	JobNumber,
	(Income-MoversCommission-OtherExpenses) AS NetIncome_per_move
FROM Moving

--Show total number of moves and total net income
SELECT
	COUNT(JobNumber) AS Total_number_of_moves,
	SUM(Income-MoversCommission-OtherExpenses) AS Total_net_income
FROM Moving

--Find all moves in 2022 and how many of them we had
/*
SELECT	
	JobNUmber,
	Name,
	LastName,
	DATEPART(YEAR, Date) AS Year
FROM Moving
WHERE DATEPART(YEAR, Date) = 2022
*/
WITH cte AS (
	SELECT	
		JobNUmber,
		Name,
		LastName,
		DATEPART(YEAR, Date) AS Year
	FROM Moving
	WHERE DATEPART(YEAR, Date) = 2022
)

SELECT 
	COUNT(JobNumber) AS Number_of_moves_in_2022
FROM cte

/* We could do this even easier if we are not interesting in
which moves were in 2022(this shows only the number of moves in 2022) */
SELECT 
	COUNT(JobNUmber) AS Number_of_moves_in_2022
FROM Moving
WHERE DATEPART(YEAR, Date) = 2022

/* Salesmen have been instructed to charge (income column) an amount not less
than the number of cubic feet a move entails. Let's see if they made any bad deals?! */
SELECT 
	JobNumber,
	Name,
	LastName,
	Date,
	CubicFoot,
	Income
FROM Moving
WHERE CubicFoot > Income

/* Let's separate income by year and order by highest income */
SELECT 
	SUM(Income) AS Total_income_per_year,
	DATEPART(YEAR, Date) AS Year
FROM Moving
GROUP BY DATEPART(YEAR, Date)
ORDER BY Total_income_per_year DESC

/* Look at whole Moving database using FULL JOIN
We also know that some data in table Moving is missing and for that reason we can't
use matching data from table MovingInfo. We will remove all rows with NULL */
SELECT 
	M.JobNumber,
	I.JobNUmber
FROM Moving M
FULL JOIN MovingInfo I
ON M.JobNumber = I.JobNumber
WHERE M.JobNumber IS NULL OR I.JobNumber IS NULL
--Now execute this:
DELETE FROM MovingInfo
WHERE JobNumber BETWEEN 21 AND 29

--Let's find out what our average review is
--Looks like we made review to be varchar and that is reason why AVG won't work if we don't use CAST
SELECT
	AVG(CAST(review AS tinyint)) AS Average_review
FROM MovingInfo

/* We can also permanently change the review column to TINYINT,
as CAST provides only a temporary conversion. */
--If you used my 1st query to create table run this:
ALTER TABLE MovingInfo
ALTER COLUMN review TINYINT
ALTER TABLE MovingInfo
ADD CONSTRAINT CHK_Review_Range CHECK (Review BETWEEN 1 AND 5)
--If you getting error
ALTER TABLE MovingInfo
DROP CONSTRAINT CK__MovingInf__Revie__/* Copy number from error here */
ALTER TABLE MovingInfo
ALTER COLUMN review TINYINT
ALTER TABLE MovingInfo
ADD CONSTRAINT CHK_Review_Range CHECK (Review BETWEEN 1 AND 5)

--If you imported data, run this:
ALTER TABLE MovingInfo
ALTER COLUMN review TINYINT
ALTER TABLE MovingInfo
ADD CONSTRAINT CHK_Review_Range CHECK (Review BETWEEN 1 AND 5)

--Now, let's try same thing but without CAST and round it on 2 decimals
SELECT
	ROUND(AVG(review*1.00),2) AS Average_review
FROM MovingInfo

--Or, we could check out how many reviews we got for each star rating
SELECT
	COUNT(Review) AS Review_by_stars
FROM MovingInfo
GROUP BY review

/* We can see that in some cases for state we have 'New York' and in most cases 
it is 'NY'. This time, we will update table to make our life easier. */
UPDATE MovingInfo
SET PickUpState = 'NY', DropOffState= 'NY'
WHERE PickUpState = 'New York' OR DropOffState = 'New York'

--Now when table is updated, let's see how many pick-ups we had in NY
SELECT
	COUNT(JobNumber) AS NY_PickUps
FROM MovingInfo	
WHERE PickUpState = 'NY' 

--What about drop offs?
SELECT
	COUNT(JobNumber) AS NY_DropOffs
FROM MovingInfo	
WHERE DropOffState = 'NY' 

--We want the list of all moves where people stayed in there neighborhood
SELECT
	JobNumber,
	PickUpNeighborhood,
	DropOffNeighborhood
FROM MovingInfo
WHERE PickUpNeighborhood = DropOffNeighborhood

/* Our marketing team wants to launch a new campaign focusing on neighborhoods where
we have the highest number of pickups, with a priority also on income per neighborhood */
WITH income AS (
	SELECT
		I.PickUpNeighborhood,
		SUM(M.Income) AS Income_per_Neighborhood,
		DENSE_RANK() OVER (ORDER BY SUM(M.Income) DESC) AS Rank_income
	FROM Moving M
	LEFT JOIN MovingInfo I
	ON M.JobNumber = I.JobNumber
	GROUP BY I.PickUpNeighborhood
),
Num_of_moves AS (
	SELECT
		PickUpNeighborhood,
		COUNT(PickUpNeighborhood) AS Number_of_pickups_by_neigh,
		DENSE_RANK() OVER (ORDER BY COUNT(PickUpNeighborhood) DESC) AS Rank_num_of_moves
	FROM MovingInfo
	GROUP BY PickUpNeighborhood
),
Combined AS (
	SELECT
		Num_of_moves.PickUpNeighborhood,
		Income.Rank_income,
		Num_of_moves.Rank_num_of_moves,
		(Income.Rank_income + Num_of_moves.Rank_num_of_moves) AS CombinedRank
	FROM Num_of_moves
	LEFT JOIN Income
	ON Num_of_moves.PickUpNeighborhood = Income.PickUpNeighborhood
)
SELECT 
	PickUpNeighborhood,
/*	Rank_income,
	Rank_num_of_moves,
	CombinedRank,  */
	DENSE_RANK() OVER (ORDER BY CombinedRank) AS FinalRank
FROM Combined
ORDER BY FinalRank ASC
