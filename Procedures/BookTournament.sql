CREATE PROCEDURE BookTournament
    @FacilityIDs NVARCHAR(MAX),       -- Comma-separated FacilityIDs for bulk booking
    @BookingIDPrefix NVARCHAR(50)     -- Prefix for generating unique BookingIDs
AS
BEGIN
    -- Declare necessary variables
    DECLARE @UserID NVARCHAR(50);
    DECLARE @FacilityID NVARCHAR(8);
    DECLARE @BookingID NVARCHAR(50);
    DECLARE @TournamentID NVARCHAR(8);

    -- Set the current UserID based on the login user
    SET @UserID = SUSER_NAME();

    -- Validate if the user has an approved status in the TournamentOrganizer table
    IF NOT EXISTS (
        SELECT 1 
        FROM TournamentOrganizer 
        WHERE OrganizerID = @UserID 
          AND ApprovalStatus = 'Approved'
    )
    BEGIN
        RAISERROR('Your approval status is not approved. You cannot make a booking.', 16, 1);
        RETURN;
    END

      -- Generate a new TournamentID based on the current count in the Tournaments table
    SELECT @TournamentID = CONCAT('T', FORMAT(ISNULL(MAX(CAST(SUBSTRING(TournamentID, 2, LEN(TournamentID) - 1) AS INT)), 0) + 1, '000'))
    FROM Tournaments;

    -- Split the comma-separated FacilityIDs into a table
    DECLARE @FacilityTable TABLE (FacilityID NVARCHAR(8));
    INSERT INTO @FacilityTable (FacilityID)
    SELECT value FROM STRING_SPLIT(@FacilityIDs, ',');

    -- Loop through each FacilityID
    DECLARE FacilityCursor CURSOR FOR
        SELECT FacilityID FROM @FacilityTable;

    OPEN FacilityCursor;
    FETCH NEXT FROM FacilityCursor INTO @FacilityID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Validate if the facility is available
        IF EXISTS (
            SELECT 1
            FROM Bookings
            WHERE FacilityID = @FacilityID
              AND TournamentID = @TournamentID
        )
        BEGIN
            RAISERROR('Facility %s is not available for the selected tournament.', 16, 1, @FacilityID);
            RETURN;
        END

        -- Generate a unique BookingID for each facility
        SET @BookingID = @BookingIDPrefix;

        -- Validate if the BookingID already exists
        IF EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID)
        BEGIN
            RAISERROR('The BookingID %s already exists. Please use a unique BookingID.', 16, 1, @BookingID);
            RETURN;
        END

        -- Insert the booking if all validations pass
        INSERT INTO Bookings (BookingID, FacilityID, UserID, BookingType, TournamentID, TotalAmountOfPeople)
        VALUES (@BookingID, @FacilityID, @UserID, 'Tournament', @TournamentID, 100);

        FETCH NEXT FROM FacilityCursor INTO @FacilityID;
    END

    CLOSE FacilityCursor;
    DEALLOCATE FacilityCursor;

    -- Update the Tournament table to mark it as pending
    INSERT INTO Tournaments (TournamentID, OrganizerID, ApprovalStatus)
    VALUES (@TournamentID, @UserID, 'PENDING');
END;
GO
