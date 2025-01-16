-- Create Tournaments Table
CREATE TABLE Tournaments (
    TournamentID VARCHAR(8) PRIMARY KEY,
    OrganizerID VARCHAR(8),
    TournamentName VARCHAR(100),
    StartDateTime DATETIME,
    EndDateTime DATETIME,
    CONSTRAINT FK_OrganizerID FOREIGN KEY (OrganizerID) REFERENCES TournamentOrganizer(OrganizerID)
);

-- Create TournamentsHistory Table
CREATE TABLE TournamentsHistory (
    HistoryID INT IDENTITY PRIMARY KEY,
    TournamentID VARCHAR(8),
    OrganizerID VARCHAR(8),
    TournamentName VARCHAR(100),
    StartDateTime DATETIME,
    EndDateTime DATETIME,
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);

-- Trigger for Logging DML Changes on Tournaments Table
CREATE TRIGGER trg_Tournaments_Audit
ON Tournaments
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, OperationType)
    SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, OperationType)
    SELECT i.TournamentID, i.OrganizerID, i.TournamentName, i.StartDateTime, i.EndDateTime, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.TournamentID = d.TournamentID;

    -- Log deleted records (DELETE)
    INSERT INTO TournamentsHistory (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, OperationType)
    SELECT TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime, 'DELETE'
    FROM deleted;
END;
GO

-- Insert Sample Data into Tournaments
INSERT INTO Tournaments (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime)
VALUES 
('F001', 'TO001', 'Basketball Championship', '2025-02-01 09:00:00', '2025-02-05 18:00:00'),
('F002', 'TO002', 'Volleyball Tournament', '2025-03-10 10:00:00', '2025-03-15 20:00:00'),
('F003', 'TO003', 'Squash League', '2025-04-01 08:00:00', '2025-04-10 19:00:00'),
('F004', 'TO004', 'Badminton Open', '2025-05-05 09:30:00', '2025-05-08 17:30:00'),
('F005', 'TO005', 'Swimming Event', '2025-06-01 06:00:00', '2025-06-01 14:00:00');
GO

-- Create Bookings Table
CREATE TABLE Bookings (
    BookingID VARCHAR(8) PRIMARY KEY,
    FacilityID VARCHAR(8),
    UserID VARCHAR(8),
    BookingType VARCHAR(20),
    TournamentID VARCHAR(8) NULL,
    StartDateTime DATETIME,
    EndDateTime DATETIME,
    TotalAmountOfPeople INT NULL,
    BookingStatus VARCHAR(20),
    CONSTRAINT FK_FacilityID FOREIGN KEY (FacilityID) REFERENCES Facilities(FacilityID),
    CONSTRAINT FK_UserID FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_TournamentID FOREIGN KEY (TournamentID) REFERENCES Tournaments(TournamentID)
);

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
    BookingStatus VARCHAR(20),
    OperationType VARCHAR(10), -- 'INSERT', 'UPDATE', 'DELETE'
    ChangeDate DATETIME DEFAULT GETDATE()
);

-- Trigger for Logging DML Changes on Bookings Table
CREATE TRIGGER trg_Bookings_Audit
ON Bookings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log inserted records (INSERT)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus, OperationType)
    SELECT BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus, 'INSERT'
    FROM inserted;

    -- Log updated records (UPDATE)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus, OperationType)
    SELECT i.BookingID, i.FacilityID, i.UserID, i.BookingType, i.TournamentID, i.StartDateTime, i.EndDateTime, i.TotalAmountOfPeople, i.BookingStatus, 'UPDATE'
    FROM inserted i
    JOIN deleted d ON i.BookingID = d.BookingID;

    -- Log deleted records (DELETE)
    INSERT INTO BookingsHistory (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus, OperationType)
    SELECT BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus, 'DELETE'
    FROM deleted;
END;
GO

-- Insert Sample Data into Bookings
INSERT INTO Bookings (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople, BookingStatus)
VALUES 
('APA001', 'FAC001', 'TO001', 'Training', 'F001', '2025-01-20 10:00:00', '2025-01-20 12:00:00', 10, 'Confirmed'),
('APA002', 'FAC002', 'TO002', 'Event', 'F002', '2025-01-25 09:00:00', '2025-01-25 15:00:00', 50, 'Confirmed'),
('APA003', 'FAC003', 'TO003', 'Match', 'F003', '2025-01-30 14:00:00', '2025-01-30 18:00:00', 20, 'Pending'),
('APA004', 'FAC004', 'TO004', 'Workshop', 'F004', '2025-02-05 13:00:00', '2025-02-05 16:00:00', 15, 'Cancelled'),
('APA005', 'FAC005', 'TO005', 'Seminar', 'F005', '2025-02-10 09:00:00', '2025-02-10 12:00:00', 30, 'Confirmed');
GO
