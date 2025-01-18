CREATE PROCEDURE ViewAccountDetails
    @UserID NVARCHAR(50),
    @TableName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Role NVARCHAR(50) = LEFT(@UserID, 2)
    
    IF @TableName = 'User'
    BEGIN
        IF @Role IN ('DA', 'TO', 'IC')
        BEGIN
            -- View own details in User table
            SELECT UserID, UserType, FullName, Email, PasswordHash, PhoneNumber, RegistrationDate
            FROM [User]
            WHERE UserID = @UserID
        END
        ELSE IF @Role = 'CM'
        BEGIN
            -- View all details in User table, hide sensitive information for others
            SELECT 
                UserID, 
                UserType,
                CASE 
                    WHEN UserID = @UserID THEN FullName ELSE 'Hidden' 
                END AS FullName,
                CASE 
                    WHEN UserID = @UserID THEN Email ELSE 'Hidden' 
                END AS Email,
				CASE 
                    WHEN UserID = @UserID THEN PasswordHash ELSE 'Hidden' 
                END AS PasswordHash,
                CASE 
                    WHEN UserID = @UserID THEN PhoneNumber ELSE 'Hidden' 
                END AS PhoneNumber,
                RegistrationDate
            FROM [User]
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message
        END
    END
    ELSE IF @TableName = 'TournamentOrganizer'
    BEGIN
        IF @Role = 'TO'
        BEGIN
            -- View own details in TournamentOrganizer table
            SELECT OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus
            FROM TournamentOrganizer
            WHERE OrganizerID = @UserID
        END
        ELSE IF @Role = 'CM'
        BEGIN
            -- View all details in TournamentOrganizer table, hide sensitive information for others
            SELECT 
                OrganizerID,
                CASE 
                    WHEN OrganizerID = @UserID THEN BusinessName ELSE 'Hidden' 
                END AS BusinessName,
                CASE 
                    WHEN OrganizerID = @UserID THEN BusinessRegistrationNumber ELSE 'Hidden' 
                END AS BusinessRegistrationNumber,
                Address,
                ApprovalStatus
            FROM TournamentOrganizer
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message
        END
    END
    ELSE IF @TableName = 'Participants'
    BEGIN
        IF @Role IN ('TO', 'IC')
        BEGIN
            -- View own details in Participants table
            SELECT ParticipantID, BookingID, FullName, Email, PhoneNumber, Age, Gender
            FROM Participants
            WHERE ParticipantID = @UserID
        END
        ELSE IF @Role = 'CM'
        BEGIN
            -- View all details in Participants table, hide sensitive information for others
            SELECT 
                ParticipantID, BookingID, 
                CASE 
                    WHEN ParticipantID = @UserID THEN FullName ELSE 'Hidden' 
                END AS FullName,
                CASE 
                    WHEN ParticipantID = @UserID THEN Email ELSE 'Hidden' 
                END AS Email,
                CASE 
                    WHEN ParticipantID = @UserID THEN PhoneNumber ELSE 'Hidden' 
                END AS PhoneNumber,
                Age, Gender
            FROM Participants
        END
        ELSE
        BEGIN
            SELECT 'Access Denied' AS Message
        END
    END
    ELSE
    BEGIN
        SELECT 'Invalid Table Name' AS Message
    END
END

--Test as DA
EXEC ViewAccountDetails @UserID = 'DA001', @TableName = 'User';
EXEC ViewAccountDetails @UserID = 'DA001', @TableName = 'TournamentOrganizer';
EXEC ViewAccountDetails @UserID = 'DA001', @TableName = 'Participants';

--Test as CM
EXEC ViewAccountDetails @UserID = 'CM001', @TableName = 'User';
EXEC ViewAccountDetails @UserID = 'CM001', @TableName = 'TournamentOrganizer';
EXEC ViewAccountDetails @UserID = 'CM001', @TableName = 'Participants';

--Test as TO
EXEC ViewAccountDetails @UserID = 'TO001', @TableName = 'User';
EXEC ViewAccountDetails @UserID = 'TO001', @TableName = 'TournamentOrganizer';
EXEC ViewAccountDetails @UserID = 'TO001', @TableName = 'Participants';

--Test as IC
EXEC ViewAccountDetails @UserID = 'IC001', @TableName = 'User';
EXEC ViewAccountDetails @UserID = 'IC001', @TableName = 'TournamentOrganizer';
EXEC ViewAccountDetails @UserID = 'IC001', @TableName = 'Participants';
