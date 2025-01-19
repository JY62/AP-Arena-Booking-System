-- Enable advanced options
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO

-- Enable xp_cmdshell
sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO

-- Create backup directory if it doesn't exist
EXEC xp_cmdshell 'if not exist "C:\SQLBackups\APArenaDB" mkdir "C:\SQLBackups\APArenaDB"'
GO

-- Create Transaction Log Backup Job (Every 6 hours)
USE [msdb]
GO

BACKUP DATABASE [APArenaDB]
TO DISK = N'C:\SQLBackups\APArenaDB\APArenaDB_FullBackup_$(DATE:yyyymmdd).bak'
WITH COMPRESSION, CHECKSUM;


EXEC dbo.sp_add_job
    @job_name = N'APArenaDB_LogBackup_6Hours',
    @description = N'Transaction log backup every 6 hours for APArenaDB',
    @category_name = N'Database Maintenance'
GO

EXEC sp_add_jobstep
    @job_name = N'APArenaDB_LogBackup_6Hours',
    @step_name = N'Log Backup',
    @subsystem = N'TSQL',
    @command = N'DECLARE @FileName nvarchar(260)
                 SET @FileName = N''C:\SQLBackups\APArenaDB\APArenaDB_Log_'' + 
                                CONVERT(nvarchar(8), GETDATE(), 112) + N''_'' + 
                                REPLACE(CONVERT(nvarchar(5), GETDATE(), 108), '':'', '''') + N''.trn''
                 
                 BACKUP LOG [APArenaDB] 
                 TO DISK = @FileName
                 WITH COMPRESSION, CHECKSUM',
    @retry_attempts = 3,
    @retry_interval = 5
GO

-- Create schedule for transaction log backup (Every 6 hours)
EXEC sp_add_jobschedule
    @job_name = N'APArenaDB_LogBackup_6Hours',
    @name = N'Every6HoursSchedule',
    @freq_type = 4,                 --- Daily frequency
    @freq_interval = 1,             --- Every day
    @freq_subday_type = 8,          --- Specifies hours as the unit
    @freq_subday_interval = 6,      --- Run every 6 hours
    @active_start_time = 000000     --- Start at midnight
GO

-- Enable the transaction log backup job
EXEC dbo.sp_update_job @job_name = N'APArenaDB_LogBackup_6Hours', @enabled = 1
GO

-- Create or verify backup history cleanup job
IF NOT EXISTS (SELECT name FROM msdb.dbo.sysjobs WHERE name = N'Cleanup_Backup_History')
BEGIN
    EXEC dbo.sp_add_job
        @job_name = N'Cleanup_Backup_History',
        @description = N'Cleanup backup history and files older than 30 days'
    
    EXEC sp_add_jobstep
        @job_name = N'Cleanup_Backup_History',
        @step_name = N'Cleanup',
        @subsystem = N'TSQL',
        @command = N'
            DECLARE @CleanupDate datetime
            SET @CleanupDate = DATEADD(dd, -30, GETDATE())
            
            -- Clean up backup history
            EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @CleanupDate
            
            -- Delete old backup files
            EXEC xp_cmdshell ''forfiles /p "C:\SQLBackups\APArenaDB" /s /m *.* /d -30 /c "cmd /c del @path"''
        '
    
    EXEC sp_add_jobschedule
        @job_name = N'Cleanup_Backup_History',
        @name = N'DailyCleanup',
        @freq_type = 4,
        @freq_interval = 1,
        @active_start_time = 020000
    
    EXEC dbo.sp_update_job @job_name = N'Cleanup_Backup_History', @enabled = 1
END
GO

EXEC msdb.dbo.sp_add_jobserver 
    @job_name = N'APArenaDB_LogBackup_6Hours',
    @server_name = N'JUNYEE';  -- server name 
GO

EXEC msdb.dbo.sp_start_job @job_name = N'APArenaDB_LogBackup_6Hours';
GO

-- Verification
-- Enable xp_cmdshell
sp_configure 'xp_cmdshell', 1
GO

RECONFIGURE
GO

SELECT 
    j.name AS 'Job Name',
    h.run_date,
    h.run_time,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS 'Status',
    h.message AS 'Details'
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h 
    ON j.job_id = h.job_id
WHERE j.name = 'APArenaDB_LogBackup_6Hours'
    AND h.run_date >= CONVERT(int, CONVERT(varchar(8), DATEADD(day, -1, GETDATE()), 112))
ORDER BY h.run_date DESC, h.run_time DESC;
GO

-- Check Job Creation
SELECT job_id, name, enabled
FROM msdb.dbo.sysjobs
WHERE name = N'APArenaDB_LogBackup_6Hours';

-- Check Job Steps
SELECT step_id, step_name, subsystem, command
FROM msdb.dbo.sysjobsteps
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'APArenaDB_LogBackup_6Hours');

-- Verify Job Schedule
SELECT s.name, s.freq_type, s.freq_interval, s.freq_subday_type, s.freq_subday_interval, s.active_start_time
FROM msdb.dbo.sysschedules s
INNER JOIN msdb.dbo.sysjobschedules js ON s.schedule_id = js.schedule_id
WHERE js.job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'APArenaDB_LogBackup_6Hours');

-- Check if the job is running
SELECT job_id, name, enabled
FROM msdb.dbo.sysjobs
WHERE name = N'APArenaDB_LogBackup_6Hours';

-- Check backup files
EXEC xp_cmdshell 'dir C:\SQLBackups\APArenaDB';

-- Verify Cleanup Job
SELECT job_id, name, enabled
FROM msdb.dbo.sysjobs
WHERE name = N'Cleanup_Backup_History';

EXEC msdb.dbo.sp_help_jobhistory @job_name = N'APArenaDB_LogBackup_6Hours';

SELECT job_id, step_id, step_name, run_status, run_date, run_duration, message
FROM msdb.dbo.sysjobhistory
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = N'APArenaDB_LogBackup_6Hours')
ORDER BY run_date DESC;
