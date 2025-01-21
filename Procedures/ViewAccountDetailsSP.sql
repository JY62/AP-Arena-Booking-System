ALTER PROCEDURE ViewAccountDetails
    @TableName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Detect the current SQL Server login's username
    DECLARE @LoginName VARCHAR(8) = SUSER_SNAME(); 
    DECLARE @UserID VARCHAR(8);

    -- Look up the UserID based on the current login name
    -- Modified to handle Windows Authentication format if present
    SELECT @UserID = UserID 
    FROM [User] 
    WHERE UserID = @LoginName;
	SELECT @UserID AS RetrievedUserID;

    -- If no matching UserID found, return an error message
    IF @UserID IS NULL
    BEGIN
        SELECT 'Access Denied: No matching UserID found for the login. Login: ' + @LoginName AS Message;
        RETURN;
    END

	--Select @Role AS Role;
    DECLARE @Role NVARCHAR(50) = LEFT(@UserID, 2);

    -- Open keys for decryption
    OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

    -- Handle [User] table
    IF @TableName = 'User'
    BEGIN
        IF @Role IN ('DA', 'TO', 'IC')
        BEGIN
            SELECT 
                UserID, UserType, CONVERT(NVARCHAR(255), DecryptByKey(FullName)) AS FullName, Email, PasswordHash, PhoneNumber, RegistrationDate
            FROM [User]
            WHERE UserID = @UserID;  -- Maintains original access control
        END
        ELSE IF @Role = 'CM'
        BEGIN
            SELECT 
                UserID, UserType,
                CASE 
                    WHEN UserID = @UserID THEN CONVERT(NVARCHAR(255), DecryptByKey(FullName)) ELSE '********' 
                END AS FullName,
                CASE 
                    WHEN UserID = @UserID THEN Email ELSE '*****@*****.com' 
                END AS Email,
                CASE 
                    WHEN UserID = @UserID THEN PhoneNumber ELSE '+60********' 
                END AS PhoneNumber,
                RegistrationDate
            FROM [User];
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
        ELSE IF @Role = 'CM'
        BEGIN
            SELECT 
                OrganizerID,
                CASE 
                    WHEN OrganizerID = @UserID THEN CONVERT(VARCHAR(255), DECRYPTBYKEY(BusinessName)) ELSE 'Hidden' 
                END AS BusinessName,
                CASE 
                    WHEN OrganizerID = @UserID THEN BusinessRegistrationNumber ELSE 'Hidden' 
                END AS BusinessRegistrationNumber,
                CASE 
                    WHEN OrganizerID = @UserID THEN CONVERT(VARCHAR(255), DECRYPTBYKEY(Address)) ELSE 'Hidden' 
                END AS Address,
                ApprovalStatus
            FROM TournamentOrganizer;
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message;
        END
    END
    -- Handle [Participants] table
    ELSE IF @TableName = 'Participants'
    BEGIN
		OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
        IF @Role IN ('DA', 'TO', 'IC')
        BEGIN
            SELECT 
                p.ParticipantID, p.BookingID, CONVERT(VARCHAR(255), DECRYPTBYKEY(p.FullName)) AS FullName, p.Email, 
                p.PhoneNumber, p.Age, p.Gender
            FROM Participants p
            INNER JOIN Bookings b ON p.BookingID = b.BookingID
            WHERE b.UserID = @UserID;
        END
        ELSE IF @Role = 'CM'
        BEGIN
            SELECT 
                p.ParticipantID, p.BookingID, 
                CASE 
                    WHEN b.UserID = @UserID THEN CONVERT(VARCHAR(255), DECRYPTBYKEY(p.FullName)) ELSE '********' 
                END AS FullName,
                CASE 
                    WHEN b.UserID = @UserID THEN p.Email ELSE '*****@*****.com'  
                END AS Email,
                CASE 
                    WHEN b.UserID = @UserID THEN p.PhoneNumber ELSE '+60********' 
                END AS PhoneNumber,
                p.Age, 
                p.Gender
            FROM Participants p
            INNER JOIN Bookings b ON p.BookingID = b.BookingID;
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message;
        END
		CLOSE SYMMETRIC KEY ParticipantKey;
    END
    ELSE
    BEGIN
        SELECT 'Invalid Table Name' AS Message;
    END

    -- Close symmetric keys after decryption
    CLOSE SYMMETRIC KEY UserKey;
END;

-- User roles and permissions creation
CREATE ROLE DataAdmin;
CREATE ROLE ComplexManager;
CREATE ROLE TournamentOrganizer;
CREATE ROLE IndividualCustomer;

-- Creating Users
CREATE USER DA001 FOR LOGIN DA001;
CREATE USER CM001 FOR LOGIN CM001;
CREATE USER TO001 FOR LOGIN TO001;
CREATE USER IC001 FOR LOGIN IC001;

-- Create users corresponding to the UserIDs in the [User] table
CREATE LOGIN DA001 WITH PASSWORD = 'yourpassword';
CREATE LOGIN CM001 WITH PASSWORD = 'yourpassword';
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';
CREATE LOGIN IC001 WITH PASSWORD = 'yourpassword';

-- Assign users to roles
EXEC sp_addrolemember 'DataAdmin', 'DA001';
EXEC sp_addrolemember 'ComplexManager', 'CM001';
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';
EXEC sp_addrolemember 'IndividualCustomer', 'IC001';

-- Grant execute permissions to roles
GRANT EXECUTE ON dbo.ViewAccountDetails TO DataAdmin;
GRANT EXECUTE ON dbo.ViewAccountDetails TO ComplexManager;
GRANT EXECUTE ON dbo.ViewAccountDetails TO TournamentOrganizer;
GRANT EXECUTE ON dbo.ViewAccountDetails TO IndividualCustomer;

--Grant Select
GRANT SELECT ON dbo.[User] TO DataAdmin;
GRANT SELECT ON dbo.[User] TO ComplexManager;
GRANT SELECT ON dbo.[User] TO TournamentOrganizer;
GRANT SELECT ON dbo.[User] TO IndividualCustomer;

--Grant Unmasking
GRANT UNMASK TO DataAdmin;
GRANT UNMASK TO ComplexManager;
GRANT UNMASK TO TournamentOrganizer;
GRANT UNMASK TO IndividualCustomer;

-- Grant control on keys to roles
GRANT CONTROL ON SYMMETRIC KEY::UserKey TO DataAdmin;
GRANT CONTROL ON SYMMETRIC KEY::UserKey TO ComplexManager;
GRANT CONTROL ON SYMMETRIC KEY::UserKey TO TournamentOrganizer;
GRANT CONTROL ON SYMMETRIC KEY::UserKey TO IndividualCustomer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO DataAdmin;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO ComplexManager;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO IndividualCustomer;

EXECUTE AS USER = 'IC001';

-- For the logged-in user, view their own account in the 'User' table
EXEC ViewAccountDetails @TableName = 'User';

-- For the logged-in user, view their own account in the 'TournamentOrganizer' table
EXEC ViewAccountDetails @TableName = 'TournamentOrganizer';

-- For the logged-in user, view their own account in the 'Participants' table
EXEC ViewAccountDetails @TableName = 'Participants';

REVERT;