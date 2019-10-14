SELECT @@servername [Server],
       j.[name],
       j.[enabled],
       CAST(STUFF(STUFF(CAST(jh.run_date AS VARCHAR), 7, 0, '-'), 5, 0, '-') + ' '
            + STUFF(STUFF(REPLACE(STR(jh.run_time, 6, 0), ' ', '0'), 5, 0, ':'), 3, 0, ':') AS DATETIME) AS [LastRun],
       CAST(jh.run_duration / 10000 AS VARCHAR) + ':' + CAST(jh.run_duration / 100 % 100 AS VARCHAR) + ':'
       + CAST(jh.run_duration % 100 AS VARCHAR) AS Duration,
       CASE jh.run_status
           WHEN 0 THEN
               'Failed'
           WHEN 1 THEN
               'Success'
           WHEN 2 THEN
               'Retry'
           WHEN 3 THEN
               'Canceled'
           WHEN 4 THEN
               'In progress'
       END AS [Status]
FROM
(
    SELECT a.job_id,
           MAX(a.instance_id) AS [instance_id]
    FROM msdb.dbo.sysjobhistory a
    WHERE a.step_id = 0
    GROUP BY a.job_id
) b
    LEFT OUTER JOIN msdb.dbo.sysjobhistory jh
        ON jh.instance_id = b.instance_id
    RIGHT OUTER JOIN msdb.dbo.sysjobs j
        ON j.job_id = jh.job_id
WHERE j.name <> 'syspolicy_purge_history'
ORDER BY jh.run_date DESC;
