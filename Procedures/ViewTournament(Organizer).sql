-- ViewTournament (Tournament Organizer)
CREATE PROCEDURE ViewTournament_Organizer
AS
BEGIN
    PRINT 'Tournaments under your ID:';
    SELECT TournamentID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus
    FROM Tournaments
    WHERE OrganizerID = SYSTEM_USER;
END;

--Create role
CREATE ROLE TournamentOrganizer;

-- Create login for Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  
CREATE USER TO001 FOR LOGIN TO001;

-- Add user to Tournament Organizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Role and Permissions
GRANT SELECT ON dbo.Tournaments TO TournamentOrganizer;
GRANT EXECUTE ON dbo.ViewTournament_Organizer TO TournamentOrganizer;

-- Valid EXEC
EXEC ViewTournament_Organizer;
REVERT;

DROP PROCEDURE ViewTournament_Organizer;
