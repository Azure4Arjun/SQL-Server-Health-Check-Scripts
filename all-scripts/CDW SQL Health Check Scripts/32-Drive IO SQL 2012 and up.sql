
--drop table #filestats
CREATE TABLE #filestats
(
    [DbName] sysname NOT NULL,
    [usage] NVARCHAR(15),
    [DbId] SMALLINT NOT NULL,
    [FileId] SMALLINT NOT NULL,
    [NumberReads] BIGINT NOT NULL,
    [NumberWrites] BIGINT NOT NULL,
    [BytesRead] BIGINT NOT NULL,
    [BytesWritten] BIGINT NOT NULL,
    [IoStallMS] BIGINT NOT NULL,
    [IoStallReadMS] BIGINT NOT NULL,
    [IoStallWriteMS] BIGINT NOT NULL,
    [TotalIO] BIGINT NOT NULL,
    [TotalBytes] BIGINT NOT NULL,
    [AvgReadStall] NUMERIC(20, 0) NOT NULL,
    [AvgWriteStall] NUMERIC(20, 0) NOT NULL,
    [AvgStallPerIO] NUMERIC(20, 0) NOT NULL,
    [AvgBytesPerIO] NUMERIC(20, 0) NOT NULL,
    [%IO] NUMERIC(20, 3) NOT NULL,
    [%Bytes] NUMERIC(20, 3) NOT NULL,
    [%Stall] NUMERIC(20, 3) NOT NULL,
    [File] VARCHAR(255),
    [size] BIGINT,
    [maxsize] NVARCHAR(15),
    [growth] NVARCHAR(15),
    [currentgrowthMB] INT
);

BEGIN
    DECLARE @TotalIO BIGINT,
            @TotalBytes BIGINT,
            @TotalStall BIGINT;
    DECLARE @strsql NVARCHAR(MAX),
            @dbname sysname,
            @dbid INT,
            @fileid INT;

    SELECT @TotalIO = SUM(NumberReads + NumberWrites),
           @TotalBytes = SUM(BytesRead + BytesWritten),
           @TotalStall = SUM(IoStallMS)
    FROM::fn_virtualfilestats(NULL, NULL);

    INSERT INTO #filestats
    SELECT [DbName] = DB_NAME([DbId]),
           '', --usage
           [DbId],
           [FileId],
           [NumberReads],
           [NumberWrites],
           [BytesRead],
           [BytesWritten],
           [IoStallMS],
           [IoStallReadMS],
           [IoStallWriteMS],
           [TotalIO] = CAST((NumberReads + NumberWrites) AS BIGINT),
           [TotalBytes] = (BytesRead + BytesWritten),
           [AvgStallRead] = ([IoStallReadMS] / (NumberReads + 1)),
           [AvgStallWrite] = ([IoStallWriteMS] / (NumberWrites + 1)),
           [AvgStallPerIO] = ([IoStallMS] / ([NumberReads] + [NumberWrites] + 1)),
           [AvgBytesPerIO] = ((BytesRead + BytesWritten) / (NumberReads + NumberWrites + 1)),
           [%IO] = (100 * CONVERT(FLOAT, (NumberReads + NumberWrites)) / @TotalIO),
           [%Bytes] = (100 * CONVERT(FLOAT, (BytesRead + BytesWritten)) / @TotalBytes),
           [%Stall] = (100 * CONVERT(FLOAT, IoStallMS) / @TotalStall),
           '',
           0,
           '',
           '',
           0
    FROM::fn_virtualfilestats(NULL, NULL)state;
    DECLARE mycursor CURSOR FOR
    SELECT f.DbName,
           f.DbId,
           f.FileId
    FROM #filestats f
        JOIN sys.databases d
            ON f.DbId = d.database_id
    WHERE d.state_desc = 'online';

    OPEN mycursor;
    FETCH NEXT FROM mycursor
    INTO @dbname,
         @dbid,
         @fileid;
    WHILE @@fetch_status = 0
    BEGIN
        SET @strsql
            = N'update #filestats set [File] = xfiles.[filename], size = cast(xfiles.[size] as bigint) * 8 / 1024 ,
          maxsize =(case xfiles.maxsize when -1 then N''Unlimited''
			else
			convert(nvarchar(15),cast(xfiles.maxsize  as bigint)* 8 ) + N'' KB'' end),
	  growth = (case status & 0x100000 when 0x100000 then
		convert(nvarchar(3), xfiles.growth) + N''%''
		else
		convert(nvarchar(15), xfiles.growth * 8 /1024) + N'' MB'' end),
		currentgrowthMB = (case status & 0x100000 when 0x100000 then
		           convert(int, xfiles.growth) * cast(xfiles.[size] * 8 /1024 as bigint)  / 100
		           else convert(int, xfiles.growth * 8) /1024 end) ,
	 usage =(case status & 0x40 when 0x40 then ''log only'' else ''data only'' end) from [' + @dbname
              + N']..sysfiles xfiles where ' + N' xfiles.fileid = ' + CAST(@fileid AS NVARCHAR)
              + N' and #filestats.DbId = ' + CAST(@dbid AS NVARCHAR) + N' and #filestats.FileId = '
              + CAST(@fileid AS NVARCHAR);
        PRINT @strsql;
        PRINT @strsql;
        EXEC sp_executesql @strsql;
        FETCH NEXT FROM mycursor
        INTO @dbname,
             @dbid,
             @fileid;
    END;
    CLOSE mycursor;
    DEALLOCATE mycursor;

END;



SELECT @@servername [Server],
       SUBSTRING([File], 1, 2) [Drive],
       *
FROM #filestats;

DROP TABLE #filestats;

SELECT @@servername [Server],
       [Drive],
       CASE
           WHEN num_of_reads = 0 THEN
               0
           ELSE
       (io_stall_read_ms / num_of_reads)
       END AS [Read Latency],
       CASE
           WHEN io_stall_write_ms = 0 THEN
               0
           ELSE
       (io_stall_write_ms / num_of_writes)
       END AS [Write Latency],
       CASE
           WHEN
           (
               num_of_reads = 0
               AND num_of_writes = 0
           ) THEN
               0
           ELSE
       (io_stall / (num_of_reads + num_of_writes))
       END AS [Overall Latency],
       CASE
           WHEN num_of_reads = 0 THEN
               0
           ELSE
       (num_of_bytes_read / num_of_reads)
       END AS [Avg Bytes/Read],
       CASE
           WHEN io_stall_write_ms = 0 THEN
               0
           ELSE
       (num_of_bytes_written / num_of_writes)
       END AS [Avg Bytes/Write],
       CASE
           WHEN
           (
               num_of_reads = 0
               AND num_of_writes = 0
           ) THEN
               0
           ELSE
       ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes))
       END AS [Avg Bytes/Transfer]
FROM
(
    SELECT LEFT(mf.physical_name, 2) AS Drive,
           SUM(num_of_reads) AS num_of_reads,
           SUM(io_stall_read_ms) AS io_stall_read_ms,
           SUM(num_of_writes) AS num_of_writes,
           SUM(io_stall_write_ms) AS io_stall_write_ms,
           SUM(num_of_bytes_read) AS num_of_bytes_read,
           SUM(num_of_bytes_written) AS num_of_bytes_written,
           SUM(io_stall) AS io_stall
    FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
        INNER JOIN sys.master_files AS mf WITH (NOLOCK)
            ON vfs.database_id = mf.database_id
               AND vfs.file_id = mf.file_id
    GROUP BY LEFT(mf.physical_name, 2)
) AS tab
ORDER BY [Overall Latency]
OPTION (RECOMPILE);