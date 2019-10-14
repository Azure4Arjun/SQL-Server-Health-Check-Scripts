SELECT @@servername [Server],
       (
           SELECT total_physical_memory_kb / 1024 FROM sys.dm_os_sys_memory
       ) AS total_physical_memory_mb,
       (
           SELECT available_physical_memory_kb / 1024 FROM sys.dm_os_sys_memory
       ) AS available_memory_mb,
       (
           SELECT system_memory_state_desc FROM sys.dm_os_sys_memory
       ) AS memory_state,
       physical_memory_in_use_kb / 1024 AS [SQL Server Memory Usage (MB)],
       large_page_allocations_kb,
       locked_page_allocations_kb,
       page_fault_count,
       memory_utilization_percentage,
       available_commit_limit_kb,
       CASE
           WHEN process_physical_memory_low = 0 THEN
               'False'
           ELSE
               'True'
       END AS process_physical_memory_low,
       CASE
           WHEN process_virtual_memory_low = 0 THEN
               'False'
           ELSE
               'True'
       END AS process_virtual_memory_low
FROM sys.dm_os_process_memory WITH (NOLOCK)
OPTION (RECOMPILE);