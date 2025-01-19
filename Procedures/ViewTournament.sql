CREATE PROCEDURE ViewTournament
AS
BEGIN
    -- Check the role of the current user
    IF (IS_ROLEMEMBER('ComplexManager') = 1 OR IS_ROLEMEMBER('DataAdmin') = 1)
    BEGIN
        -- If the user is a Complex Manager or Data Admin, show approved tournaments
        SELECT TournamentID, TournamentName, StartDateTime, EndDateTime
        FROM Tournaments
        WHERE ApprovalStatus = 'Approved';
        RETURN;
    END

    IF (IS_ROLEMEMBER('TournamentOrganizer') = 1)
    BEGIN
        -- If the user is a Tournament Organizer, show tournaments they organize
        SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus
        FROM Tournaments
        WHERE OrganizerID = SUSER_SNAME(); -- Match OrganizerID with the login name
        RETURN;
    END

    -- If the user does not belong to any valid role, raise an error
    RAISERROR('You do not have the necessary permissions to access this functionality.', 16, 1);
END;

-- Create roles
CREATE ROLE DataAdmin;
CREATE ROLE ComplexManager;
CREATE ROLE TournamentOrganizer;

-- Create logins and users
CREATE LOGIN DA001 WITH PASSWORD = 'yourpassword'; -- Replace with actual password
CREATE LOGIN CM001 WITH PASSWORD = 'yourpassword'; -- Replace with actual password
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword'; -- Replace with actual password

CREATE USER DA001 FOR LOGIN DA001;
CREATE USER CM001 FOR LOGIN CM001;
CREATE USER TO001 FOR LOGIN TO001;

-- Add users to roles
EXEC sp_addrolemember 'DataAdmin', 'DA001';
EXEC sp_addrolemember 'ComplexManager', 'CM001';
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Grant SELECT permission on the Tournaments table
GRANT SELECT ON dbo.Tournaments TO DataAdmin;
GRANT SELECT ON dbo.Tournaments TO ComplexManager;
GRANT SELECT ON dbo.Tournaments TO TournamentOrganizer;

-- Grant EXECUTE permission on the procedure
GRANT EXECUTE ON dbo.ViewTournament TO DataAdmin;
GRANT EXECUTE ON dbo.ViewTournament TO ComplexManager;
GRANT EXECUTE ON dbo.ViewTournament TO TournamentOrganizer;
