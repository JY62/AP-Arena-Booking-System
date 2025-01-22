-- Use the database
USE APArenaDB;

-- First create a procedure to get the OrganizerID with UNMASK permission
CREATE OR ALTER PROCEDURE GetTournamentOrganizer
    @TournamentID VARCHAR(8),
    @OrganizerID VARCHAR(8) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT @OrganizerID = NULLIF(OrganizerID, '')
    FROM Tournaments 
    WHERE TournamentID = @TournamentID;
END;
GO

-- Main procedure
CREATE OR ALTER PROCEDURE UpdateTournamentRegistration
    @TournamentID VARCHAR(8),
    @NewApprovalStatus VARCHAR(20) = NULL,
    @NewTournamentName VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Declare variables for role checking
    DECLARE @UserRole VARCHAR(50)
    DECLARE @OrganizerID VARCHAR(8)
    DECLARE @CurrentUserID VARCHAR(8)
    DECLARE @ErrorMessage VARCHAR(200)
    
    -- Get current user's login name without domain prefix
    SET @CurrentUserID = SUBSTRING(SYSTEM_USER, 
                                 CASE 
                                     WHEN CHARINDEX('\', SYSTEM_USER) > 0 
                                     THEN CHARINDEX('\', SYSTEM_USER) + 1 
                                     ELSE 1 
                                 END, 
                                 LEN(SYSTEM_USER));
    
    -- Debug print
    PRINT 'Current User: ' + @CurrentUserID;
    
    -- Get the user's role
    IF IS_ROLEMEMBER('ComplexManager') = 1
        SET @UserRole = 'ComplexManager'
    ELSE IF IS_ROLEMEMBER('TournamentOrganizer') = 1
        SET @UserRole = 'TournamentOrganizer'
    ELSE
        SET @UserRole = 'NoRole';
    
    -- Debug prints
    PRINT 'User Role: ' + @UserRole;
    PRINT 'Tournament ID being modified: ' + @TournamentID;

    -- Handle ComplexManager operations
    IF @UserRole = 'ComplexManager' AND @NewApprovalStatus IS NOT NULL
    BEGIN
        -- Validate the new status value
        IF @NewApprovalStatus NOT IN ('Approved', 'Pending', 'Rejected')
        BEGIN
            THROW 51000, 'Invalid approval status. Must be either Approved, Pending, or Rejected.', 1;
            RETURN;
        END
        
        -- Update tournament status
        UPDATE Tournaments
        SET ApprovalStatus = @NewApprovalStatus
        WHERE TournamentID = @TournamentID;
        
        PRINT 'Tournament approval status updated successfully.';
    END
    
    -- Handle TournamentOrganizer operations
    ELSE IF @UserRole = 'TournamentOrganizer' AND @NewTournamentName IS NOT NULL
    BEGIN
        -- Get the OrganizerID using the helper procedure
        EXEC GetTournamentOrganizer 
            @TournamentID = @TournamentID,
            @OrganizerID = @OrganizerID OUTPUT;

        IF @OrganizerID IS NULL
        BEGIN
            THROW 51000, 'Tournament does not exist or has no organizer assigned.', 1;
            RETURN;
        END

        -- Check if the user is the organizer of this tournament
        IF TRIM(@CurrentUserID) <> TRIM(@OrganizerID)
        BEGIN
            SET @ErrorMessage = 'You can only modify tournaments that you organize. Current user: ' + 
                               TRIM(@CurrentUserID) + ', Tournament: ' + @TournamentID;
            THROW 51000, @ErrorMessage, 1;
            RETURN;
        END
        
        -- Update tournament name
        UPDATE Tournaments
        SET TournamentName = @NewTournamentName
        WHERE TournamentID = @TournamentID;
        
        PRINT 'Tournament name updated successfully.';
    END
    
    -- Handle unauthorized access
    ELSE
    BEGIN
        THROW 51000, 'You do not have permission to perform this operation.', 1;
        RETURN;
    END
END;
GO



--Testing
-- Create Complex Manager role
CREATE ROLE ComplexManager;

-- Create the ComplexManager login and user
CREATE LOGIN CM001 WITH PASSWORD = '123';  -- Replace with actual password
CREATE USER CM001 FOR LOGIN CM001;
EXEC sp_addrolemember 'ComplexManager', 'CM001';

--GRANTING PERMISSION 
GRANT EXECUTE ON dbo.UpdateTournamentRegistration TO ComplexManager;
GRANT SELECT ON dbo.Tournaments TO ComplexManager;

-- Log in as CM001 and execute the procedure
EXECUTE AS USER = 'CM001';
EXEC UpdateTournamentRegistration 
    @TournamentID = 'T004',
    @NewApprovalStatus = 'Rejected';
REVERT;

---------------------------------------------------------------------------------------
--Create Tournament Organizer Role
CREATE ROLE TournamentOrganizer;

-- Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = '123';  -- Replace with actual password
CREATE USER TO001 FOR LOGIN TO001;
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

--GRANTING PERMISSION 
GRANT EXECUTE ON dbo.UpdateTournamentRegistration TO TournamentOrganizer;
GRANT EXECUTE ON GetTournamentOrganizer TO TournamentOrganizer;
GRANT SELECT ON dbo.Tournaments TO TournamentOrganizer;

-- As Tournament Organizer (updating tournament name)
EXECUTE AS USER = 'TO001';
EXEC UpdateTournamentRegistration 
    @TournamentID = 'T001',
    @NewTournamentName = 'Updated Tournament';
REVERT;


