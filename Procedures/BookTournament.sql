CREATE PROCEDURE BookTournament
    @TournamentID NVARCHAR(8),      -- TournamentID to be booked
    @StartDateTime DATETIME,        -- Start date and time of the booking
    @EndDateTime DATETIME,          -- End date and time of the booking
    @FacilityID NVARCHAR(8),        -- FacilityID for the booking
    @BookingID NVARCHAR(50)         -- BookingID to be manually assigned
AS
BEGIN
    -- Declare necessary variables
    DECLARE @UserID NVARCHAR(50);

    -- Set the current UserID based on the login user
    SET @UserID = SUSER_NAME();

    -- Validate if the tournament exists
    IF (SELECT COUNT(*) 
        FROM Tournaments 
        WHERE TournamentID = @TournamentID) = 0
    BEGIN
        RAISERROR('Tournament does not exist.', 16, 1);
        RETURN;
    END

    -- Validate if the facility is available
    IF EXISTS (
        SELECT 1
        FROM Bookings
        WHERE FacilityID = @FacilityID
          AND (
              (@StartDateTime BETWEEN StartDateTime AND EndDateTime)
              OR (@EndDateTime BETWEEN StartDateTime AND EndDateTime)
              OR (StartDateTime BETWEEN @StartDateTime AND @EndDateTime)
              OR (EndDateTime BETWEEN @StartDateTime AND @EndDateTime)
          )
    )
    BEGIN
        RAISERROR('Facility is not available during the selected time.', 16, 1);
        RETURN;
    END

    -- Validate if the BookingID already exists
    IF EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID)
    BEGIN
        RAISERROR('The BookingID already exists. Please use a unique BookingID.', 16, 1);
        RETURN;
    END

    -- Check if the user has already booked the tournament
    IF EXISTS (
        SELECT 1
        FROM Bookings
        WHERE TournamentID = @TournamentID
          AND UserID = @UserID
    )
    BEGIN
        RAISERROR('You have already booked this tournament.', 16, 1);
        RETURN;
    END

    -- Insert the booking if all validations pass
    INSERT INTO Bookings (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
    VALUES (@BookingID, @FacilityID, @UserID, 'Tournament', @TournamentID, @StartDateTime, @EndDateTime, 100);

    -- Update the Tournament table to mark it as booked
    UPDATE Tournaments
    SET ApprovalStatus = 'Approved'  -- Ensure valid value ('Approved' or 'Denied')
    WHERE TournamentID = @TournamentID;

    PRINT 'Tournament booked successfully.';
END;
GO




DROP PROCEDURE BookTournament;

-- Create role for Tournament Organizer
CREATE ROLE TournamentOrganizer;

-- Create login for Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  
CREATE USER TO001 FOR LOGIN TO001;

-- Add user to Tournament Organizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Grant permissions on BookTournament to TournamentOrganizer
GRANT EXECUTE ON dbo.BookTournament TO TournamentOrganizer;
GRANT SELECT (FacilityID, StartDateTime, EndDateTime, BookingType, TournamentID) ON Bookings TO TournamentOrganizer;
GRANT INSERT ON Bookings TO TournamentOrganizer;

-- Create role for Tournament Organizer
DROP ROLE TournamentOrganizer;

-- Create login for Tournament Organizer
DROP LOGIN TO001   
DROP USER TO001

-- Add user to Tournament Organizer role
EXEC sp_droprolemember 'TournamentOrganizer', 'TO001';

-- Grant permissions on BookTournament to TournamentOrganizer
REVOKE EXECUTE ON dbo.BookTournament TO TournamentOrganizer;
REVOKE SELECT (FacilityID, StartDateTime, EndDateTime, BookingType, TournamentID) ON Bookings TO TournamentOrganizer;
REVOKE INSERT ON Bookings TO TournamentOrganizer;

drop procedure BookTournament

-- Valid execution of the procedure by the Tournament Organizer
Execute as user = 'TO001'
EXEC BookTournament 
    @TournamentID = 'T002',
    @StartDateTime = '2025-01-24 10:30:00',
    @EndDateTime = '2025-01-24 13:30:00',
    @FacilityID = 'F003',
    @BookingID = 'B011'; -- Manually assign the BookingID
Revert;
