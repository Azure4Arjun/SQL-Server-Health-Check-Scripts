SELECT @@servername [Server],
       j.name,
       j.enabled,
       s.step_name,
       s.subsystem,
       s.database_name,
       --,s.command,
       l.name
FROM msdb.dbo.sysjobsteps s
    JOIN msdb.dbo.sysjobs j
        ON s.job_id = j.job_id
    LEFT OUTER JOIN master.dbo.syslogins l
        ON j.owner_sid = l.sid
WHERE j.name <> 'syspolicy_purge_history'
ORDER BY j.name;