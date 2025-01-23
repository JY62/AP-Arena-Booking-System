CREATE PROCEDURE UpdateParticipants
    @BookingID NVARCHAR(10), -- Booking ID for the participant
    @ParticipantID NVARCHAR(10), -- Participant ID to specify which participant to modify
    @FullName NVARCHAR(100) = NULL, -- Full name of the participant (to be encrypted), optional
    @Email NVARCHAR(100) = NULL, -- Participant's email, optional
    @PhoneNumber NVARCHAR(20) = NULL, -- Participant's phone number, optional
    @Age INT = NULL, -- Participant's age, optional
    @Gender NVARCHAR(10) = NULL -- Participant's gender, optional
AS
BEGIN
    -- Declare variables for encryption, validation, and time check
    DECLARE @EncryptedFullName VARBINARY(256) = NULL;
    DECLARE @OriginalEmail NVARCHAR(100);
    DECLARE @OriginalPhoneNumber NVARCHAR(20);
    DECLARE @OriginalAge INT;
    DECLARE @OriginalGender NVARCHAR(10);
    DECLARE @UserID NVARCHAR(100) = SUSER_NAME();
    DECLARE @BookingStartDateTime DATETIME;

    -- Check if the current user is authorized to update the participant
    IF NOT EXISTS (SELECT 1 FROM Bookings WHERE UserID = @UserID AND BookingID = @BookingID)
    BEGIN
        RAISERROR('You are not authorized to update this participant.', 16, 1);
        RETURN;
    END

    -- Retrieve the Booking StartDateTime from the Bookings table for time validation
    SELECT @BookingStartDateTime = StartDateTime
    FROM Bookings
    WHERE BookingID = @BookingID;

    -- Check if the update is being attempted 24 hours before the booking time
    IF @BookingStartDateTime <= DATEADD(HOUR, 24, GETDATE())
    BEGIN
        RAISERROR('Update cannot be performed within 24 hours of the booking time.', 16, 1);
        RETURN;
    END

    -- Retrieve the original values for the participant based on ParticipantID
    SELECT 
        @OriginalEmail = Email,
        @OriginalPhoneNumber = PhoneNumber,
        @OriginalAge = Age,
        @OriginalGender = Gender
    FROM Participants
    WHERE BookingID = @BookingID AND ParticipantID = @ParticipantID;

    -- Check if participant exists for the given BookingID and ParticipantID
    IF NOT EXISTS (SELECT 1 FROM Participants WHERE BookingID = @BookingID AND ParticipantID = @ParticipantID)
    BEGIN
        RAISERROR('Participant not found for the specified BookingID and ParticipantID.', 16, 1);
        RETURN;
    END

    -- Encrypt the FullName if provided
    IF @FullName IS NOT NULL
    BEGIN
        OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
        SET @EncryptedFullName = EncryptByKey(Key_GUID('ParticipantKey'), @FullName);
        CLOSE SYMMETRIC KEY ParticipantKey;
    END

    -- Update the participant's details
    UPDATE Participants
    SET
        FullName = CASE WHEN @EncryptedFullName IS NOT NULL THEN @EncryptedFullName ELSE FullName END,
        Email = CASE WHEN @Email IS NOT NULL THEN @Email ELSE @OriginalEmail END,
        PhoneNumber = CASE WHEN @PhoneNumber IS NOT NULL THEN @PhoneNumber ELSE @OriginalPhoneNumber END,
        Age = CASE WHEN @Age IS NOT NULL THEN @Age ELSE @OriginalAge END,
        Gender = CASE WHEN @Gender IS NOT NULL THEN @Gender ELSE @OriginalGender END
    WHERE BookingID = @BookingID AND ParticipantID = @ParticipantID;
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
GRANT EXECUTE ON dbo.UpdateParticipants TO TournamentOrganizer, IndividualCustomer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer, IndividualCustomer;

-- Step 10: Valid execution as a Tournament Organizer
EXECUTE AS USER = 'IC001';  
-- Example: Executing the UpdateParticipants procedure
EXEC UpdateParticipants
    @BookingID = 'B001', -- Replace with a valid BookingID
    @ParticipantID = 'P001',    -- Replace with a valid ParticipantID
    @FullName = 'John Doe', -- Optional: Provide a full name to be encrypted
    @Email = 'johndoe@example.com', -- Optional: Provide an email
    @PhoneNumber = '+601234567890', -- Optional: Provide a phone number
    @Age = 30, -- Optional: Provide the age
    @Gender = 'Male'; -- Optional: Provide the gender
REVERT;

-- Cleanup
DROP PROCEDURE UpdateParticipants;
DROP ROLE TournamentOrganizer;
DROP ROLE IndividualCustomer;
DROP LOGIN TO001;
DROP LOGIN IC001;
DROP USER TO001;
DROP USER IC001;

REVOKE SELECT ON dbo.Bookings TO TournamentOrganizer, IndividualCustomer;
REVOKE SELECT ON dbo.Participants TO TournamentOrganizer, IndividualCustomer;
REVOKE EXECUTE ON dbo.UpdateParticipants TO TournamentOrganizer, IndividualCustomer;
REVOKE CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer, IndividualCustomer;

EXEC sp_droprolemember 'TournamentOrganizer', 'TO001';
EXEC sp_droprolemember 'IndividualCustomer', 'IC001';
