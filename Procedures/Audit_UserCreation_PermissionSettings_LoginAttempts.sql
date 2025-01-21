USE APArenaDB;
GO

-- Create roles
CREATE ROLE DataAdmin;
CREATE ROLE ComplexManager;
CREATE ROLE TournamentOrganizer;
CREATE ROLE IndividualCustomer;

-- Verify roles
SELECT name AS RoleName
FROM sys.database_principals
WHERE type = 'R';

-----------------------------------------------------------------------------------------------------------------------------------
-- Prerequisites: Create a folder "SQLAuditLogs" in C:Drive

-- 1. Audit User Creation
USE [master];
GO
-- Create a server audit (Have to create a folder named 'SQLAuditLogs in C drive first')
CREATE SERVER AUDIT UserCreationAudit
TO FILE (FILEPATH = 'C:\SQLAuditLogs\'); 
GO
-- ENABLE the server audit
ALTER SERVER AUDIT UserCreationAudit WITH (STATE = ON);
GO

-- Create a database audit specification
USE APArenaDB;
GO
CREATE DATABASE AUDIT SPECIFICATION AuditUserCreation
FOR SERVER AUDIT UserCreationAudit
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP); -- Tracks user creation and modification
GO

-- Enable the database audit specification
ALTER DATABASE AUDIT SPECIFICATION AuditUserCreation WITH (STATE = ON);
GO

-- Testing on UserCreation Audit
CREATE USER TestUser FOR LOGIN [TestLogin];
GO

SELECT 
    event_time,
    action_id,
    succeeded,
    session_server_principal_name AS executed_by,
    database_name,
    object_name AS user_name,
    statement
FROM sys.fn_get_audit_file('C:\SQLAuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ('CR', 'DR') -- CR: Create Principal, DR: Drop Principal
ORDER BY event_time DESC;


-----------------------------------------------------------------------------------------------------------------------------------

-- 2. PermissionAudit
-- Create a Server Audit
USE [master]
-- Create a server audit for tracking permission management activities
CREATE SERVER AUDIT AuditPermissions
TO FILE (FILEPATH = 'C:\SQLAuditLogs\')
WITH (ON_FAILURE = CONTINUE);
GO

-- Enable the server audit to start tracking permission management activities
ALTER SERVER AUDIT AuditPermissions WITH (STATE = ON);
GO

-- Switch to the target database
USE APArenaDB;
GO
-- Create a Database Audit Specification with both database and schema level auditing
CREATE DATABASE AUDIT SPECIFICATION AuditPermissionChanges
FOR SERVER AUDIT AuditPermissions
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = ON);
GO

-- Enable the Database Audit Specification
ALTER DATABASE AUDIT SPECIFICATION AuditPermissionChanges WITH (STATE = ON);
GO

-- Test the Setup
-- Permission Modifications
-- Grant SELECT on a specific table to DataAdmin
GRANT SELECT ON dbo.[User] TO DataAdmin;
REVOKE SELECT ON dbo.[Tournaments] FROM IndividualCustomer;
DENY SELECT ON dbo.[User] TO TournamentOrganizer;
GRANT EXEC ON dbo.[CreateLogin] TO DataAdmin;
GO

-- Logs for RolePermissionAudit
SELECT 
    event_time,
    action_id,
    succeeded,
    session_server_principal_name AS executed_by,
    database_name,
    object_name AS user_name,
    statement
FROM sys.fn_get_audit_file('C:\SQLAuditLogs\*.sqlaudit', DEFAULT, DEFAULT)
WHERE action_id IN ('G', 'D', 'R')
ORDER BY event_time DESC;

-----------------------------------------------------------------------------------------------------------------------------------

-- 3. Audit Login Attempts
USE [master];
-- Step 1: Create the Server Audit
CREATE SERVER AUDIT LoginAudit
TO FILE (FILEPATH = 'C:\SQLAuditLogs\', MAXSIZE = 5 GB, MAX_FILES = 10, RESERVE_DISK_SPACE = ON)
WITH (ON_FAILURE = CONTINUE);
GO

-- Step 2: Create the Server Audit Specification to capture login attempts
CREATE SERVER AUDIT SPECIFICATION LoginAuditSpecification
FOR SERVER AUDIT LoginAudit
ADD (FAILED_LOGIN_GROUP),      -- Tracks failed logins
ADD (SUCCESSFUL_LOGIN_GROUP)   -- Tracks successful logins
WITH (STATE = ON);
GO

-- Step 3: Enable the Audit
ALTER SERVER AUDIT LoginAudit
WITH (STATE = ON);
GO

-- Switch context to the new login (Generated from Login Creation)
EXECUTE AS LOGIN = 'DA0001';

REVERT;
USE [master];

SELECT 
    event_time,
    server_principal_name,
    action_id,
    succeeded,
    session_id,
    database_name,
    client_ip,
    application_name,
    host_name
FROM sys.fn_get_audit_file('C:\SQLAuditLogs\*', NULL, NULL)
WHERE action_id IN ('LGIS', 'LGIN')
ORDER BY event_time DESC;

-----------------------------------------------------------------------------------------------------------------------------------
