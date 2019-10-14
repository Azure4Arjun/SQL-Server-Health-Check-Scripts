CREATE TABLE #waitstats
(
    waittype VARCHAR(250),
    waits BIGINT,
    waittime BIGINT,
    signaltime BIGINT
);

INSERT INTO #waitstats
EXEC ('DBCC SQLPERF(waitstats)');

-- add to list as necessary to remove unimportant waits
ALTER TABLE #waitstats ADD [category] VARCHAR(50);
GO
UPDATE #waitstats
SET [category] = CASE
                     WHEN waittype LIKE N'LCK_M_%' THEN
                         N'Lock'
                     WHEN waittype LIKE N'LATCH_%' THEN
                         N'Latch'
                     WHEN waittype LIKE N'PAGELATCH_%' THEN
                         N'Buffer Latch'
                     WHEN waittype LIKE N'PAGEIOLATCH_%' THEN
                         N'Buffer IO'
                     WHEN waittype LIKE N'RESOURCE_SEMAPHORE_%' THEN
                         N'Compilation'
                     WHEN waittype = N'SOS_SCHEDULER_YIELD' THEN
                         N'Scheduler Yield'
                     WHEN waittype IN ( N'LOGMGR', N'LOGBUFFER', N'LOGMGR_RESERVE_APPEND', N'LOGMGR_FLUSH', N'WRITELOG' ) THEN
                         N'Logging'
                     WHEN waittype IN ( N'ASYNC_NETWORK_IO', N'NET_WAITFOR_PACKET' ) THEN
                         N'Network IO'
                     WHEN waittype IN ( N'CXPACKET', N'EXCHANGE' ) THEN
                         N'Parallelism'
                     WHEN waittype IN ( N'RESOURCE_SEMAPHORE', N'CMEMTHREAD', N'SOS_RESERVEDMEMBLOCKLIST' ) THEN
                         N'Memory'
                     WHEN waittype LIKE N'CLR_%'
                          OR waittype LIKE N'SQLCLR%' THEN
                         N'CLR'
                     WHEN waittype LIKE N'DBMIRROR%'
                          OR waittype = N'MIRROR_SEND_MESSAGE' THEN
                         N'Mirroring'
                     WHEN waittype LIKE N'XACT%'
                          OR waittype LIKE N'DTC_%'
                          OR waittype LIKE N'TRAN_MARKLATCH_%'
                          OR waittype LIKE N'MSQL_XACT_%'
                          OR waittype = N'TRANSACTION_MUTEX' THEN
                         N'Transaction'
                     WHEN waittype LIKE N'SLEEP_%'
                          OR waittype IN ( N'LAZYWRITER_SLEEP', N'SQLTRACE_BUFFER_FLUSH', N'WAITFOR',
                                           N'WAIT_FOR_RESULTS'
                                         ) THEN
                         N'Sleep'
                     ELSE
                         waittype
                 END;

DELETE FROM #waitstats
WHERE waittype IN ( N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
                    N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE', N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT',
                    N'CLR_SEMAPHORE', N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
                    N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE', N'EXECSYNC', N'FSAGENT',
                    N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX', N'HADR_CLUSAPI_CALL',
                    N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
                    N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE', N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE',
                    N'ONDEMAND_TASK_QUEUE', N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
                    N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
                    N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
                    N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY', N'SLEEP_MASTERUPGRADED',
                    N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK', N'SLEEP_TEMPDBSTARTUP',
                    N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
                    N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS', N'WAITFOR',
                    N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
                    N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN', N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT', N'Total',
                    N'HADR_FILESTREAM_IOMGR_IOCOMPLETI'
                  )
      OR waittype LIKE '%sleep%';




DECLARE @waits BIGINT,
        @waittime BIGINT,
        @signaltime BIGINT;

-- sum
SELECT @waits = SUM(waits),
       @waittime = SUM(waittime),
       @signaltime = SUM(signaltime)
FROM #waitstats
WHERE [category] <> 'SLEEP';

-- report
SELECT TOP 10
    @@servername [Server],
    [category],
    waittype,
    waits,
    waittime,
    signaltime,
    (CAST(waittime AS FLOAT) / @waittime) * 100 AS "% total waittime",
    (CAST(signaltime AS FLOAT) / waittime) * 100 AS "signal %",
    waittime / waits AS "average wait ms"
FROM #waitstats
WHERE waittime <> 0
      AND category <> ' SLEEP'
ORDER BY waittime DESC;


DROP TABLE #waitstats;
