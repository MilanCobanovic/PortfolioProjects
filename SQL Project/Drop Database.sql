USE master;
GO

-- Terminate all processes using the database
ALTER DATABASE [MovingData] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- Drop the database
DROP DATABASE [MovingData];
GO
