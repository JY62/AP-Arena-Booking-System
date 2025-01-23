CREATE PROCEDURE UpdateBooking
    @BookingID VARCHAR(8),
    @FacilityID VARCHAR(8) = NULL,
    @UserID VARCHAR(8) = NULL,
    @BookingType VARCHAR(20) = NULL,
    @TournamentID VARCHAR(8) = NULL,
    @StartDateTime DATETIME = NULL,
    @EndDateTime DATETIME = NULL,
    @TotalAmountOfPeople INT = NULL
AS
BEGIN
    -- Fetch the logged-in user ID and role
    DECLARE @LoggedInUserID NVARCHAR(128) = SUSER_SNAME();
    DECLARE @Role NVARCHAR(50);
    DECLARE @FacilityCapacity INT;
    DECLARE @AvailabilityStatus INT;

    -- Determine the role of the logged-in user based on the UserID prefix
    IF LEFT(@LoggedInUserID, 2) = 'CM'
        SET @Role = 'ComplexManager';
    ELSE
        SET @Role = 'Other';

    -- Check if the user is a Complex Manager
    IF @Role = 'ComplexManager'
    BEGIN
        -- Validate FacilityID availability status, if provided
        IF @FacilityID IS NOT NULL
        BEGIN
            SELECT @AvailabilityStatus = AvailabilityStatus, 
                   @FacilityCapacity = Capacity
            FROM dbo.Facility
            WHERE FacilityID = @FacilityID;

            IF @AvailabilityStatus IS NULL
            BEGIN
                PRINT 'Facility not found. Update cannot proceed.';
                RETURN;
            END

            IF @AvailabilityStatus = 0
            BEGIN
                PRINT 'Facility not available.';
                RETURN;
            END
        END

        -- Validate TotalAmountOfPeople against Facility capacity, if provided
        IF @TotalAmountOfPeople IS NOT NULL AND @FacilityCapacity IS NOT NULL
        BEGIN
            IF @TotalAmountOfPeople > @FacilityCapacity
            BEGIN
                PRINT 'The amount of people exceeds the facility capacity.';
                RETURN;
            END
        END

        -- Validate UserID if provided
        IF @UserID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.[User] WHERE UserID = @UserID)
            BEGIN
                PRINT 'The provided UserID does not exist in the dbo.[User] table.';
                RETURN;
            END
        END

        -- Update the booking information
        BEGIN TRY
            UPDATE Bookings
            SET 
                FacilityID = ISNULL(@FacilityID, FacilityID),
                UserID = ISNULL(@UserID, UserID),
                BookingType = ISNULL(@BookingType, BookingType),
                TournamentID = ISNULL(@TournamentID, TournamentID),
                StartDateTime = ISNULL(@StartDateTime, StartDateTime),
                EndDateTime = ISNULL(@EndDateTime, EndDateTime),
                TotalAmountOfPeople = ISNULL(@TotalAmountOfPeople, TotalAmountOfPeople)
            WHERE BookingID = @BookingID;

            -- Check if the update affected any rows
            IF @@ROWCOUNT = 0
                PRINT 'No booking found with the specified BookingID.';
            ELSE
                PRINT 'Booking updated successfully.';
        END TRY
        BEGIN CATCH
            PRINT 'An error occurred while updating the booking. Please check your input.';
        END CATCH
    END
    ELSE
    BEGIN
        -- If the user is not a Complex Manager, display a message
        PRINT 'You do not have permission to update bookings.';
    END
END;
GO



-- Testing
-- Create the DataAdmin role
CREATE ROLE ComplexManager;

-- Create the DA001 login and user
CREATE LOGIN CM002 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER CM002 FOR LOGIN CM002;

-- Add DA001 user to the DataAdmin role
EXEC sp_addrolemember 'ComplexManager', 'CM002';

-- Grant EXECUTE permission on the procedure to the DataAdmin role
GRANT EXECUTE ON dbo.UpdateBooking TO ComplexManager;

GRANT SELECT ON dbo.Bookings TO ComplexManager;

-- Log in as DA001 and execute the procedure
EXECUTE AS USER = 'CM002';
EXEC UpdateBooking 
    @BookingID = 'B001',
    @FacilityID = 'F5',
    @UserID = 'IC006',
    @StartDateTime = '2025-01-23 10:00:00',
    @EndDateTime = '2025-01-23 12:00:00',
    @TotalAmountOfPeople = 30;

REVERT;

drop procedure UpdateBooking