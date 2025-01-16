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
    ALTER COLUMN ParticipantID ADD MASKED WITH (FUNCTION = 'partial(1,"***",1)');

ALTER TABLE Participants 
    ALTER COLUMN Age ADD MASKED WITH (FUNCTION = 'default()');

ALTER TABLE Participants 
    ALTER COLUMN Gender ADD MASKED WITH (FUNCTION = 'default()');

-- ENCRYPTION DETAILS
CREATE SYMMETRIC KEY FullNameSymmetricKey
WITH ALGORITHM = AES_256
ENCRYPTION BY PASSWORD = 'password';

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
    ChangeType VARCHAR(10),						-- 'INSERT', 'UPDATE', or 'DELETE'
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
        SELECT	
			ParticipantID, 
			BookingID, 
			ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'), FullName), 
			Email, 
			PhoneNumber, 
			Age, 
			Gender, 
			'INSERT'
        FROM inserted;
    
    -- Log updated records (UPDATE)
        INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
        SELECT 
			i.ParticipantID, 
			i.BookingID, 
			ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'), i.FullName), 
			i.Email, 
			i.PhoneNumber, 
			i.Age, 
			i.Gender, 
			'UPDATE'
        FROM inserted i
		JOIN deleted d ON i.ParticipantID = d.ParticipantID
		WHERE i.ParticipantID IS NOT NULL;

    -- Log deleted records (DELETE)
        INSERT INTO ParticipantsHistory (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender, ChangeType)
        SELECT 
			ParticipantID, 
			BookingID, 
			ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'), FullName), 
			Email, 
			PhoneNumber, 
			Age, 
			Gender, 
			'DELETE'
        FROM deleted;
	END;
	GO

-- inserting sample records
OPEN SYMMETRIC KEY FullNameSymmetricKey DECRYPTION BY PASSWORD = 'password';

INSERT INTO Participants (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender)
VALUES
('P1', 'B1', ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'),'Fak Jun Yee'), 'FJY@gmail.com', '+60123456789', '23', 'Male'),
('P2', 'B2', ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'),'Fak Vig Nesh'), 'FVN@gmail.com', '+60198765432', '50', 'Female'),
('P3', 'B3', ENCRYPTBYKEY(KEY_GUID('FullNameSymmetricKey'),'Fak Yu Lius'), 'FYL@gmail.com', '+60196969696', '12', 'Male')

CLOSE SYMMETRIC KEY FullNameSymmetricKey;
select * from Participants
