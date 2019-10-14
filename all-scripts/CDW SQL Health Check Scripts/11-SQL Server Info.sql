


-- create tables
CREATE TABLE #registrydata
(
    KeyValue VARCHAR(255),
    DataValue VARCHAR(255)
);
CREATE TABLE #xp_msver
(
    IndexValue SMALLINT,
    KeyValue VARCHAR(255),
    InternalValue VARCHAR(15),
    DataValue VARCHAR(255)
);
CREATE TABLE #reportdata
(
    [Name] VARCHAR(255),
    [Value] VARCHAR(255)
);

-- insert interim tables
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'ProductName';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'CurrentBuildNumber';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'ProductID';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'CurrentVersion';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'CSDVersion';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'BuildLab';
GO
INSERT INTO #registrydata
EXEC master..xp_regread 'HKEY_LOCAL_MACHINE',
                        'SOFTWARE\MICROSOFT\Windows NT\CurrentVersion',
                        'EditionID';
GO
INSERT INTO #xp_msver
EXEC xp_msver;
GO


--- insert into report table
INSERT INTO #reportdata
SELECT 'Server Name',
       CAST(SERVERPROPERTY(N'Servername') AS sysname);
INSERT INTO #reportdata
SELECT 'Instance Name',
       CAST(SERVERPROPERTY(N'InstanceName') AS sysname);
INSERT INTO #reportdata
SELECT 'Is Clustered',
       CAST(SERVERPROPERTY(N'IsClustered') AS sysname);
INSERT INTO #reportdata
SELECT 'Executing On',
       CAST(SERVERPROPERTY(N'ComputerNamePhysicalNetBios') AS sysname);
INSERT INTO #reportdata
SELECT 'OS Version',
       DataValue
FROM #registrydata
WHERE KeyValue = 'ProductName';
--insert into #reportdata select	'OS Service Pack',isnull('',DataValue ) from	#registrydata where  KeyValue = 'CSDVersion'
/*
insert into #reportdata 
select	'Windows Edition',
		case
			when substring(DataValue,1,5) = '69712' then '2003 Standard Edition 32 bit'
			when substring(DataValue,1,5) = '69753' then '2003 Web Edition 32 bit'
			when substring(DataValue,1,5) = '69713' then '2003 Enterprise Edition 32 bit'
			when substring(DataValue,1,5) = '69754' then '2003 Datacenter Edition 32 bit'
			when substring(DataValue,1,5) = '69770' then '2003 Enterprise Edition 64 bit'
			when substring(DataValue,1,5) = '69769' then '2003 Datacenter Edition 64 bit'
			else 'Unknown Windows Edition'
		end as "Windows Edition"
from	#registrydata
where	KeyValue = 'ProductID'
*/
INSERT INTO #reportdata
SELECT 'SQL Server Product',
       CASE
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '14.0' THEN
               'SQL Server 2017'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '13.0' THEN
               'SQL Server 2016'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '12.0' THEN
               'SQL Server 2014'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '11.0' THEN
               'SQL Server 2012'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '10.5' THEN
               'SQL Server 2008 R2'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 4) = '10.0' THEN
               'SQL Server 2008'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '9.' THEN
               'SQL Server 2005'
           WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '8.' THEN
               'SQL Server 2000'
       END;
INSERT INTO #reportdata
SELECT 'SQL Server Edition',
       CAST(SERVERPROPERTY(N'Edition') AS sysname);
INSERT INTO #reportdata
SELECT 'SQL Server Version',
       CAST(SERVERPROPERTY(N'ProductVersion') AS sysname);
--insert into #reportdata select 'Product Version', DataValue from #xp_msver where KeyValue = 'ProductVersion'
INSERT INTO #reportdata
SELECT 'Language',
       DataValue
FROM #xp_msver
WHERE KeyValue = 'Language';
INSERT INTO #reportdata
SELECT 'Collation',
       CAST(SERVERPROPERTY(N'Collation') AS sysname);
INSERT INTO #reportdata
SELECT 'Case Sensitive',
       CASE
           WHEN 'A' <> 'a' THEN
               'Yes'
           ELSE
               'No'
       END;
INSERT INTO #reportdata
SELECT 'Processors',
       DataValue
FROM #xp_msver
WHERE KeyValue = 'ProcessorCount';
INSERT INTO #reportdata
SELECT 'Platform',
       DataValue
FROM #xp_msver
WHERE KeyValue = 'Platform';
INSERT INTO #reportdata
SELECT 'Active Procesors',
       DataValue
FROM #xp_msver
WHERE KeyValue = 'ProcessorActiveMask';
INSERT INTO #reportdata
SELECT 'Physcial Memory',
       DataValue
FROM #xp_msver
WHERE KeyValue = 'PhysicalMemory';
--insert into #reportdata select 'License Type', CAST(serverproperty(N'LicenseType') AS sysname)
--insert into #reportdata select 'Licenses', CAST(serverproperty(N'NumLicenses') AS sysname)
INSERT INTO #reportdata
SELECT 'Full Text Enabled',
       CASE
           WHEN CONVERT(sysname, SERVERPROPERTY('IsFulltextEnabled')) = '0' THEN
               'No'
           ELSE
               'Yes'
       END;
INSERT INTO #reportdata
SELECT 'Integrated Security',
       CASE
           WHEN CONVERT(sysname, SERVERPROPERTY('IsIntegratedSecurityOnly')) = '0' THEN
               'No'
           ELSE
               'Yes'
       END;

UPDATE #reportdata
SET [Value] = ''
WHERE [Value] IS NULL;


-- report

DECLARE @cols AS NVARCHAR(MAX),
        @query AS NVARCHAR(MAX);



SELECT @cols = STUFF(
(
    SELECT ',' + QUOTENAME([Name])
    FROM #reportdata
    GROUP BY [Name]
    --  order by id
    FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'),
1   ,
1   ,
''
                    );

SET @query
    = 'SELECT  @@servername as [Server], ' + @cols
      + ' from 
             (
                select [Value], [Name]
                from #reportdata
            ) x
            pivot 
            (
                max([Value])
                for [Name] in (' + @cols + ')
            ) p ';
PRINT @query;
EXECUTE (@query);
--select @@servername,* from #reportdata



DROP TABLE #registrydata;
DROP TABLE #xp_msver;
DROP TABLE #reportdata;




