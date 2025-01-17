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
    UserType VARCHAR(50) NOT NULL CHECK (UserType IN ('Data Admin', 'Complex Manager', 'Tournament Organizer', 'Individual Customers')), -- Must be either type
    FullName VARBINARY(255) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE CHECK (Email LIKE '%_@__%.__%'), -- Follow email format
    PasswordHash VARBINARY(255) NOT NULL,
    PhoneNumber VARCHAR(15) NOT NULL CHECK (PhoneNumber LIKE '+60%'), -- Follow Malaysia country code (+60)
    RegistrationDate DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Active', 'Inactive')), -- Must be either status
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


-- Creating Tournament Organizer Table
CREATE TABLE TournamentOrganizer (
	OrganizerID VARCHAR(8) PRIMARY KEY CHECK (OrganizerID LIKE 'TO%'),
	BusinessName VARBINARY(255) NOT NULL,
	BusinessRegistrationNumber VARCHAR(12) NOT NULL CHECK (
        BusinessRegistrationNumber LIKE '[1-9][0-9][0-9][0-9][0][1-6][0-9][0-9][0-9][0-9][0-9][0-9]'
    ), 
	Address VARBINARY(255) NOT NULL,
	ApprovalStatus VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (ApprovalStatus IN ('Approved', 'Pending', 'Denied')),
	CONSTRAINT FK_Organizer_User FOREIGN KEY (OrganizerID) REFERENCES [User](UserID)
);
GO

-- Add dynamic masking for sensitive attributes
ALTER TABLE TournamentOrganizer
    ALTER COLUMN OrganizerID ADD MASKED WITH (FUNCTION = 'default()');

-- Add dynamic masking to the BusinessRegistrationNumber column
ALTER TABLE TournamentOrganizer
	ALTER COLUMN BusinessRegistrationNumber ADD MASKED WITH (FUNCTION = 'partial(4,"****",4)');

-- Logging DML Changes on User Table
CREATE TABLE TournamentOrganizerHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    OrganizerID VARCHAR(8),
    BusinessName VARBINARY(255),
    BusinessRegistrationNumber VARCHAR(12),
    Address VARBINARY(255),
    ApprovalStatus VARCHAR(20),
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_TournamentOrganizer_Audit
ON TournamentOrganizer
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO TournamentOrganizerHistory (OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus, OperationType)
    SELECT OrganizerID, ENCRYPTBYKEY(KEY_GUID('UserKey'), BusinessName), BusinessRegistrationNumber, ENCRYPTBYKEY(KEY_GUID('UserKey'), Address), ApprovalStatus, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO TournamentOrganizerHistory (OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus, OperationType)
    SELECT i.OrganizerID, ENCRYPTBYKEY(KEY_GUID('UserKey'), i.BusinessName), i.BusinessRegistrationNumber, ENCRYPTBYKEY(KEY_GUID('UserKey'), i.Address), 
	i.ApprovalStatus, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.OrganizerID = d.OrganizerID
    WHERE i.OrganizerID IS NOT NULL;

    -- Log deleted records (DELETE)
    INSERT INTO TournamentOrganizerHistory (OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus, OperationType)
    SELECT OrganizerID, ENCRYPTBYKEY(KEY_GUID('UserKey'), BusinessName), BusinessRegistrationNumber, ENCRYPTBYKEY(KEY_GUID('UserKey'), Address), ApprovalStatus, 'DELETE'
    FROM deleted;
END;
GO


-- Creating Facility Table
CREATE TABLE Facility (
    FacilityID VARCHAR(8) PRIMARY KEY CHECK (FacilityID LIKE 'F%'),
    FacilityType VARCHAR(50) NOT NULL CHECK (FacilityType IN ('Volleyball court', 'Basketball court', 'Badminton court', 'Tennis court', 
                                                     'Swimming pool', 'Gym')),
    FacilityName VARCHAR(100) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0 AND Capacity <= 9999),
    RatePerHour DECIMAL(10,2) NOT NULL CHECK (RatePerHour >= 0),
    AvailabilityStatus BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE FacilitiesHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    FacilityID VARCHAR(8),
    FacilityType VARCHAR(50),
    FacilityName VARCHAR(100),
    Capacity INT,
    RatePerHour DECIMAL(10,2),
    AvailabilityStatus BIT,
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER trg_Facility_Audit
ON Facility
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO FacilitiesHistory (FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus, OperationType)
    SELECT FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO FacilitiesHistory (FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus, OperationType)
    SELECT i.FacilityID, i.FacilityType, i.FacilityName, i.Capacity, i.RatePerHour, i.AvailabilityStatus, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.FacilityID = d.FacilityID
    WHERE i.FacilityID IS NOT NULL;

    -- Log deleted records (DELETE)
    INSERT INTO FacilitiesHistory (FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus, OperationType)
    SELECT FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus, 'DELETE'
    FROM deleted;
END;
GO

-- Creating Tournament Table
CREATE TABLE Tournaments (
    TournamentID VARCHAR(8) PRIMARY KEY CHECK (TournamentID LIKE 'T%'), 
    OrganizerID VARCHAR(8) NOT NULL CHECK (OrganizerID LIKE 'TO%'), -- 'TO' prefix for Tournament Organizer
    TournamentName VARCHAR(100) NOT NULL, 
    StartDateTime DATETIME NOT NULL, -- Start date and time of the tournament
    EndDateTime DATETIME NOT NULL, -- End date and time of the tournament
	ApprovalStatus VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (ApprovalStatus IN ('Approved', 'Pending', 'Rejected')),
    FOREIGN KEY (OrganizerID) REFERENCES TournamentOrganizer(OrganizerID) -- References OrganizerID in Users table
);

-- Add dynamic masking for sensitive attributes
ALTER TABLE Tournaments
    ALTER COLUMN OrganizerID ADD MASKED WITH (FUNCTION = 'default()');

-- Create TournamentsHistory Table
CREATE TABLE TournamentsHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    TournamentID VARCHAR(8),
    OrganizerID VARCHAR(8),
    TournamentName VARCHAR(100),
    StartDateTime DATETIME,
    EndDateTime DATETIME,
	ApprovalStatus VARCHAR(20),
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger for Logging DML Changes on Tournaments Table
CREATE TRIGGER trg_Tournaments_Audit
ON Tournaments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus, OperationType)
    SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus, OperationType)
    SELECT i.TournamentID, i.OrganizerID, i.TournamentName, i.StartDateTime, i.EndDateTime, i.ApprovalStatus, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.TournamentID = d.TournamentID;

    -- Log deleted records (DELETE)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus, OperationType)
    SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, ApprovalStatus, 'DELETE'
    FROM deleted;
END;
GO

-- Create Booking Table
CREATE TABLE Bookings (
    BookingID VARCHAR(8) PRIMARY KEY CHECK (BookingID LIKE 'APA%'), -- Prefix 'APA' 
    FacilityID VARCHAR(8) NOT NULL CHECK (FacilityID LIKE 'F%'), -- 'F' prefix for FacilityID
    UserID VARCHAR(8) NOT NULL CHECK (UserID LIKE 'DA%' OR UserID LIKE 'CM%' OR UserID LIKE 'TO%' OR UserID LIKE 'IC%'), -- Prefixes for users
    BookingType VARCHAR(20) CHECK (BookingType IN ('Tournament', 'Individual')), -- Validates either 'Tournament' or 'Individual'
    TournamentID VARCHAR(8) NULL,
    StartDateTime DATETIME NOT NULL, 
    EndDateTime DATETIME NOT NULL, 
    TotalAmountOfPeople INT NOT NULL, 
    FOREIGN KEY (FacilityID) REFERENCES Facility(FacilityID), 
    FOREIGN KEY (UserID) REFERENCES [User](UserID), 
    FOREIGN KEY (TournamentID) REFERENCES Tournaments(TournamentID)
);
GO

-- Trigger to enforce the validation logic for TournamentID based on BookingType
CREATE TRIGGER trg_ValidateTournamentID
ON Bookings
AFTER INSERT, UPDATE
AS
BEGIN
    -- Check if BookingType is 'Tournament', and TournamentID does not start with 'T'
    -- Or if BookingType is 'Individual', and TournamentID is not NULL
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE (BookingType = 'Tournament' AND TournamentID NOT LIKE 'T%')
           OR (BookingType = 'Individual' AND TournamentID IS NOT NULL)
    )
    BEGIN
        RAISERROR('Invalid TournamentID value for the specified BookingType.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Add dynamic masking for sensitive attributes
ALTER TABLE Bookings
    ALTER COLUMN BookingID ADD MASKED WITH (FUNCTION = 'default()');

-- Add dynamic masking for sensitive attributes
ALTER TABLE Bookings
    ALTER COLUMN UserID ADD MASKED WITH (FUNCTION = 'default()');

-- Create BookingsHistory Table
CREATE TABLE BookingsHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    BookingID VARCHAR(8),
    FacilityID VARCHAR(8),
    UserID VARCHAR(8),
    BookingType VARCHAR(20),
    TournamentID VARCHAR(8) NULL,
    StartDateTime DATETIME,
    EndDateTime DATETIME,
    TotalAmountOfPeople INT NULL,
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger for Logging DML Changes on Bookings Table
CREATE TRIGGER trg_Bookings_Audit
ON Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, OperationType)
    SELECT BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, OperationType)
    SELECT i.BookingID, i.FacilityID, i.UserID, i.BookingType, i.TournamentID, i.StartDateTime, i.EndDateTime, i.TotalAmountOfPeople, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.BookingID = d.BookingID;

    -- Log deleted records (DELETE)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, OperationType)
    SELECT BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, 'DELETE'
    FROM deleted;
END;
GO

-- Table Generation
CREATE TABLE Participants (
    ParticipantID VARCHAR(8) PRIMARY KEY CHECK (ParticipantID LIKE 'P%'),  
    BookingID VARCHAR(8) NOT NULL CHECK (BookingID LIKE 'B%'),         
    FullName VARBINARY(255) NOT NULL,        
    Email VARCHAR(100) NOT NULL UNIQUE CHECK (Email LIKE '%_@__%.__%'),    
    PhoneNumber VARCHAR(15) CHECK (PhoneNumber LIKE '+60_________'),               
    Age INT CHECK (Age >= 0 AND Age <= 120), 
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')),
    CONSTRAINT FK_Booking FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) 
);

-- Dynamic Data Masking for sensitive data
ALTER TABLE Participants
    ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE Participants
    ALTER COLUMN PhoneNumber ADD MASKED WITH (FUNCTION = 'partial(0,"+60",0)');

ALTER TABLE Participants 
    ALTER COLUMN ParticipantID ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE Participants 
    ALTER COLUMN Age ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE Participants 
    ALTER COLUMN Gender ADD MASKED WITH (FUNCTION = 'default()');

-- ENCRYPTION DETAILS
CREATE SYMMETRIC KEY ParticipantKey
WITH ALGORITHM = AES_256
ENCRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

-- Logging
CREATE TABLE ParticipantsHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID VARCHAR(8),
    BookingID VARCHAR(8),
    FullName VARBINARY(255),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(15),
    Age INT,
    Gender VARCHAR(10),
    ChangeType VARCHAR(10), -- 'INSERT', 'UPDATE', or 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger to log changes
CREATE TRIGGER trg_Participants_Audit
ON Participants
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
    SELECT ParticipantID, BookingID, ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), FullName), Email, PhoneNumber, Age, Gender, 
		'INSERT' FROM inserted;
    
    -- Log updated records (UPDATE)
    INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
    SELECT i.ParticipantID, i.BookingID, ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), i.FullName), i.Email, i.PhoneNumber, i.Age, i.Gender, 
		'UPDATE' FROM inserted i
	JOIN deleted d ON i.ParticipantID = d.ParticipantID
	WHERE i.ParticipantID IS NOT NULL;

    -- Log deleted records (DELETE)
    INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
    SELECT ParticipantID, BookingID, ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), FullName), Email, PhoneNumber, Age, Gender, 
	'DELETE'FROM deleted;
END;
GO
