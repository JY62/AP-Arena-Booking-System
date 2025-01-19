USE APArenaDB;
GO

USE APArenaDB;
GO

-- Start by granting UNMASK permission temporarily to the current user session
-- This is done inside the procedure, granting it only for the duration of the procedure
CREATE OR ALTER PROCEDURE AddParticipants
    @BookingID VARCHAR(8),
    @FullName VARCHAR(100),
    @Email VARCHAR(100),
    @PhoneNumber VARCHAR(15),
    @Age INT,
    @Gender VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
    DECLARE @TotalParticipants INT;
    DECLARE @MaxParticipants INT;
    DECLARE @NewParticipantID VARCHAR(8);
    DECLARE @UserID NVARCHAR(128);
    DECLARE @GrantSQL NVARCHAR(MAX);
    DECLARE @RevokeSQL NVARCHAR(MAX);

    -- Get the current user executing the procedure
    SET @UserID = SYSTEM_USER;

    -- Build the dynamic SQL for granting UNMASK permission
    SET @GrantSQL = N'GRANT UNMASK TO ' + QUOTENAME(@UserID);

    -- Temporarily grant the UNMASK permission to the current user session
    EXEC sp_executesql @GrantSQL;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate user permissions
        IF NOT EXISTS (
            SELECT 1 
            FROM sys.database_principals 
            WHERE name = @UserID 
            AND (
                IS_MEMBER('TournamentOrganizer') = 1 
                OR IS_MEMBER('IndividualCustomer') = 1
            )
        )
        BEGIN
            THROW 51000, 'User does not have required permissions.', 1;
        END;

        -- Check if the BookingID belongs to the current user
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Bookings WITH (NOLOCK)
            WHERE BookingID = @BookingID 
            AND UserID = @UserID
        )
        BEGIN
            THROW 51000, 'This booking does not belong to the current user.', 1;
        END;

        -- Get maximum participants allowed for this booking
        SELECT @MaxParticipants = TotalAmountOfPeople
        FROM dbo.Bookings WITH (NOLOCK)
        WHERE BookingID = @BookingID;

        -- Count current participants
        SELECT @TotalParticipants = COUNT(*)
        FROM dbo.Participants WITH (NOLOCK)
        WHERE BookingID = @BookingID;

        -- Check if booking is full
        IF @TotalParticipants >= @MaxParticipants
        BEGIN
            THROW 51000, 'This booking has reached its maximum participant capacity.', 1;
        END;

        -- Generate new ParticipantID
        SET @NewParticipantID = 'P' + RIGHT('0000' + CAST(
            (SELECT ISNULL(MAX(CAST(SUBSTRING(ParticipantID, 2, LEN(ParticipantID)) AS INT)), 0) + 1
            FROM dbo.Participants) AS VARCHAR), 3);

        -- Ensure the ParticipantID is unique
        WHILE EXISTS (SELECT 1 FROM dbo.Participants WHERE ParticipantID = @NewParticipantID)
        BEGIN
            SET @NewParticipantID = 'P' + RIGHT('0000' + CAST(
                (SELECT ISNULL(MAX(CAST(SUBSTRING(ParticipantID, 2, LEN(ParticipantID)) AS INT)), 0) + 1
                FROM dbo.Participants) AS VARCHAR), 3);
        END;

        -- Insert new participant
        INSERT INTO Participants (
            ParticipantID,
            BookingID,
            FullName,
            Email,
            PhoneNumber,
            Age,
            Gender
        )
        VALUES (
            @NewParticipantID,
            @BookingID,
			CONVERT(VARBINARY(255), @FullName),
            @Email,
            @PhoneNumber,
            @Age,
            @Gender
        );

        COMMIT TRANSACTION;
        
        SELECT 'Participant added successfully. ParticipantID: ' + @NewParticipantID AS Result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;

    -- Build the dynamic SQL for revoking UNMASK permission
    SET @RevokeSQL = N'REVOKE UNMASK FROM ' + QUOTENAME(@UserID);

    -- Revoke the UNMASK permission after the procedure completes
    EXEC sp_executesql @RevokeSQL;

END;
GO




----------------------------------------------------------------
-- Step 1: Create the IndividualCustomer role
CREATE ROLE IndividualCustomer;

-- Step 2: Create a sample login and user for testing
CREATE LOGIN IC006 WITH PASSWORD = '123'; -- Replace with a secure password
CREATE USER IC006 FOR LOGIN IC006;

-- Step 3: Add the user to the IndividualCustomer role
EXEC sp_addrolemember 'IndividualCustomer', 'IC006';

-- Step 4: Grant necessary permissions
GRANT EXECUTE ON dbo.AddParticipants TO IndividualCustomer;
GRANT SELECT ON dbo.Bookings TO IndividualCustomer;
GRANT SELECT, INSERT ON dbo.Participants TO IndividualCustomer;

-- Step 5: Log in as IC005 and test the AddParticipants procedure
EXECUTE AS USER = 'IC006';

EXEC AddParticipants 
    @BookingID = 'B004', -- Replace with a valid BookingID
    @FullName = 'Charlie Brown', 
    @Email = 'charlie.brown@example.com', 
    @PhoneNumber = '+60123456789', 
    @Age = 28, 
    @Gender = 'Male';

REVERT;
GO


--------------------------------------------------------------------- 
-- Step 1: Create the TournamentOrganizer role
CREATE ROLE TournamentOrganizer;

-- Step 2: Create a sample login and user for testing
CREATE LOGIN TO002 WITH PASSWORD = '123'; -- Replace with a secure password
CREATE USER TO002 FOR LOGIN TO002;

-- Step 3: Add the user to the TournamentOrganizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO002';

-- Step 4: Grant necessary permissions
GRANT EXECUTE ON dbo.AddParticipants TO TournamentOrganizer;
GRANT SELECT ON dbo.Bookings TO TournamentOrganizer;
GRANT SELECT, INSERT ON dbo.Participants TO TournamentOrganizer;

-- Step 5: Log in as TO002 and test the AddParticipants procedure
EXECUTE AS USER = 'TO002';

EXEC AddParticipants 
    @BookingID = 'B013', -- Replace with a valid BookingID
    @FullName = 'David Smith', 
    @Email = 'david.smith@example.com', 
    @PhoneNumber = '+60198765432', 
    @Age = 35, 
    @Gender = 'Male';

REVERT;
GO

SELECT ParticipantID FROM dbo.Participants;



