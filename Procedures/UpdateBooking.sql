CREATE PROCEDURE UpdateBooking
    @BookingID VARCHAR(8),
    @FacilityID VARCHAR(8),
    @StartDateTime DATETIME,
    @EndDateTime DATETIME,
    @TotalAmountOfPeople INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate that the current user is the owner of the booking
    IF NOT EXISTS (
        SELECT 1
        FROM Bookings
        WHERE BookingID = @BookingID
          AND UserID = SUSER_SNAME()
    )
    BEGIN
        RAISERROR ('You can only update your own bookings.', 16, 1);
        RETURN;
    END

    -- Validate that TotalAmountOfPeople does not exceed Facility Capacity
    DECLARE @Capacity INT;
    SELECT @Capacity = Capacity
    FROM Facility
    WHERE FacilityID = @FacilityID;

    IF @TotalAmountOfPeople > @Capacity
    BEGIN
        RAISERROR ('Total amount of people exceeds the facility capacity.', 16, 1);
        RETURN;
    END

    -- Validate that the new StartDateTime and EndDateTime do not conflict with existing bookings
    IF EXISTS (
        SELECT 1
        FROM Bookings
        WHERE FacilityID = @FacilityID
          AND BookingID <> @BookingID
          AND (
              (@StartDateTime < EndDateTime AND @EndDateTime > StartDateTime) -- Overlap condition
          )
    )
    BEGIN
        RAISERROR ('The new booking time conflicts with another booking.', 16, 1);
        RETURN;
    END

    -- Update the booking details
    UPDATE Bookings
    SET 
        FacilityID = @FacilityID,
        StartDateTime = @StartDateTime,
        EndDateTime = @EndDateTime,
        TotalAmountOfPeople = @TotalAmountOfPeople
    WHERE BookingID = @BookingID;

    PRINT 'Booking updated successfully.';
END


-- Testing for TO 
-- Create the TournamentOrganizer role
CREATE ROLE TournamentOrganizer;

-- Create the TO001 login and user
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER TO001 FOR LOGIN TO001;

-- Add TO001 user to the DataAdmin role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Grant EXECUTE permission on the procedure to the DataAdmin role
GRANT EXECUTE ON dbo.UpdateBooking TO TournamentOrganizer;

GRANT SELECT ON dbo.Bookings TO TournamentOrganizer;

-- Log in as DA001 and execute the procedure
EXECUTE AS USER = 'TO001';
EXEC UpdateBooking 
    @BookingID = 'B002',
    @FacilityID = 'F1',
    @StartDateTime = '2025-01-20 12:00:00.000',
    @EndDateTime = '2025-01-20 01:00:00.000',
    @TotalAmountOfPeople = 10;

REVERT;

drop procedure UpdateBooking

-- Testing for IC
-- Create the DataAdmin role
CREATE ROLE IndividualCustomer;

-- Create the DA001 login and user
CREATE LOGIN IC001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER IC001 FOR LOGIN IC001;

-- Add DA001 user to the DataAdmin role
EXEC sp_addrolemember 'IndividualCustomer', 'IC001';

-- Grant EXECUTE permission on the procedure to the DataAdmin role
GRANT EXECUTE ON dbo.UpdateBooking TO IndividualCustomer;

GRANT SELECT ON dbo.Bookings TO IndividualCustomer;

-- Log in as DA001 and execute the procedure
EXECUTE AS USER = 'IC001';
EXEC UpdateBooking 
    @BookingID = 'B001',
    @FacilityID = 'F1',
    @StartDateTime = '2025-01-20 10:00:00.000',
    @EndDateTime = '2025-01-20 12:00:00.000',
    @TotalAmountOfPeople = 10;

REVERT;

drop procedure UpdateBooking
