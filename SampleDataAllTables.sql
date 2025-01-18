--User Table

OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
-- Data Admin accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate)
VALUES
('DA001', 'Data Admin', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Alice Tan'), 'alice.tan@example.com', HASHBYTES('SHA2_256', 'StrongP@ss1'), '+60123456789', GETDATE()),
('DA002', 'Data Admin', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Bob Lim'), 'bob.lim@example.com', HASHBYTES('SHA2_256', 'Str0ngP@ss2'), '+60129876543', GETDATE());

-- Complex Manager account
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate)
VALUES
('CM001', 'Complex Manager', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Charles Ng'), 'charles.ng@example.com', HASHBYTES('SHA2_256', 'CmplxM@n1'), '+60134567890', GETDATE());

-- Tournament Organizer accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate)
VALUES
('TO001', 'Tournament Organizer', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Diana Wong'), 'diana.wong@example.com', HASHBYTES('SHA2_256', 'T0urn@ment1'), '+60145678901', GETDATE()),
('TO002', 'Tournament Organizer', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Edward Lee'), 'edward.lee@example.com', HASHBYTES('SHA2_256', 'T0urn@ment2'), '+60156789012', GETDATE());

-- Individual Customer accounts
INSERT INTO [User] (UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate)
VALUES
('IC001', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Fiona Tan'), 'fiona.tan@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss1'), '+60167890123', GETDATE()),
('IC002', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'George Lim'), 'george.lim@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss2'), '+60178901234', GETDATE()),
('IC003', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Jojo Siwa'), 'annoyingmf@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss3'), '+60178791261', GETDATE()),
('IC004', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Siew Pui Yi'), 'MsPuiYi@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss4'), '+60178791261', GETDATE()),
('IC005', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Maria Ozawa'), 'dayummmmm@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss5'), '+60196969696', GETDATE()),
('IC006', 'Individual Customers', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'P Diddy'), 'PartyLover@example.com', HASHBYTES('SHA2_256', 'Cust0m3rP@ss6'), '+60123456789', GETDATE());
-- Close the symmetric key after the operation
CLOSE SYMMETRIC KEY UserKey; 

-- Facility Table

INSERT INTO Facility 
(FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus) 
VALUES
('F1', 'Volleyball court', 'Pro Volleyball Court A', 50, 75.00, 1),
('F2', 'Volleyball court', 'Pro Volleyball Court B', 50, 75.00, 1),
('F3', 'Basketball court', 'Championship Court 1', 100, 100.00, 1),
('F4', 'Basketball court', 'Championship Court 2', 100, 100.00, 0),
('F5', 'Badminton court', 'Elite Badminton Court A', 30, 50.00, 1),
('F6', 'Badminton court', 'Elite Badminton Court B', 30, 50.00, 1),
('F7', 'Tennis court', 'Grand Tennis Court', 40, 90.00, 1),
('F8', 'Swimming pool', 'Olympic Pool', 200, 150.00, 0),
('F9', 'Gym', 'Fitness Center', 80, 45.00, 1),
('F10', 'Tennis court', 'Center Tennis Court', 40, 90.00, 1);

select * from Facility

--TournamentOrganizer
OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

INSERT INTO TournamentOrganizer 
(OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus) 
VALUES
('TO001', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'SportsMaster Events'), '789405612346', ENCRYPTBYKEY(KEY_GUID('UserKey'), '123 Sports Complex Avenue, Level 2, Block A, Jakarta Selatan'), 'Approved'),
('TO002', ENCRYPTBYKEY(KEY_GUID('UserKey'), 'Elite Tournament Solutions'), '456706901299', ENCRYPTBYKEY(KEY_GUID('UserKey'), '45 Championship Road, Tower B, Level 5, Jakarta Pusat'), 'Approved');
CLOSE SYMMETRIC KEY UserKey;

select * from TournamentOrganizer

--Tournament Table

INSERT INTO Tournaments (TournamentID, OrganizerID, TournamentName, StartDateTime, EndDateTime)
VALUES 
('T001', 'TO001', 'Basketball Championship', '2025-02-01 09:00:00', '2025-02-05 18:00:00'),
('T002', 'TO002', 'Volleyball Tournament', '2025-03-10 10:00:00', '2025-03-15 20:00:00'),
('T003', 'TO001', 'Squash League', '2025-04-01 08:00:00', '2025-04-10 19:00:00'),
('T004', 'TO001', 'Badminton Open', '2025-05-05 09:30:00', '2025-05-08 17:30:00'),
('T005', 'TO001', 'Swimming Event', '2025-06-01 06:00:00', '2025-06-01 14:00:00');
GO
select * from Tournaments

--Bookings

INSERT INTO Bookings (BookingID, FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
VALUES 
('B001', 'F1', 'IC001', 'Tournament', 'T003', '2025-01-20 10:00:00', '2025-01-20 12:00:00', 10),
('B002', 'F2', 'IC004', 'Tournament', 'T003', '2025-01-25 09:00:00', '2025-01-25 15:00:00', 50),
('B003', 'F3', 'IC005', 'Tournament', 'T004', '2025-01-30 14:00:00', '2025-01-30 18:00:00', 20),
('B004', 'F4', 'IC006', 'Tournament', 'T005', '2025-01-30 14:00:00', '2025-01-30 18:00:00', 20)
GO

select * from Bookings

-- Participants Table
  
OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

INSERT INTO [Participants] (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender)
VALUES
('P001', 'B001', ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), 'Fiona Tan'), 'fiona.tan@example.com', '+60167890123', '50','Female'),
('P002', 'B002', ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), 'George Lim'), 'george.lim@example.com', '+60178901234', '20', 'Male'),
('P003', 'B003', ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), 'Siew Pui Yi'), 'MsPuiYi@example.com', '+60178791261', '20','Female'),
('P004', 'B004', ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), 'Maria Ozawa'), 'dayummmmm@example.com', '+60196969696', '30','Female'),
('P005', 'B004', ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), 'P Diddy'), 'PartyLover@example.com', '+60123456789', '45','Male');

CLOSE SYMMETRIC KEY ParticipantKey;

Select * from Participants
