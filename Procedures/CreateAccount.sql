USE APArenaDB;
GO

-- Create Account in User Table
CREATE PROCEDURE CreateAccount
    @FullName NVARCHAR(255),
    @Email VARCHAR(100),
    @PhoneNumber VARCHAR(15),
	@Password NVARCHAR(255) 
AS
BEGIN
    -- Variable declarations
    DECLARE @UserID VARCHAR(8);
    DECLARE @UserType VARCHAR(50);
    DECLARE @EncryptedFullName VARBINARY(255);
    DECLARE @HashedPassword VARBINARY(255);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Retrieve the UserID and Password from the current login context
        SET @UserID = SUSER_NAME();

        -- Determine UserType based on UserID prefix
        SET @UserType = 
            CASE 
                WHEN @UserID LIKE 'DA%' THEN 'Data Admin'
                WHEN @UserID LIKE 'CM%' THEN 'Complex Manager'
                WHEN @UserID LIKE 'TO%' THEN 'Tournament Organizer'
                WHEN @UserID LIKE 'IC%' THEN 'Individual Customers'
                ELSE NULL
            END;

        -- Validate UserType
        IF @UserType IS NULL
            THROW 50001, 'Invalid UserType based on UserID.', 1;

	    -- Hash the provided password using SHA2_256
        SET @HashedPassword = HASHBYTES('SHA2_256', @Password);

		-- Create symmetric key for encryption if not created yet
		-- CREATE SYMMETRIC KEY UserKey WITH ALGORITHM = AES_256 ENCRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

        -- Encrypt FullName
		OPEN SYMMETRIC KEY UserKey
        DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
        SET @EncryptedFullName = EncryptByKey(Key_GUID('UserKey'), @FullName);

		-- Close the symmetric key
        CLOSE SYMMETRIC KEY UserKey;

        -- Insert user information into the User table
        INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber)
        VALUES (@UserID, @UserType, @EncryptedFullName, @Email, @HashedPassword, @PhoneNumber);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'UserKey')
            CLOSE SYMMETRIC KEY UserKey;
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Grant EXECUTE permission on the CreateAccount procedure to all roles
GRANT EXECUTE ON OBJECT::dbo.CreateAccount TO DataAdmin;
GRANT EXECUTE ON OBJECT::dbo.CreateAccount TO TournamentOrganizer;
GRANT EXECUTE ON OBJECT::dbo.CreateAccount TO IndividualCustomer;
GO

-- Switch context to the new login (Generated from Login Creation)
EXECUTE AS LOGIN = 'DA0001';

-- Check the current login context
SELECT SUSER_NAME() AS CurrentUser, SYSTEM_USER AS SystemUser;

-- Execute the CreateAccount procedure to insert user information
EXEC CreateAccount 
    @FullName = 'John Doe', -- Full name of the user
    @Email = 'johndoe@example.com', -- User's email address
    @PhoneNumber = '+60123456789', -- User's phone number
	@Password = 'SecurePassword123!' -- User's password

-- Query the User table to verify the inserted data
-- Open the symmetric key first
OPEN SYMMETRIC KEY UserKey
DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

-- Select and decrypt the data
SELECT 
    UserID,
    UserType,
    CONVERT(NVARCHAR(255), DecryptByKey(FullName)) AS DecryptedFullName,
    Email,
    PhoneNumber,
    RegistrationDate
FROM [User];

-- Close the symmetric key
CLOSE SYMMETRIC KEY UserKey;

REVERT