CREATE PROCEDURE BookTournament
    @TournamentID NVARCHAR(8) -- Input parameter for TournamentID
AS
BEGIN
    -- Step 1: Display available tournaments for booking
    PRINT 'Available Approved Tournaments:';
    SELECT TournamentID, TournamentName, StartDate, EndDate
    FROM Tournaments
    WHERE ApprovalStatus = 'Approved';

    -- Validate if the TournamentID exists and is approved
    IF (SELECT COUNT(*) 
        FROM Tournaments 
        WHERE TournamentID = @TournamentID 
        AND ApprovalStatus = 'Approved') = 0
    BEGIN
        RAISERROR('Invalid or Unapproved TournamentID.', 16, 1);
        RETURN;
    END

    -- Step 2: Insert booking details into the Bookings table
    INSERT INTO Bookings (FacilityID, UserID, BookingType, TournamentID, StartDateTime, EndDateTime, TotalAmountOfPeople)
    VALUES (
        F1, -- FacilityID 
        SYSTEM_USER, -- UserID of the logged-in user
        'Tournament', -- BookingType
        @TournamentID, -- TournamentID provided by the organizer
        GETDATE(), -- StartDateTime (current date and time)
        DATEADD(HOUR, 3, GETDATE()), -- EndDateTime (3 hours from now)
        100 -- TotalAmountOfPeople 
    );

    PRINT 'Booking successfully created for TournamentID: ' + @TournamentID;
END;

-- Step 1: Create the TournamentOrganizer role
CREATE ROLE TournamentOrganizer;

-- Step 2: Create login and user for the Tournament Organizer
CREATE LOGIN TO001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER TO001 FOR LOGIN TO001;

-- Step 3: Add the user to the TournamentOrganizer role
EXEC sp_addrolemember 'TournamentOrganizer', 'TO001';

-- Step 4: Grant SELECT permission on Tournaments and EXECUTE on BookTournament
GRANT SELECT ON dbo.Tournaments TO TournamentOrganizer;
GRANT EXECUTE ON dbo.BookTournament TO TournamentOrganizer;

-- Valid EXEC 
EXEC BookTournament @TournamentID = 'T001';
REVERT;

-- Invalid EXEC 
EXEC BookTournament @TournamentID = 1;
REVERT;

drop procedure BookTournament
