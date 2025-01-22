CREATE PROCEDURE BookTournament
    @TournamentID NVARCHAR(8) -- TournamentID to be booked
AS
BEGIN
    -- Declare necessary variables
    DECLARE @UserID NVARCHAR(50);
    DECLARE @FacilityID NVARCHAR(8);
    DECLARE @BookingType NVARCHAR(50);
    DECLARE @StartDateTime DATETIME;
    DECLARE @EndDateTime DATETIME;
    DECLARE @TotalAmountOfPeople INT;

    -- Set the current UserID based on the login user
    SET @UserID = SUSER_NAME();

    -- Validate if the tournament exists and is approved
    IF (SELECT COUNT(*) 
        FROM Tournaments 
        WHERE TournamentID = @TournamentID) = 0
    BEGIN
        RAISERROR('Tournament does not exist.', 16, 1);
        RETURN;
    END

    -- Example logic for assigning facility and other details
    SET @FacilityID = 'F1'; -- Example FacilityID
    SET @BookingType = 'Tournament'; 
    SET @StartDateTime = GETDATE(); 
    SET @EndDateTime = DATEADD(HOUR, 3, @StartDateTime); 
    SET @TotalAmountOfPeople = 100;

    -- Check if the user has already booked the tournament
    IF EXISTS (SELECT 1 FROM Bookings WHERE TournamentID = @TournamentID AND UserID = @UserID)
    BEGIN
        RAISERROR('You have already booked this tournament.', 16, 1);
        RETURN;
    END

    -- Insert the booking if the user hasn't booked it yet
    INSERT INTO Bookings (FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
    VALUES (@FacilityID, @UserID, @BookingType, @TournamentID, @StartDateTime, @EndDateTime, @TotalAmountOfPeople);

    -- Update the Tournament table to mark it as booked
    UPDATE Tournaments
    SET ApprovalStatus = 'Approved'  -- Ensure valid value ('Approved' or 'Denied')
    WHERE TournamentID = @TournamentID;

    PRINT 'Tournament booked successfully.';
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
EXECUTE AS USER = 'TO001';  -- Impersonate Tournament Organizer

-- Valid execution of the procedure by the Tournament Organizer
EXEC BookTournament 
    @TournamentID = 'T001';  -- The TournamentID of the tournament to be booked
revert;
