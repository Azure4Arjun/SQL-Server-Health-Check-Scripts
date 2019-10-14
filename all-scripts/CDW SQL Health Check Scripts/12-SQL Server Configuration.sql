USE master;
EXEC sp_configure 'show advanced option', '1';
GO
RECONFIGURE;
GO



CREATE TABLE #configuration
(
    [Name] VARCHAR(50),
    [Minimum] INT,
    [Maximum] INT,
    [Config Value] INT,
    [Run Value] INT
);
INSERT INTO #configuration
EXEC sp_configure;

SELECT @@servername AS [Server],
       'Config/Run Warning' AS [Config Type],
       *
FROM #configuration
WHERE [Config Value] <> [Run Value];


SELECT @@servername AS [Server],
       'All values',
       *
FROM #configuration;



DROP TABLE #configuration;