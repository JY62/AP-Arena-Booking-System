this is my entire code but it still returns with the access denied message:

-- Create the ViewAccountDetails2 procedure
CREATE PROCEDURE ViewAccountDetails2
    @TableName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Detect the current SQL Server login's username
    DECLARE @LoginName NVARCHAR(50) = SUSER_SNAME(); -- Get the current login name
    DECLARE @UserID NVARCHAR(50);

    -- Look up the UserID based on the current login name
    SELECT @UserID = UserID 
    FROM [User] 
    WHERE UserID = @LoginName;  -- Match login name with UserID

    -- If no matching UserID found, return an error message
    IF @UserID IS NULL
    BEGIN
        SELECT 'Access Denied: No matching UserID found for the login.' AS Message;
        RETURN;
    END

    DECLARE @Role NVARCHAR(50) = LEFT(@UserID, 2);

    -- Open keys for decryption
    OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
    OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

    -- Handle [User] table
    IF @TableName = 'User'
    BEGIN
        IF @Role IN ('DA', 'TO', 'IC')
        BEGIN
            SELECT 
                UserID, 
                UserType, 
                CONVERT(VARCHAR(255), DECRYPTBYKEY(FullName)) AS FullName, -- Decrypt FullName
                Email, 
                PasswordHash, -- Return the hashed password
                PhoneNumber, 
                RegistrationDate
            FROM [User]
            WHERE UserID = @UserID;
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message;
        END
    END
    -- Handle [TournamentOrganizer] table
    ELSE IF @TableName = 'TournamentOrganizer'
    BEGIN
        IF @Role = 'TO'
        BEGIN
            SELECT 
                OrganizerID, 
                CONVERT(VARCHAR(255), DECRYPTBYKEY(BusinessName)) AS BusinessName, -- Decrypt BusinessName
                BusinessRegistrationNumber, 
                CONVERT(VARCHAR(255), DECRYPTBYKEY(Address)) AS Address, -- Decrypt Address
                ApprovalStatus
            FROM TournamentOrganizer
            WHERE OrganizerID = @UserID;
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message;
        END
    END
    -- Handle [Participants] table
    ELSE IF @TableName = 'Participants'
    BEGIN
        IF @Role IN ('DA', 'TO', 'IC')
        BEGIN
            SELECT 
                p.ParticipantID, 
                p.BookingID, 
                CONVERT(VARCHAR(255), DECRYPTBYKEY(p.FullName)) AS FullName, -- Decrypt FullName
                p.Email, 
                p.PhoneNumber, 
                p.Age, 
                p.Gender
            FROM Participants p
            INNER JOIN Bookings b ON p.BookingID = b.BookingID
            WHERE b.UserID = @UserID;
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message;
        END
    END
    ELSE
    BEGIN
        SELECT 'Invalid Table Name' AS Message;
    END

    -- Close symmetric keys after decryption
    CLOSE SYMMETRIC KEY UserKey;
    CLOSE SYMMETRIC KEY ParticipantKey;
END;


-- Testing
-- Create the DataAdmin role
CREATE ROLE DataAdmin;

-- Create the DA001 login and user
CREATE LOGIN DA001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER DA001 FOR LOGIN DA001;

-- Add DA001 user to the DataAdmin role
EXEC sp_addrolemember 'DataAdmin', 'DA001';

-- Grant EXECUTE permission on the procedure to the DataAdmin role
GRANT EXECUTE ON dbo.ViewAccountDetails2 TO DataAdmin;

GRANT SELECT ON dbo.[User] TO DataAdmin;

-- Grant control on the symmetric keys to the DataAdmin role
GRANT CONTROL ON SYMMETRIC KEY::UserKey TO DataAdmin;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO DataAdmin;

-- Log in as DA001 and execute the procedure
EXECUTE AS USER = 'DA001';
EXEC ViewAccountDetails2 @TableName = 'User';

REVERT;
