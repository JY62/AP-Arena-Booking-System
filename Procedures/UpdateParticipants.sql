-- First, we open the symmetric key for encryption
CREATE PROCEDURE UpdateParticipant
    @CurrentUserID NVARCHAR(10), -- Current User ID (could be IC or TO)
    @BookingID NVARCHAR(10), -- Booking ID for the participant
    @FullName NVARCHAR(100), -- Full name of the participant (to be encrypted)
    @Email NVARCHAR(100), -- Participant's email
    @PhoneNumber NVARCHAR(20), -- Participant's phone number
    @Age INT, -- Participant's age
    @Gender NVARCHAR(10) -- Participant's gender
AS
BEGIN
    -- Open the symmetric key for encryption
    OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

    -- Check if the user is authorized to update or insert the participant
    IF EXISTS (SELECT 1 FROM Bookings WHERE UserID = @CurrentUserID AND BookingID = @BookingID)
    BEGIN
        -- If the participant already exists for the given booking, update the record
        IF EXISTS (SELECT 1 FROM Participants WHERE BookingID = @BookingID)
        BEGIN
            UPDATE Participants
            SET 
                FullName = ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), @FullName),
                Email = @Email,
                PhoneNumber = @PhoneNumber,
                Age = @Age,
                Gender = @Gender
            WHERE BookingID = @BookingID;
        END
        -- If the participant does not exist, insert a new record
        ELSE
        BEGIN
            INSERT INTO Participants (ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender)
            VALUES 
                (NEWID(), @BookingID, ENCRYPTBYKEY(KEY_GUID('ParticipantKey'), @FullName), @Email, @PhoneNumber, @Age, @Gender);
        END
    END
    ELSE
    BEGIN
        -- If the user is not authorized, print a message
        PRINT 'You are not authorized to update or insert this participant.';
    END

    -- Close the symmetric key after the operation
    CLOSE SYMMETRIC KEY ParticipantKey;
END;

-- Step 6: Create roles for permissions
CREATE ROLE TournamentOrganizer;
CREATE ROLE IndividualCustomer;

-- Step 7: Create login and user examples
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER TO001 FOR LOGIN TO001;
CREATE LOGIN IC001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER IC001 FOR LOGIN IC001;

-- Step 8: Assign roles to users
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';
EXEC sp_addrolemember 'IndividualCustomer', 'IC001';

-- Step 9: Grant permissions to roles
GRANT SELECT ON dbo.Bookings TO TournamentOrganizer, IndividualCustomer;
GRANT SELECT ON dbo.Participants TO TournamentOrganizer, IndividualCustomer;
GRANT EXECUTE ON dbo.UpdateParticipant TO TournamentOrganizer, IndividualCustomer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer, IndividualCustomer;

-- Step 10: Valid execution as a Tournament Organizer
EXECUTE AS USER = 'IC001';  
EXEC UpdateParticipant 
    @CurrentUserID = 'IC001',        -- The current user ID (either Individual Customer or Tournament Organizer)
    @BookingID = 'B002',             -- The Booking ID associated with the participant
    @FullName = 'Emile Fring',         -- The full name of the participant (this will be encrypted)
    @Email = 'Fring@myhouse.com',-- The participant's email
    @PhoneNumber = '+60176809123',   -- The participant's phone number
    @Age = 33,                       -- The participant's age
    @Gender = 'Male'; 
REVERT;

-- Cleanup
DROP PROCEDURE UpdateParticipant;
DROP ROLE TournamentOrganizer;
DROP ROLE IndividualCustomer;
DROP LOGIN TO001;
DROP LOGIN IC001;
DROP USER TO001;
DROP USER IC001;
