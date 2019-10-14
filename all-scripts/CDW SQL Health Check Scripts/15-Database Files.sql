USE master;
GO
SELECT @@servername AS [Server],
       d.name,
       SUBSTRING(physical_name, 1, 2) AS drive,
       f.size * 8 / 1024 AS sizemb,
       d.recovery_model_desc,
       f.*
FROM sys.master_files f
    JOIN sys.databases d
        ON d.database_id = f.database_id;