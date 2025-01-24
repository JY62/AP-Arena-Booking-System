-- UpdateBusinessRegistration Procedure
CREATE PROCEDURE UpdateBusinessRegistration
    @OrganizerID NVARCHAR(50), -- Input parameter for OrganizerID
    @ApprovalStatus NVARCHAR(50) -- Input parameter for ApprovalStatus
AS
BEGIN
    -- Step 1: Validate if the ApprovalStatus is one of the allowed values
    IF @ApprovalStatus NOT IN ('Approved', 'Pending')
    BEGIN
        RAISERROR('Invalid ApprovalStatus. Only "Approved", "Denied", or "Pending" are allowed.', 16, 1);
        RETURN;
    END

    -- Step 2: Display tournament organizer information
    PRINT 'Available Tournament Organizers for Approval:';
    SELECT OrganizerID, BusinessName, ApprovalStatus
    FROM TournamentOrganizer;

    -- Validate if the OrganizerID exists
    IF NOT EXISTS (
        SELECT 1 
        FROM TournamentOrganizer 
        WHERE OrganizerID = @OrganizerID
    )
    BEGIN
        RAISERROR('Invalid OrganizerID.', 16, 1);
        RETURN;
    END

    -- Step 3: Update ApprovalStatus in TournamentOrganizer table
    UPDATE TournamentOrganizer
    SET ApprovalStatus = @ApprovalStatus
    WHERE OrganizerID = @OrganizerID;

    PRINT 'Business registration status updated successfully for OrganizerID: ' + @OrganizerID;
END;

-- Role and Permissions
CREATE ROLE ComplexManager;

CREATE LOGIN CM001 WITH PASSWORD = 'yourpassword'; 
CREATE USER CM001 FOR LOGIN CM001;

EXEC sp_addrolemember 'ComplexManager', 'CM001';

GRANT SELECT, UPDATE ON dbo.TournamentOrganizer TO ComplexManager;
GRANT EXECUTE ON dbo.UpdateBusinessRegistration TO ComplexManager;

-- Valid EXEC (Complex Manager updating ApprovalStatus)
EXEC UpdateBusinessRegistration @OrganizerID = 'TO001', @ApprovalStatus = 'Approved';
REVERT;

-- Invalid EXEC 
EXEC UpdateBusinessRegistration @OrganizerID = 'TO001', @ApprovalStatus = 'NO';
REVERT;

DROP PROCEDURE UpdateBusinessRegistration;
