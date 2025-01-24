-- Version 2: To handle both TournamentOrganizer (Bulk Booking) and IndividualCustomer (Single booking) 
CREATE OR ALTER PROCEDURE BookFacility
    @FacilityID VARCHAR(8),
    @StartDateTime DATETIME,
    @EndDateTime DATETIME,
    @TotalAmountOfPeople INT,
    @TournamentID VARCHAR(8) = NULL -- Used only if TournamentOrganizer
AS
BEGIN
    SET NOCOUNT ON;

    -- Get the current user's name without domain
    DECLARE @CurrentUser NVARCHAR(128) = SYSTEM_USER;
    DECLARE @UserID VARCHAR(8) = @CurrentUser;
    DECLARE @UserType NVARCHAR(20);
    DECLARE @ApprovalStatus NVARCHAR(20);
    DECLARE @NewBookingID VARCHAR(8);

    -- Debugging: Print the current user
    PRINT 'Current User: ' + @CurrentUser;
    PRINT 'UserID: ' + ISNULL(@UserID, 'NULL');

    -- Determine User Type (IC for Individual Customers, TO for Tournament Organizers)
    IF @UserID LIKE 'IC%'
        SET @UserType = 'IndividualCustomer';
    ELSE IF @UserID LIKE 'TO%'
        SET @UserType = 'TournamentOrganizer';
    ELSE
    BEGIN
        THROW 51000, 'Invalid UserID format. Must start with "IC" or "TO".', 1;
        RETURN;
    END

    -- Validate TotalAmountOfPeople
    IF @TotalAmountOfPeople <= 0
    BEGIN
        THROW 51000, 'TotalAmountOfPeople must be a positive integer.', 1;
        RETURN;
    END

    -- Check specific conditions for TournamentOrganizer
    IF @UserType = 'TournamentOrganizer'
    BEGIN
        IF @TournamentID IS NULL
        BEGIN
            THROW 51000, 'TournamentID must be provided for TournamentOrganizer bookings.', 1;
            RETURN;
        END

        -- Validate Tournament ApprovalStatus
        SELECT @ApprovalStatus = ApprovalStatus
        FROM Tournaments
        WHERE TournamentID = @TournamentID AND OrganizerID = @UserID;

        IF @ApprovalStatus IS NULL
        BEGIN
            THROW 51000, 'TournamentID does not exist or does not belong to the Organizer.', 1;
            RETURN;
        END

        IF @ApprovalStatus <> 'Approved'
        BEGIN
            THROW 51000, 'Tournament is not approved. Cannot book facilities.', 1;
            RETURN;
        END

        -- Check Facility Availability for TournamentOrganizer
        IF EXISTS (
            SELECT 1
            FROM Bookings
            WHERE FacilityID = @FacilityID
            AND (
                (@StartDateTime BETWEEN StartDateTime AND EndDateTime)
                OR
                (@EndDateTime BETWEEN StartDateTime AND EndDateTime)
            )
        )
        BEGIN
            THROW 51000, 'The selected facility is not available during the requested time period.', 1;
            RETURN;
        END
    END

    -- Check specific conditions for IndividualCustomer
    IF @UserType = 'IndividualCustomer'
    BEGIN
        -- Check if the user already has a booking during the requested time
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

        -- Check Facility Availability for IndividualCustomer
        IF EXISTS (
            SELECT 1
            FROM Bookings
            WHERE FacilityID = @FacilityID
            AND (
                (@StartDateTime BETWEEN StartDateTime AND EndDateTime)
                OR
                (@EndDateTime BETWEEN StartDateTime AND EndDateTime)
            )
        )
        BEGIN
            THROW 51000, 'The selected facility is not available during the requested time period.', 1;
            RETURN;
        END
    END

    -- Generate the new BookingID
    SELECT @NewBookingID = 'B' + RIGHT('0000000' + CAST(
        ISNULL(MAX(CAST(SUBSTRING(BookingID, 2, LEN(BookingID)) AS INT)), 0) + 1 AS VARCHAR(7)
    ), 7)
    FROM Bookings;

    -- Insert the booking into the Bookings table
    INSERT INTO Bookings (
        BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime,
        TotalAmountOfPeople
    )
    VALUES (
        @NewBookingID, 
        @FacilityID, 
        @UserID, 
        CASE WHEN @UserType = 'TournamentOrganizer' THEN 'Tournament' ELSE 'Individual' END, 
        @TournamentID, 
        @StartDateTime, 
        @EndDateTime, 
        @TotalAmountOfPeople
    );

    PRINT 'Booking successful. BookingID: ' + @NewBookingID;
END;
GO
