-- Create database
CREATE DATABASE APArenaDB;

-- Use the database
USE APArenaDB;

-- Create symmetric key for encryption
CREATE SYMMETRIC KEY UserKey
WITH ALGORITHM = AES_256
ENCRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

-- Create the User table
CREATE TABLE [User] (
    UserID VARCHAR(8) PRIMARY KEY CHECK (UserID LIKE 'DA%' OR UserID LIKE 'CM%' OR UserID LIKE 'TO%' OR UserID LIKE 'IC%'), -- Must be either prefix
    UserType VARCHAR(50) CHECK (UserType IN ('Data Admin', 'Complex Manager', 'Tournament Organizer', 'Individual Customers')), -- Must be either type
    FullName VARBINARY(255),
    Email VARCHAR(100) UNIQUE CHECK (Email LIKE '%_@__%.__%'), -- Follow email format
    PasswordHash VARBINARY(255),
    PhoneNumber VARCHAR(15) CHECK (PhoneNumber LIKE '+60%'), -- Follow Malaysia country code (+60)
    RegistrationDate DATETIME,
    Status VARCHAR(20) CHECK (Status IN ('Active', 'Inactive')), -- Must be either status
);

-- Add dynamic masking for sensitive attributes
ALTER TABLE [User]
    ALTER COLUMN UserID ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE [User]
    ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE [User]
    ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = 'partial(0,"+60",0)');

-- Logging DML Changes on User Table
CREATE TABLE UsersHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    UserID VARCHAR(8),
    UserType VARCHAR(50),
    FullName VARBINARY(255),
    Email VARCHAR(100),
    PasswordHash VARBINARY(255),
    PhoneNumber VARCHAR(15),
    RegistrationDate DATETIME,
    Status VARCHAR(20),
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_User_Audit
ON [User]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	-- Open the symmetric key for encryption and decryption
    -- Log inserted records (INSERT)
    INSERT INTO UsersHistory (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status, OperationType)
    SELECT UserID, UserType, ENCRYPTBYKEY(KEY_GUID('UserKey'), FullName), Email, PasswordHash, PhoneNumber, RegistrationDate, Status, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO UsersHistory (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status, OperationType)
    SELECT i.UserID, i.UserType, ENCRYPTBYKEY(KEY_GUID('UserKey'), i.FullName), i.Email, i.PasswordHash, i.PhoneNumber, i.RegistrationDate, i.Status, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.UserID = d.UserID
    WHERE i.UserID IS NOT NULL;

    -- Log deleted records (DELETE)
    INSERT INTO UsersHistory (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status, OperationType)
    SELECT UserID, UserType, ENCRYPTBYKEY(KEY_GUID('UserKey'), FullName), Email, PasswordHash, PhoneNumber, RegistrationDate, Status, 'DELETE'
    FROM deleted;

    -- Close the symmetric key
    --CLOSE SYMMETRIC KEY UserKey;
END;
GO


-- Insert sample records into the User table
OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

-- Data Admin accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status)
VALUES
('DA001', 'Data Admin', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Alice Tan'), 'alice.tan@example.com', HASHBYTES('SHA2_256', 'StrongP@ss1'), '+60123456789', GETDATE(), 'Active'),
('DA002', 'Data Admin', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Bob Lim'), 'bob.lim@example.com', HASHBYTES('SHA2_256', 'Str0ngP@ss2'), '+60129876543', GETDATE(), 'Active');

-- Complex Manager account
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status)
VALUES
('CM001', 'Complex Manager', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Charles Ng'), 'charles.ng@example.com', HASHBYTES('SHA2_256', 'CmplxM@n1'), '+60134567890', GETDATE(), 'Active');

-- Tournament Organizer accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status)
VALUES
('TO001', 'Tournament Organizer', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Diana Wong'), 'diana.wong@example.com', HASHBYTES('SHA2_256', 'T0urn@ment1'), '+60145678901', GETDATE(), 'Active'),
('TO002', 'Tournament Organizer', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Edward Lee'), 'edward.lee@example.com', HASHBYTES('SHA2_256', 'T0urn@ment2'), '+60156789012', GETDATE(), 'Active');

-- Individual Customer accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate, Status)
VALUES
('IC001', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Fiona Tan'), 'fiona.tan@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss1'), '+60167890123', GETDATE(), 'Active'),
('IC002', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'George Lim'), 'george.lim@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss2'), '+60178901234', GETDATE(), 'Inactive');

-- Close the symmetric key after the operation
CLOSE SYMMETRIC KEY UserKey;

