-- Use the database
USE APArenaDB;

-- Use the database
USE APArenaDB;


-- Updated stored procedure with simplified user identification
CREATE OR ALTER PROCEDURE BookFacilityForIndividual
    @FacilityID VARCHAR(8),
    @StartDateTime DATETIME,
    @EndDateTime DATETIME,
    @TotalAmountOfPeople INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the current user's name without domain
    DECLARE @CurrentUser NVARCHAR(128) = SYSTEM_USER;
    
    -- Extract UserID directly from the username
    DECLARE @UserID VARCHAR(8) = @CurrentUser;
    
    -- Debugging: Print the UserID
    PRINT 'Current User: ' + @CurrentUser;
    PRINT 'UserID: ' + ISNULL(@UserID, 'NULL');

    -- Verify this is a valid Individual Customer ID format (starts with 'IC')
    IF @UserID NOT LIKE 'IC%'
    BEGIN
        THROW 51000, 'Invalid Individual Customer ID format.', 1;
        RETURN;
    END

    -- Validate inputs
    IF ISDATE(@StartDateTime) = 0 OR ISDATE(@EndDateTime) = 0
    BEGIN
        THROW 51000, 'Invalid date format for StartDateTime or EndDateTime.', 1;
        RETURN;
    END

    IF @TotalAmountOfPeople <= 0
    BEGIN
        THROW 51000, 'TotalAmountOfPeople must be a positive integer.', 1;
        RETURN;
    END

    -- Check for existing bookings during the requested time period
    IF EXISTS (
        SELECT 1 
        FROM Bookings 
        WHERE UserID = @UserID 
        AND (
            (@StartDateTime BETWEEN StartDateTime AND EndDateTime)
            OR
            (@EndDateTime BETWEEN StartDateTime AND EndDateTime)
        )
    )
    BEGIN
        THROW 51000, 'You already have a booking during this time period.', 1;
        RETURN;
    END

    -- Generate the new BookingID
    DECLARE @NewBookingID VARCHAR(8);
    SELECT @NewBookingID = 'B' + RIGHT('00' + CAST(
        (SELECT ISNULL(MAX(CAST(SUBSTRING(BookingID, 2, LEN(BookingID)) AS INT)), 0) 
         FROM Bookings) + 1 AS VARCHAR(7)), 7);

    -- Insert the booking
    INSERT INTO Bookings (
        BookingID,
        FacilityID,
        UserID,
        BookingType,
        TournamentID,
        StartDateTime,
        EndDateTime,
        TotalAmountOfPeople
    )
    VALUES (
        @NewBookingID,
        @FacilityID,
        @UserID,
        'Individual',
        NULL,  -- TournamentID is NULL for individual bookings
        @StartDateTime,
        @EndDateTime,
        @TotalAmountOfPeople
    );
    
    PRINT 'Booking successful. BookingID: ' + @NewBookingID;
END;
GO

-- Testing the Procedure
-- Create the IndividualCustomer role
CREATE ROLE IndividualCustomer;

-- Create a sample login and user for testing
CREATE LOGIN IC005 WITH PASSWORD = '123'; -- Replace with a secure password
CREATE USER IC005 FOR LOGIN IC005;

-- Add the IC004 user to the IndividualCustomer role
EXEC sp_addrolemember 'IndividualCustomer', 'IC005';

-- Grant necessary permissions
GRANT EXECUTE ON dbo.BookFacilityForIndividual TO IndividualCustomer;
GRANT SELECT ON dbo.Bookings TO IndividualCustomer;

-- Log in as IC005 and execute the procedure
EXECUTE AS USER = 'IC005';
EXEC BookFacilityForIndividual 
    @FacilityID = 'F2',  -- Replace with a valid FacilityID
    @StartDateTime = '2024-01-20 14:00:00',
    @EndDateTime = '2024-01-20 16:00:00',
    @TotalAmountOfPeople = 10;

REVERT;
GO

-- Debugging: Print the UserID to check its value
PRINT 'UserID: ' + ISNULL(@UserID, 'NULL');
