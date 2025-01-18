CREATE PROCEDURE UpdateBusinessRegistration ()
BEGIN
    -- Validate the role of the user
    IF LEFT(@UserID, 2) != 'CM' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only Complex Managers are allowed to update this record.';
    END IF;

    -- Validate the status
    IF @ApprovalStatus NOT IN ('Approved', 'Pending', 'Denied') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Approval Status. Only Approved, Pending, or Denied are allowed.';
    END IF;

    -- Check if the status is the same as the current status
    IF (SELECT ApprovalStatus FROM TournamentOrganizer WHERE TournamentOrganizerID = @TournamentOrganizerID) = @ApprovalStatus THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'The status is already set to the provided value.';
    END IF;

    -- Update the record
    UPDATE TournamentOrganizer
    SET ApprovalStatus = @ApprovalStatus
    WHERE TournamentOrganizerID = @TournamentOrganizerID;
END;

-- valid EXEC
SET @UserID = 'CM123';
SET @TournamentOrganizerID = 5;
SET @ApprovalStatus = 'Approved';
CALL UpdateBusinessRegistration();


-- invalid EXEC
-- Invalid role
SET @UserID = 'TO456';
SET @TournamentOrganizerID = 5;
SET @ApprovalStatus = 'Approved';
CALL UpdateBusinessRegistration();
