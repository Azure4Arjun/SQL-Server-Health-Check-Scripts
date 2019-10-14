SELECT @@servername [Server],
       fullbackup.name AS Name,
       Last_Full_Backup,
       Days_Since_Last_Full,
       Last_Diff_Backup,
       Days_Since_Last_Diff,
       Last_Trans_Backup,
       CASE
           WHEN fullbackup.name IN ( 'model', 'tempdb' ) THEN
               'not needed'
           WHEN transbackup.RecoveryMode = 'SIMPLE' THEN
               'not needed'
           ELSE
               CAST(ISNULL(CAST(Days_Since_Last_Trans AS VARCHAR), 'MISSING') AS VARCHAR)
       END AS Days_Since_Last_Trans,
       transbackup.RecoveryMode AS Recovery_Mode
FROM
(
    SELECT sdb.name,
           CONVERT(SMALLDATETIME, MAX(bs.backup_finish_date)) AS Last_Full_Backup,
           DATEDIFF(d, MAX(bs.backup_finish_date), GETDATE()) AS Days_Since_Last_Full
    FROM master.dbo.sysdatabases sdb
        LEFT JOIN msdb.dbo.backupset bs
            ON sdb.name = bs.database_name
               AND bs.type = 'd'
    GROUP BY sdb.name,
             type
) AS fullbackup
    JOIN
    (
        SELECT sdb.name,
               CONVERT(SMALLDATETIME, MAX(bs.backup_finish_date)) AS Last_Diff_Backup,
               DATEDIFF(d, MAX(bs.backup_finish_date), GETDATE()) AS Days_Since_Last_Diff
        FROM master.dbo.sysdatabases sdb
            LEFT JOIN msdb.dbo.backupset bs
                ON sdb.name = bs.database_name
                   AND bs.type = 'i'
        GROUP BY sdb.name,
                 type
    ) AS diffbackup
        ON fullbackup.name = diffbackup.name
    JOIN
    (
        SELECT sdb.name,
               CONVERT(SMALLDATETIME, MAX(bs.backup_finish_date)) AS Last_Trans_Backup,
               DATEDIFF(d, MAX(bs.backup_finish_date), GETDATE()) AS Days_Since_Last_Trans,
               CONVERT(sysname, DATABASEPROPERTYEX(sdb.name, 'Recovery')) AS RecoveryMode
        FROM master.dbo.sysdatabases sdb
            LEFT JOIN msdb.dbo.backupset bs
                ON sdb.name = bs.database_name
                   AND bs.type = 'l'
        GROUP BY sdb.name,
                 type
    ) AS transbackup
        ON fullbackup.name = transbackup.name
ORDER BY fullbackup.name;


GO





