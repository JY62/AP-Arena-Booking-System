drop procedure InsertTournamentOrganizer

CREATE PROCEDURE InsertTournamentOrganizer
    @BusinessName NVARCHAR(255),
    @BusinessRegistrationNumber VARCHAR(12),
    @Address NVARCHAR(255)
AS
BEGIN
	
    DECLARE @OrganizerID NVARCHAR(50) = SUSER_SNAME();
    
    IF @OrganizerID IS NOT NULL
    BEGIN
        BEGIN TRY
			OPEN SYMMETRIC KEY UserKey DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%';
            INSERT INTO TournamentOrganizer (OrganizerID, BusinessName, BusinessRegistrationNumber, Address)
            VALUES (@OrganizerID, ENCRYPTBYKEY(KEY_GUID('UserKey'), '@BusinessName'), 
		    @BusinessRegistrationNumber, CONVERT(VARBINARY(255), ENCRYPTBYKEY(KEY_GUID('UserKey'), '@Address')));
            CLOSE SYMMETRIC KEY UserKey;
            PRINT 'Insert successful.';
        END TRY
        BEGIN CATCH
            PRINT 'Error occurred: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
    BEGIN
        PRINT 'Error: OrganizerID could not be determined from the current login.';
    END
END;
GO


-- Testing --

--create role
CREATE ROLE TournamentOrganizer;

--create login of test user
CREATE LOGIN TO003 WITH PASSWORD = 'StrongPassword123!';

-- create user
CREATE USER TO003 FOR LOGIN TO003;

-- giving permissions
ALTER ROLE TournamentOrganizer ADD MEMBER TO003;

GRANT EXECUTE ON InsertTournamentOrganizer TO TournamentOrganizer;

GRANT INSERT ON TournamentOrganizer TO TournamentOrganizer;

GRANT CONTROL ON SYMMETRIC KEY::UserKey TO TournamentOrganizer;
GRANT CONTROL ON SYMMETRIC KEY::ParticipantKey TO TournamentOrganizer;

-- execute
Exec as user = 'TO003';

EXEC InsertTournamentOrganizer 
    @BusinessName = 'My Business Name',
    @BusinessRegistrationNumber = '111101111111', 
    @Address = '123 Business Street';

REVERT;
