USE APArenaDB;

DROP PROCEDURE ViewTournamentParticipants;


CREATE OR ALTER PROCEDURE ViewTournamentParticipants
    @BookingID VARCHAR(8)
AS
BEGIN
    SET NOCOUNT ON;

    -- Open the symmetric key
    OPEN SYMMETRIC KEY ParticipantKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';

    -- Validate BookingID
    IF NOT EXISTS (
        SELECT 1
        FROM Participants
        WHERE BookingID = @BookingID
    )
    BEGIN
        PRINT 'No participants found for the provided BookingID.';
        RETURN;
    END

    -- Retrieve and decrypt participants' data
    SELECT 
        ParticipantID,
        CASE 
            WHEN FullName IS NOT NULL 
            THEN CAST(DecryptByKey(FullName) AS VARCHAR(255)) -- Decrypt and cast as NVARCHAR
            ELSE 'Unknown' 
        END AS FullName,
        Email,
        PhoneNumber,
        Age,
        Gender
    FROM Participants
    WHERE BookingID = @BookingID;

    -- Close the symmetric key
    CLOSE SYMMETRIC KEY ParticipantKey;
END;
GO










-- Create the IndividualCustomer role
CREATE ROLE TournamentOrganizer;

-- Create a sample login and user for testing
CREATE LOGIN TO001 WITH PASSWORD = '123'; -- Replace with a secure password
CREATE USER TO001 FOR LOGIN TO001;

-- Add the IC004 user to the IndividualCustomer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Step 4: Grant necessary permissions to the TournamentOrganizer role
GRANT EXECUTE ON dbo.ViewTournamentParticipants TO TournamentOrganizer;
GRANT SELECT ON dbo.Bookings TO TournamentOrganizer;
GRANT SELECT ON dbo.Participants TO TournamentOrganizer;
GRANT VIEW DEFINITION ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer;
GRANT UNMASK TO TournamentOrganizer;


-- Log in as TO001 and execute the procedure
EXECUTE AS LOGIN = 'TO001';
EXEC ViewTournamentParticipants @BookingID = 'B001';

REVERT;


