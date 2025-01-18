-- Use the database
USE APArenaDB;

-- Then create the stored procedure
CREATE OR ALTER PROCEDURE UpdateTournamentRegistration
    @TournamentID VARCHAR(8),
    @NewApprovalStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if the tournament exists
    IF NOT EXISTS (SELECT 1 FROM Tournaments WHERE TournamentID = @TournamentID)
    BEGIN
        THROW 51000, 'Tournament does not exist.', 1;
        RETURN;
    END

    -- Validate the new status value
    IF @NewApprovalStatus NOT IN ('Approved', 'Pending', 'Rejected')
    BEGIN
        THROW 51000, 'Invalid approval status. Must be either Approved, Pending, or Rejected.', 1;
        RETURN;
    END

    -- Update tournament status
    UPDATE Tournaments
    SET ApprovalStatus = @NewApprovalStatus
    WHERE TournamentID = @TournamentID
END;
GO

--Testing
-- Create the DataAdmin role
CREATE ROLE ComplexManager;

-- Create the CM001 login and user
CREATE LOGIN CM001 WITH PASSWORD = '123';  -- Replace with actual password
CREATE USER CM001 FOR LOGIN CM001;

-- Add CM001 user to the DataAdmin role
EXEC sp_addrolemember 'ComplexManager', 'CM001';

--GRANTING PERMISSION FOR COMPLEX MANAGER
GRANT EXECUTE ON dbo.UpdateTournamentRegistration TO ComplexManager;

GRANT SELECT ON dbo.Tournaments TO ComplexManager;

-- Log in as CM001 and execute the procedure
EXECUTE AS USER = 'CM001';
EXEC UpdateTournamentRegistration 
	@TournamentID = 'T001',
	@NewApprovalStatus = 'Approved';

REVERT;