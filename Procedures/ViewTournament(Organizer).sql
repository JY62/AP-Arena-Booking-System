CREATE PROCEDURE ViewTournament_Organizer ()
BEGIN
    -- Return tournaments that belong to the organizer
    SELECT * 
    FROM Tournament 
    WHERE OrganizerID = @UserID;
END;

-- Valid EXEC
SET @UserID = 'TO789';
CALL ViewTournament_Organizer();

-- Invalid organizer with no tournaments
SET @UserID = 'TO999';
CALL ViewTournament_Organizer();
