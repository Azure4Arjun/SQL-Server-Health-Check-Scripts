USE master;
GO
SELECT @@servername AS [Server],
       l.name AS Owner,
       d.*
FROM sys.databases d
    LEFT OUTER JOIN syslogins l
        ON d.owner_sid = l.sid;