-- ViewTournament (Complex Manager and Data Admin)
CREATE PROCEDURE ViewTournament_ManagerAdmin
AS
BEGIN
    -- Check if the user is a Complex Manager or Data Admin
    IF (IS_ROLEMEMBER('ComplexManager') = 0 AND IS_ROLEMEMBER('DataAdmin') = 0)
    BEGIN
        RAISERROR('You do not have the necessary permissions to access this functionality.', 16, 1);
        RETURN;
    END

    -- Proceed with functionality if the user has the required role
    PRINT 'Viewing available tournaments for Complex Manager and Data Admin:';
    SELECT TournamentID, TournamentName, StartDateTime, EndDateTime
    FROM Tournaments
    WHERE ApprovalStatus = 'Approved';
END;


-- Create the DataAdmin role
CREATE ROLE DataAdmin;

-- Create the ComplexManager role
CREATE ROLE ComplexManager;

-- Create login and user for DataAdmin
CREATE LOGIN DA001 WITH PASSWORD = 'yourpassword'; -- Replace with actual password
CREATE USER DA001 FOR LOGIN DA001;

-- Create login and user for ComplexManager
CREATE LOGIN CM001 WITH PASSWORD = 'yourpassword'; -- Replace with actual password
CREATE USER CM001 FOR LOGIN CM001;

-- Add users to their respective roles
EXEC sp_addrolemember 'DataAdmin', 'DA001';
EXEC sp_addrolemember 'ComplexManager', 'CM001';

-- Grant SELECT permission on Tournaments table to both roles
GRANT SELECT ON dbo.Tournaments TO DataAdmin;
GRANT SELECT ON dbo.Tournaments TO ComplexManager;

-- Grant EXECUTE permission on ViewTournament procedure to both roles
GRANT EXECUTE ON dbo.ViewTournament TO DataAdmin;
GRANT EXECUTE ON dbo.ViewTournament TO ComplexManager;

-- Valid EXEC (Complex Manager)
EXECUTE AS USER = 'CM001';
EXEC ViewTournament_ManagerAdmin;
REVERT;

-- Valid EXEC (Data Admin)
EXECUTE AS USER = 'DA001';
EXEC ViewTournament_ManagerAdmin;
REVERT;

DROP PROCEDURE ViewTournament_ManagerAdmin;

