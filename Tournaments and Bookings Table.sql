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
('T001', 'ORG001', 'Chess Championship', '2025-02-01 09:00:00', '2025-02-05 18:00:00'),
('T002', 'ORG002', 'Soccer Tournament', '2025-03-10 10:00:00', '2025-03-15 20:00:00'),
('T003', 'ORG003', 'Basketball League', '2025-04-01 08:00:00', '2025-04-10 19:00:00'),
('T004', 'ORG004', 'Badminton Open', '2025-05-05 09:30:00', '2025-05-08 17:30:00'),
('T005', 'ORG005', 'Marathon Event', '2025-06-01 06:00:00', '2025-06-01 14:00:00');
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
('B001', 'FAC001', 'USR001', 'Training', 'T001', '2025-01-20 10:00:00', '2025-01-20 12:00:00', 10, 'Confirmed'),
('B002', 'FAC002', 'USR002', 'Event', 'T002', '2025-01-25 09:00:00', '2025-01-25 15:00:00', 50, 'Confirmed'),
('B003', 'FAC003', 'USR003', 'Match', 'T003', '2025-01-30 14:00:00', '2025-01-30 18:00:00', 20, 'Pending'),
('B004', 'FAC004', 'USR004', 'Workshop', NULL, '2025-02-05 13:00:00', '2025-02-05 16:00:00', 15, 'Cancelled'),
('B005', 'FAC005', 'USR005', 'Seminar', NULL, '2025-02-10 09:00:00', '2025-02-10 12:00:00', 30, 'Confirmed');
GO
