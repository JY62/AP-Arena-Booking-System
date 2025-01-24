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
