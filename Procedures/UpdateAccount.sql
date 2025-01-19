USE APArenaDB;
GO

CREATE PROCEDURE UpdateAccount
    @UserID VARCHAR(8), -- The ID of the user to be updated
    @FullName NVARCHAR(255) = NULL, -- Plaintext FullName, optional
    @Email VARCHAR(100) = NULL, -- New Email, optional
    @Password NVARCHAR(255) = NULL, -- Plaintext Password, optional
    @PhoneNumber VARCHAR(15) = NULL -- New PhoneNumber, optional
AS
BEGIN
    -- Declare variables to store user roles, validation checks, and current values
    DECLARE @CurrentUserID VARCHAR(8);
    DECLARE @CurrentUserType VARCHAR(50);
    DECLARE @TargetUserType VARCHAR(50);
    DECLARE @LatestBookingStart DATETIME;
    DECLARE @EncryptedFullName VARBINARY(255) = NULL;
    DECLARE @PasswordHash VARBINARY(255) = NULL;
    DECLARE @OriginalEmail VARCHAR(100);
    DECLARE @OriginalPhoneNumber VARCHAR(15);

    -- Retrieve the CurrentUserID from the login context
    SET @CurrentUserID = SUSER_NAME();

    -- Retrieve the user types of the current user and the target user
    SELECT @CurrentUserType = UserType FROM [User] WHERE UserID = @CurrentUserID;
    SELECT @TargetUserType = UserType FROM [User] WHERE UserID = @UserID;

    -- Check if the Current User exists
    IF @CurrentUserType IS NULL
    BEGIN
        RAISERROR('Invalid CurrentUserID.', 16, 1);
        RETURN;
    END

    -- Check if the Target User exists
    IF @TargetUserType IS NULL
    BEGIN
        RAISERROR('Invalid UserID to update.', 16, 1);
        RETURN;
    END

    -- Check permissions based on roles
    IF @CurrentUserType = 'Data Admin'
    BEGIN
        -- Data Admin can update Data Admin or Complex Manager only
        IF @TargetUserType NOT IN ('Data Admin', 'Complex Manager')
        BEGIN
            RAISERROR('Permission denied. Data Admin cannot update this account.', 16, 1);
            RETURN;
        END
    END
    ELSE IF @CurrentUserID <> @UserID
    BEGIN
        -- All other roles can only update their own account
        RAISERROR('Permission denied. You can only update your own account.', 16, 1);
        RETURN;
    END

    -- Additional validation for Tournament Organizers and Individual Customers
    IF @TargetUserType IN ('Tournament Organizer', 'Individual Customers')
    BEGIN
        -- Retrieve the latest booking StartDateTime for the user
        SELECT @LatestBookingStart = MAX(StartDateTime)
        FROM Bookings
        WHERE UserID = @UserID AND StartDateTime > GETDATE();

        -- Check if there is a booking within 24 hours
        IF @LatestBookingStart IS NOT NULL AND DATEDIFF(HOUR, GETDATE(), @LatestBookingStart) <= 24
        BEGIN
            RAISERROR('Account modification is not allowed within 24 hours of the latest booking start time.', 16, 1);
            RETURN;
        END
    END

    -- Retrieve the original (unmasked) values for Email and PhoneNumber
    SELECT 
        @OriginalEmail = Email,
        @OriginalPhoneNumber = PhoneNumber
    FROM [User]
    WHERE UserID = @UserID;

    -- Encrypt FullName if provided
    IF @FullName IS NOT NULL
    BEGIN
        OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
        SET @EncryptedFullName = EncryptByKey(Key_GUID('UserKey'), @FullName);
        CLOSE SYMMETRIC KEY UserKey;
    END

    -- Hash Password if provided
    IF @Password IS NOT NULL
    BEGIN
        SET @PasswordHash = HASHBYTES('SHA2_256', @Password);
    END

    -- Validate input values to prevent storing masked data
    IF @Email IS NOT NULL AND @Email LIKE '%*@%.%'
    BEGIN
        RAISERROR('Invalid input: Masked email cannot be stored.', 16, 1);
        RETURN;
    END

    IF @PhoneNumber IS NOT NULL AND @PhoneNumber LIKE '****%'
    BEGIN
        RAISERROR('Invalid input: Masked phone number cannot be stored.', 16, 1);
        RETURN;
    END

    -- Update the allowed fields, using original unmasked values where necessary
    UPDATE [User]
    SET
        FullName = CASE WHEN @EncryptedFullName IS NOT NULL THEN @EncryptedFullName ELSE FullName END,
        Email = CASE WHEN @Email IS NOT NULL THEN @Email ELSE @OriginalEmail END,
        PasswordHash = CASE WHEN @PasswordHash IS NOT NULL THEN @PasswordHash ELSE PasswordHash END,
        PhoneNumber = CASE WHEN @PhoneNumber IS NOT NULL THEN @PhoneNumber ELSE @OriginalPhoneNumber END
    WHERE UserID = @UserID;
END;


GRANT EXECUTE ON OBJECT::dbo.UpdateAccount TO DataAdmin;
GRANT EXECUTE ON OBJECT::dbo.UpdateAccount TO ComplexManager;
GRANT EXECUTE ON OBJECT::dbo.UpdateAccount TO TournamentOrganizer;
GRANT EXECUTE ON OBJECT::dbo.UpdateAccount TO IndividualCustomer;

-- Testing UpdateAccount Procedure
EXECUTE AS LOGIN = 'DA0001';

EXEC UpdateAccount 
    @UserID = 'DA0001', 
    @FullName = 'Marry Brown',
    @Email = 'admin_marry@example.com', 
    @Password = 'SecurePassword123!', 
    @PhoneNumber = '+60123456789';

REVERT;
