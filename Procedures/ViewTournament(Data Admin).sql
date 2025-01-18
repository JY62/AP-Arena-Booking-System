CREATE PROCEDURE ViewTournament_AdminManager ()
BEGIN
    -- Validate the role of the user
    IF LEFT(@UserID, 2) NOT IN ('DA', 'CM') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only Data Admins or Complex Managers can access this procedure.';
    END IF;

    -- Return tournaments with a filter on ApprovalStatus
    SELECT *
    FROM Tournament
    WHERE ApprovalStatus IN ('Approved', 'Pending', 'Denied');
END;

-- Valid EXEC
SET @UserID = 'DA001';
CALL ViewTournament_AdminManager();

-- Invalid role
SET @UserID = 'TO456';
CALL ViewTournament_AdminManager();
