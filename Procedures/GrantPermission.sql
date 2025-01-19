USE APArenaDB;

-- Grant CONTROL permission to DataAdmin to manage permissions in the database
GRANT CONTROL ON DATABASE::APArenaDB TO DataAdmin;

-- Testing
EXECUTE AS LOGIN = 'DA0001';

-- Grant permission to roles
-- Grant SELECT and INSERT permissions to ComplexManager on specific tables
GRANT UPDATE ON [dbo].[Tournaments] TO ComplexManager;

-- Grant SELECT, INSERT, and UPDATE permissions to TournamentOrganizer
GRANT SELECT, INSERT, UPDATE ON [dbo].[TournamentTable] TO TournamentOrganizer;
GRANT SELECT ON [dbo].[User] TO ComplexManager;

-- Grant SELECT permission to IndividualCustomer
GRANT SELECT ON [dbo].[Facilities] TO IndividualCustomer;

SELECT * FROM [User]

REVERT;

-- Validate Permissions for DataAdmin
SELECT 
    grantee_principal_id, 
    permission_name, 
    state_desc
FROM sys.database_permissions 
WHERE grantee_principal_id = DATABASE_PRINCIPAL_ID('DataAdmin');

