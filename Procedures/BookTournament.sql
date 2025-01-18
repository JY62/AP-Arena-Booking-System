CREATE PROCEDURE BookTournament ()
BEGIN
    -- Validate if the tournament exists and is approved
    IF (SELECT COUNT(*) FROM Tournament WHERE TournamentID = @TournamentID AND ApprovalStatus = 'Approved') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tournament does not exist or is not approved for booking.';
    END IF;

    -- Create a new booking
    INSERT INTO Bookings (TournamentID, OrganizerID, BookingDate)
    VALUES (@TournamentID, @UserID, NOW());
END;


-- Valid EXEC
SET @UserID = 'TO123';
SET @TournamentID = 2;
CALL BookTournament();

-- Invalid tournament ID
SET @UserID = 'TO123';
SET @TournamentID = 999;
CALL BookTournament();
