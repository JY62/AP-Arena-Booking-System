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

    -- Declare other variables
    DECLARE @FacilityID NVARCHAR(8);
    DECLARE @BookingType NVARCHAR(50);
    DECLARE @StartDateTime DATETIME;
    DECLARE @EndDateTime DATETIME;
    DECLARE @TotalAmountOfPeople INT;

    -- Example logic for assigning facility and other details (you can modify based on your requirements)
    -- Assuming that we have some logic to assign FacilityID, BookingType, StartDateTime, EndDateTime, and TotalAmountOfPeople
    SET @FacilityID = 'F1'; 
    SET @BookingType = 'Tournament'; -- Example BookingType
    SET @StartDateTime = GETDATE(); -- Example StartDateTime, modify as needed
    SET @EndDateTime = DATEADD(HOUR, 3, @StartDateTime); -- Example EndDateTime, 3 hours after StartDateTime
    SET @TotalAmountOfPeople = 50; -- Example TotalAmountOfPeople, modify as needed

    -- Create a new booking in the Bookings table
    INSERT INTO Bookings (FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
    VALUES (@FacilityID, @UserID, @BookingType, @TournamentID, @StartDateTime, @EndDateTime, @TotalAmountOfPeople);
END;


-- Valid EXEC
EXEC BookTournament @UserID = 'TO001', @TournamentID = 'T001';
-- Invalid tournament ID
EXEC BookTournament @UserID = 'TO001', @TournamentID = 'T007';
