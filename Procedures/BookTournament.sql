-- BookTournament Procedure 
CREATE PROCEDURE BookTournament
    @UserID NVARCHAR(50),          
    @TournamentID NVARCHAR(8)               
AS
BEGIN
    -- Validate if the tournament exists and is approved
    IF (SELECT COUNT(*) 
        FROM Tournaments 
        WHERE TournamentID = @TournamentID 
        AND ApprovalStatus = 'Approved') = 0
    BEGIN
        RAISERROR('Tournament does not exist or is not approved for booking.', 16, 1);
        RETURN;
    END

    -- Allow Tournament Organizer to view available tournaments
    SELECT TournamentID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus
    FROM Tournaments
    WHERE ApprovalStatus = 'Approved';

    -- Declare other variables for booking details
    DECLARE @FacilityID NVARCHAR(8);
    DECLARE @BookingType NVARCHAR(50);
    DECLARE @StartDateTime DATETIME;
    DECLARE @EndDateTime DATETIME;
    DECLARE @TotalAmountOfPeople INT;

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
GRANT SELECT ON dbo.BookTournament TO TournamentOrganizer;

-- Valid EXEC (Tournament Organizer can book a tournament)
EXECUTE AS USER = 'TO001';
EXEC BookTournament @UserID = 'TO001', @TournamentID = T001;
REVERT;

-- Invalid EXEC (Non-Tournament Organizer trying to book a tournament)
EXECUTE AS USER = 'DA001';
EXEC BookTournament @UserID = 'TO001', @TournamentID = 1;
REVERT;

drop procedure BookTournament
