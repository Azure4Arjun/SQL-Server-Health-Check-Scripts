USE tempdb;
GO
WITH f
AS (SELECT [name],
           [size] = [size] / 128.0
    FROM sys.database_files),
     s
AS (SELECT [name],
           [size],
           [free] = [size] - CONVERT(INT, FILEPROPERTY([name], 'SpaceUsed')) / 128.0
    FROM f)
SELECT [name],
       SUBSTRING(CONVERT(VARCHAR(20), [size]), 0, 5) AS 'size in MB',
       SUBSTRING(CONVERT(VARCHAR(20), [free]), 0, 5) AS 'free MB',
       SUBSTRING(CONVERT(VARCHAR(20), [free] * 100.0 / [size]), 0, 5) AS 'percent free'
FROM s;


CREATE TABLE #xp_msver
(
    indexvalue SMALLINT,
    keyvalue VARCHAR(255),
    internalValue VARCHAR(15),
    datavalue VARCHAR(255)
);
DECLARE @CPUCount INT;
INSERT INTO #xp_msver
EXEC xp_msver;

SELECT @CPUCount = CAST(datavalue AS INT)
FROM #xp_msver
WHERE keyvalue = 'ProcessorCount';

SELECT @@servername [Server],
       mf.name,
       @CPUCount AS CPUs,
       mf.size * 8 / 1024.00 AS [Initial Size in MB],
       df.size * 8 / 1024.00 AS [Current Size in MB],
       mf.physical_name
FROM master.sys.master_files mf
    JOIN tempdb.sys.database_files df
        ON mf.name = df.name;
--where	database_name = DB_ID()

DROP TABLE #xp_msver;