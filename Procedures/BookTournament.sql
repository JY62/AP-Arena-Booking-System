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




-- Version 2
CREATE PROCEDURE BookTournament
    @TournamentName NVARCHAR(100) -- Name of the new tournament
AS
BEGIN
    -- Declare variables
    DECLARE @OrganizerID VARCHAR(8);
    DECLARE @ApprovalStatus VARCHAR(20);
    DECLARE @NewTournamentID VARCHAR(8);
    DECLARE @MaxID INT;

    BEGIN TRY
        -- Fetch the OrganizerID and ApprovalStatus from TournamentOrganizer table
        SELECT 
            @OrganizerID = OrganizerID,
            @ApprovalStatus = ApprovalStatus
        FROM 
            TournamentOrganizer
        WHERE 
            OrganizerID = SYSTEM_USER;

        -- Validate OrganizerID exists
        IF @OrganizerID IS NULL
        BEGIN
            THROW 51000, 'OrganizerID does not exist.', 1;
        END

        -- Validate ApprovalStatus
        IF @ApprovalStatus <> 'Approved'
        BEGIN
            THROW 51000, 'ApprovalStatus is not approved. Cannot add tournament.', 1;
        END

        -- Generate the next unique TournamentID
        SELECT 
            @MaxID = ISNULL(MAX(CAST(SUBSTRING(TournamentID, 2, 3) AS INT)), 0)
        FROM 
            Tournaments;

        SET @NewTournamentID = 'T' + RIGHT('000' + CAST(@MaxID + 1 AS VARCHAR(3)), 3);

        -- Insert the new tournament into the Tournaments table
        INSERT INTO Tournaments (TournamentID, OrganizerID, TournamentName, ApprovalStatus)
        VALUES (@NewTournamentID, @OrganizerID, @TournamentName, 'Pending');

        PRINT 'Tournament added successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
