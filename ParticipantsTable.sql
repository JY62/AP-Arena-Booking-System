-- Table Generation
CREATE TABLE Participants (
    ParticipantID VARCHAR(8) PRIMARY KEY CHECK (ParticipantID LIKE 'P%' AND LEN(ParticipantID) = 8),  
    BookingID VARCHAR(8) NOT NULL CHECK (BookingID LIKE 'B%' AND LEN(BookingID) = 8),         
    FullName VARCHAR(100) NOT NULL,        
    Email VARCHAR(100) NOT NULL UNIQUE CHECK (Email LIKE '%_@__%.__%'),    
    PhoneNumber VARCHAR(15) CHECK (PhoneNumber LIKE '+60_________'),               
    Age INT CHECK (Age >= 0 AND Age <= 120), 
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')),  -- Only 'Male' or 'Female'
    CONSTRAINT FK_Booking FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID) 
);

-- Obfuscation
ALTER TABLE Participants 
    ALTER COLUMN ParticipantID ADD MASKED WITH (FUNCTION = 'partial(1,"***",1)');
    
ALTER TABLE Participants 
    ALTER COLUMN Age ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE Participants 
    ALTER COLUMN Gender ADD MASKED WITH (FUNCTION = 'default()');

-- Logging
CREATE TABLE ParticipantsHistory (
    HistoryID INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID VARCHAR(8),
    BookingID VARCHAR(8),
    FullName VARCHAR(100),
    Email VARCHAR(100),
    PhoneNumber VARCHAR(15),
    Age INT,
    Gender VARCHAR(10),
    ChangeType VARCHAR(10),                   -- 'INSERT', 'UPDATE', or 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()     -- Timestamp of the change
);
GO

-- Trigger to log changes
CREATE TRIGGER trg_Participants_Audit
ON Participants
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
        SELECT i.ParticipantID, i.BookingID, i.FullName, i.Email, i.PhoneNumber, i.Age, i.Gender, 'INSERT'
        FROM inserted i;
    END

    -- Log updated records (UPDATE)
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE ph
        SET ph.BookingID = i.BookingID,
            ph.FullName = i.FullName,
            ph.Email = i.Email,
            ph.PhoneNumber = i.PhoneNumber,
            ph.Age = i.Age,
            ph.Gender = i.Gender,
            ph.ChangeType = 'UPDATE'
        FROM ParticipantsHistory ph
        JOIN inserted i ON ph.ParticipantID = i.ParticipantID
        WHERE EXISTS (SELECT 1 FROM deleted d WHERE d.ParticipantID = i.ParticipantID);
    END

    -- Log deleted records (DELETE)
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
        SELECT d.ParticipantID, d.BookingID, d.FullName, d.Email, d.PhoneNumber, d.Age, d.Gender, 'DELETE'
        FROM deleted d;
    END
END;
GO


--encrypting

-- Create a symmetric key for encryption
CREATE SYMMETRIC KEY ParticipantKey
WITH ALGORITHM = AES_256
ENCRYPTION BY PASSWORD = 'YourStrongPasswordHere';

-- make new encrypted columns
alter Table Participants Add FullName_Encrypted varbinary(Max)Null
alter Table Participants Add Email_Encrypted varbinary(Max)Null
alter Table Participants Add PhoneNumber_Encrypted varbinary(Max)Null

--Encrypting new columns
Open Symmetric Key ParticipantKey
DECRYPTION BY PASSWORD = 'YourStrongPasswordHere';

update Participants Set [FullName_Encrypted] = ENCRYPTBYKEY
(KEY_GUID('ParticipantKey'), FullName);

update Participants Set [Email_Encrypted] = ENCRYPTBYKEY
(KEY_GUID('ParticipantKey'), Email);

update Participants Set [PhoneNumber_Encrypted] = ENCRYPTBYKEY
(KEY_GUID('ParticipantKey'), PhoneNumber);

--drop decrypted columns
Alter table Participants Drop Column FullName
Alter table Participants Drop Column Email
Alter table Participants Drop Column PhoneNumber

--rename columns

EXEC sp_rename 'dbo.Participants.FullName_Encrypted',
'FullName', 'COLUMN';
EXEC sp_rename 'dbo.Participants.Email_Encrypted',
'Email', 'COLUMN';
EXEC sp_rename 'dbo.Participants.PhoneNumber_Encrypted',
'PhoneNumber', 'COLUMN';

-- show decrypted columns

Open Symmetric Key ParticipantKey
DECRYPTION BY PASSWORD = 'YourStrongPasswordHere';

Select ParticipantID, BookingID, Age, Gender,
convert(varchar, DECRYPTBYKEY(FullName))
As 'DecryptedName',
convert(varchar, DECRYPTBYKEY(Email))
As 'DecryptedEmail',
convert(varchar, DECRYPTBYKEY(PhoneNumber))
As 'DecryptedPhoneNumber' from Participants;

close symmetric key ParticipantKey

select * from Participants
