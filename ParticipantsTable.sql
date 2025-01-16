-- Table Generation
CREATE TABLE Participants (
    ParticipantID VARCHAR(8) PRIMARY KEY,  
    BookingID VARCHAR(8) NOT NULL,         
    FullName VARCHAR(100) NOT NULL,        
    Email VARCHAR(100) NOT NULL UNIQUE,    
    PhoneNumber VARCHAR(15),               
    Age INT CHECK (Age >= 0 AND Age <= 120), 
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Others')), 
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

