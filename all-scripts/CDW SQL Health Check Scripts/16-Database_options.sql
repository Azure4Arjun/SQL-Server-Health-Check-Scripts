DECLARE @compatibility_mode INT;
DECLARE @collation sysname;

SET @collation = CAST(SERVERPROPERTY(N'Collation') AS sysname);
SET @compatibility_mode = CASE
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '14' THEN
                                  140
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '13' THEN
                                  130
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '12' THEN
                                  120
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '11' THEN
                                  110
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '10' THEN
                                  100
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '9.' THEN
                                  90
                              WHEN SUBSTRING(CAST(SERVERPROPERTY(N'ProductVersion') AS sysname), 1, 2) = '8.' THEN
                                  80
                          END;

SELECT @@servername AS [Server],
       'Compatibility level' AS Warning,
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE compatibility_level < @compatibility_mode
UNION
SELECT @@servername,
       'CHECKSUM Page Verification not used',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE page_verify_option_desc <> 'CHECKSUM'
      AND [name] <> 'tempdb'
UNION
SELECT @@servername,
       'Auto Close On',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE is_auto_close_on <> 0
UNION
SELECT @@servername,
       'Auto Shrink On',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE is_auto_shrink_on <> 0
UNION
SELECT @@servername,
       'Auto Create Statistics On',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE is_auto_create_stats_on <> 1
UNION
SELECT @@servername,
       'Auto Update Statistics Not On',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE is_auto_update_stats_on <> 1
UNION
SELECT @@servername,
       'Trustworthy Bit is On',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE is_trustworthy_on = 1
      AND [name] <> 'msdb'
UNION
SELECT @@servername,
       'Database is not Online',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE state_desc <> 'ONLINE'
UNION
SELECT @@servername,
       'Collation Warning',
       [name],
       compatibility_level,
       page_verify_option_desc,
       state_desc,
       is_read_only,
       is_auto_close_on,
       is_auto_shrink_on,
       is_auto_create_stats_on,
       is_auto_update_stats_on,
       is_trustworthy_on,
       collation_name
FROM sys.databases
WHERE collation_name <> @collation
ORDER BY Warning;

