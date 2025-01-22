CREATE PROCEDURE BookTournament
    @UserID NVARCHAR(50),          
    @TournamentID NVARCHAR(8),
    @FacilityID NVARCHAR(8),
    @TotalAmountOfPeople INT
AS
BEGIN
    -- Check if the current user is a Tournament Organizer
    IF NOT EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
        WHERE dp.name = 'TournamentOrganizer' 
        AND drm.member_principal_id = USER_ID(@UserID)
    )
    BEGIN
        RAISERROR('You do not have permission to book a tournament. Only Tournament Organizers are allowed.', 16, 1);
        RETURN;
    END

    -- Validate if the tournament exists and is approved
    IF (SELECT COUNT(*) 
        FROM Tournaments 
        WHERE TournamentID = @TournamentID 
        AND ApprovalStatus = 'Approved') = 0
    BEGIN
        RAISERROR('Tournament does not exist or is not approved for booking.', 16, 1);
        RETURN;
    END

    -- Check if the facility is available
    DECLARE @FacilityAvailable BIT;

    SET @FacilityAvailable = (SELECT TOP 1 Available 
                              FROM Facilities 
                              WHERE FacilityID = @FacilityID 
                              AND Available = 1);

    IF @FacilityAvailable = 0
    BEGIN
        RAISERROR('The selected facility is not available for the requested time.', 16, 1);
        RETURN;
    END

    -- Declare booking details
    DECLARE @BookingType NVARCHAR(50) = 'Tournament';
    DECLARE @StartDateTime DATETIME = GETDATE();  -- Current time as example
    DECLARE @EndDateTime DATETIME = DATEADD(HOUR, 3, @StartDateTime);  -- 3 hours for the event

    -- Check if the facility has already been booked for the tournament
    IF EXISTS (SELECT 1 
               FROM Bookings 
               WHERE FacilityID = @FacilityID 
               AND TournamentID = @TournamentID
               AND ((@StartDateTime BETWEEN StartDateTime AND EndDateTime) OR 
                    (@EndDateTime BETWEEN StartDateTime AND EndDateTime)))
    BEGIN
        RAISERROR('The facility is already booked for the selected time.', 16, 1);
        RETURN;
    END

    -- Insert the booking into the Bookings table
    INSERT INTO Bookings (FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
    VALUES (@FacilityID, @UserID, @BookingType, @TournamentID, @StartDateTime, @EndDateTime, @TotalAmountOfPeople);
END;



-- Create role for Tournament Organizer
CREATE ROLE TournamentOrganizer;

-- Create login for Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  
CREATE USER TO001 FOR LOGIN TO001;

-- Add user to Tournament Organizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Grant permissions on BookTournament to TournamentOrganizer
GRANT EXECUTE ON dbo.BookTournament TO TournamentOrganizer;

-- Create role for Tournament Organizer
DROP ROLE TournamentOrganizer;

-- Create login for Tournament Organizer
DROP LOGIN TO001   
DROP USER TO001

-- Add user to Tournament Organizer role
EXEC sp_droprolemember 'TournamentOrganizer', 'TO001';

-- Grant permissions on BookTournament to TournamentOrganizer
REVOKE EXECUTE ON dbo.BookTournament TO TournamentOrganizer;

drop procedure BookTournament

-- Execute the procedure as a Tournament Organizer
-- Assuming the user TO001 is a Tournament Organizer
EXECUTE AS USER = 'TO001'; -- Impersonate the Tournament Organizer
EXEC BookTournament 
    @UserID = 'TO001',          -- Tournament Organizer UserID
    @TournamentID = 'T001',     -- TournamentID to be booked
    @FacilityID = 'F1',         -- FacilityID to be used
    @TotalAmountOfPeople = 100; -- Total people expected
REVERT;
