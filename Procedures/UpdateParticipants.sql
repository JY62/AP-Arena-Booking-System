CREATE PROCEDURE UpdateParticipants ()
BEGIN
    -- Validate if the booking exists and is approved
    IF (SELECT COUNT(*) FROM Bookings WHERE BookingID = @BookingID AND ApprovalStatus = 'Approved') = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Booking does not exist or is not approved.';
    END IF;

    -- Validate if the update is within 24 hours before the event
    IF TIMESTAMPDIFF(HOUR, NOW(), (SELECT EventDate FROM Bookings WHERE BookingID = @BookingID)) < 24 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Updates are only allowed 24 hours before the event.';
    END IF;

    -- Update participant details
    UPDATE Bookings
    SET ParticipantDetails = @ParticipantDetails
    WHERE BookingID = @BookingID AND 
          (OrganizerID = @UserID OR LEFT(@UserID, 2) = 'TO');
END;

-- Valid EXEC
SET @UserID = 'IC456';
SET @BookingID = 10;
SET @ParticipantDetails = '{"Name": "John Doe", "Age": 25}';
CALL UpdateParticipants();

-- Invalid timing (within 24 hours)
SET @UserID = 'IC456';
SET @BookingID = 10;
SET @ParticipantDetails = '{"Name": "John Doe", "Age": 25}';
CALL UpdateParticipants();
