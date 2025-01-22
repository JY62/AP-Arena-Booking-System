CREATE OR ALTER PROCEDURE ViewBooking
AS
BEGIN
    SET NOCOUNT ON;
    -- Declare variables
    DECLARE @Username NVARCHAR(8);
    DECLARE @UserPrefix NVARCHAR(2);
    -- Get the login user's username
    SET @Username = SYSTEM_USER;
    -- Extract the first two characters of the username
    SET @UserPrefix = LEFT(@Username, 2);
    -- Check the prefix and execute the appropriate query
    IF @UserPrefix = 'TO'
    BEGIN
        -- Tournament Organizer: Join Bookings with Tournaments table
        SELECT 
            B.BookingID, B.FacilityID, B.UserID, B.BookingType, B.TournamentID, B.StartDateTime,
            B.EndDateTime, B.TotalAmountOfPeople, T.TournamentName, T.ApprovalStatus
        FROM Bookings B INNER JOIN Tournaments T
        ON B.TournamentID = T.TournamentID
        WHERE B.UserID = @Username;
    END
    ELSE IF @UserPrefix = 'IC'
    BEGIN
        -- Individual Customer: Display only Bookings table data
        SELECT 
            BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime,
            EndDateTime, TotalAmountOfPeople
        FROM Bookings 
		WHERE UserID = @Username;
    END
    ELSE
        -- Handle invalid prefixes or unauthorized users
        THROW 51000, 'You do not have permission to view bookings.', 1;
END;
GO


-- Testing
GRANT EXECUTE ON OBJECT::dbo.ViewBooking TO TournamentOrganizer
GRANT EXECUTE ON OBJECT::dbo.ViewBooking TO IndividualCustomer
-- Case 1: Tournament Organizer
EXECUTE AS USER = 'TO0001'; -- Log in as a Tournament Organizer
EXEC ViewBooking;
REVERT; -- Revert to the original login

-- Case 2: Individual Customer
EXECUTE AS USER = 'IC0001'; -- Log in as an Individual Customer
EXEC ViewBooking;
REVERT; -- Revert to the original login

-- Case 3: Unauthorized Use
EXECUTE AS USER = 'CM001'; -- Log in as an unauthorized user
EXEC ViewBooking; -- Error is thrown
REVERT; -- Revert to the original login


