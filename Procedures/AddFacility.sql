CREATE PROCEDURE InsertFacility
    @FacilityID VARCHAR(8),
    @FacilityType VARCHAR(50),
    @FacilityName VARCHAR(100),
    @Capacity INT,
    @RatePerHour DECIMAL(10,2),
    @AvailabilityStatus BIT = 1  -- Default to 1 (available) if not provided
AS
BEGIN
    -- Validate FacilityType against the allowed values
    IF @FacilityType NOT IN ('Volleyball court', 'Basketball court', 'Badminton court', 'Tennis court', 
                             'Swimming pool', 'Gym')
    BEGIN
        PRINT 'Error: Invalid FacilityType.';
        RETURN;
    END
    
    -- Validate Capacity range
    IF @Capacity <= 0 OR @Capacity > 9999
    BEGIN
        PRINT 'Error: Capacity must be between 1 and 9999.';
        RETURN;
    END
    
    -- Validate RatePerHour range
    IF @RatePerHour < 0
    BEGIN
        PRINT 'Error: RatePerHour cannot be negative.';
        RETURN;
    END
    
    BEGIN TRY
        -- Insert values into Facility table
        INSERT INTO Facility (FacilityID, FacilityType, FacilityName, Capacity, RatePerHour, AvailabilityStatus)
        VALUES (@FacilityID, @FacilityType, @FacilityName, @Capacity, @RatePerHour, @AvailabilityStatus);
        
        PRINT 'Insert successful.';
    END TRY
    BEGIN CATCH
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Testing
-- Create the DataAdmin role
CREATE ROLE DataAdmin;

-- Create the DA001 login and user
CREATE LOGIN DA001 WITH PASSWORD = 'yourpassword';  -- Replace with actual password
CREATE USER DA001 FOR LOGIN DA001;

-- Add DA001 user to the DataAdmin role
EXEC sp_addrolemember 'DataAdmin', 'DA001';

-- Grant EXECUTE permission on the procedure to the DataAdmin role
GRANT EXECUTE ON dbo.InsertFacility TO DataAdmin;

GRANT SELECT ON dbo.Facility TO DataAdmin;

-- Log in as DA001 and execute the procedure
EXECUTE AS USER = 'DA001';
EXEC InsertFacility 
    @FacilityID = 'F11', 
    @FacilityType = 'Swimming pool', 
    @FacilityName = 'Kids Pool', 
    @Capacity = 10, 
    @RatePerHour = 99.00;


REVERT;