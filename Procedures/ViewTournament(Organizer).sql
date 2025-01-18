--Create the procedure
CREATE PROCEDURE ViewTournament_Organizer
AS
BEGIN
    -- Validate the user has the TournamentOrganizer role
    IF (IS_ROLEMEMBER('TournamentOrganizer') = 0)
    BEGIN
        RAISERROR('You do not have the necessary permissions to access this functionality.', 16, 1);
        RETURN;
    END

    -- Display tournaments for the logged-in user based on OrganizerID
    SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus
    FROM Tournaments
    WHERE OrganizerID = SUSER_SNAME(); -- Match OrganizerID with the login name
END;

-- Create the TournamentOrganizer role
CREATE ROLE TournamentOrganizer;

-- Create a login and user for the Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  -- Replace 'yourpassword' with an actual secure password
CREATE USER TO001 FOR LOGIN TO001;

-- Add the user to the TournamentOrganizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Grant permissions to the role
GRANT SELECT ON dbo.Tournaments TO TournamentOrganizer; -- Allow viewing tournaments
GRANT EXECUTE ON dbo.ViewTournament_Organizer TO TournamentOrganizer; -- Allow executing the procedure

-- Valid execution as a Tournament Organizer
EXECUTE AS USER = 'TO001'; -- Switch to the Tournament Organizer user
EXEC ViewTournament_Organizer; -- Execute the procedure
REVERT;

drop procedure ViewTournament_Organizer
