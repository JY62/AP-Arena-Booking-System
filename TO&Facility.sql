-- Create the database if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DBSAssignment')
BEGIN
    CREATE DATABASE DBSAssignment;
END
GO

USE DBSAssignment;
GO

-- Creating Tournament Organizer Table
CREATE TABLE TournamentOrganizer (
    OrganizerID VARCHAR(8) PRIMARY KEY,
    BusinessName VARCHAR(100),
    BusinessRegistrationNumber VARCHAR(50),
    Address VARCHAR(255),
    ApprovalStatus VARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT chk_organizer_id CHECK (OrganizerID LIKE 'O%' AND LEN(OrganizerID) = 8),
    CONSTRAINT chk_business_reg_num CHECK (BusinessRegistrationNumber NOT LIKE '%[^A-Za-z0-9]%'),
    CONSTRAINT chk_approval_status CHECK (ApprovalStatus IN ('Approved', 'Pending', 'Denied'))
);
GO

-- Creating Facility Table
CREATE TABLE Facility (
    FacilityID VARCHAR(8) PRIMARY KEY,
    FacilityType VARCHAR(50),
    Name VARCHAR(100),
    Capacity INT,
    RatePerHour DECIMAL(10,2),
    AvailabilityStatus BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT chk_facility_id CHECK (FacilityID LIKE 'B%' AND LEN(FacilityID) = 8),
    CONSTRAINT chk_facility_type CHECK (FacilityType IN ('Volleyball court', 'Basketball court', 
                                                        'Badminton court', 'Tennis court', 
                                                        'Swimming pool', 'Gym')),
    CONSTRAINT chk_capacity CHECK (Capacity > 0 AND Capacity <= 9999),
    CONSTRAINT chk_rate CHECK (RatePerHour >= 0)
);
GO

-- Sample data for TournamentOrganizer table
INSERT INTO TournamentOrganizer 
(OrganizerID, BusinessName, BusinessRegistrationNumber, Address, ApprovalStatus) 
VALUES
('O2023001', 'SportsMaster Events', 'BR789456123', '123 Sports Complex Avenue, Level 2, Block A, Jakarta Selatan', 'Approved'),
('O2023002', 'Elite Tournament Solutions', 'BR456789012', '45 Championship Road, Tower B, Level 5, Jakarta Pusat', 'Approved'),
('O2023003', 'Victory Sports Management', 'BR123789456', '78 Victory Lane, Block C, Jakarta Barat', 'Pending'),
('O2023004', 'Champions United', 'BR987321654', '234 Tournament Street, Level 1, Jakarta Timur', 'Approved'),
('O2023005', 'Pro League Organizations', 'BR654987321', '567 Sports Avenue, Block D, Jakarta Utara', 'Denied'),
('O2023006', 'GameDay Events', 'BR321654987', '890 Competition Road, Level 3, Bekasi', 'Pending'),
('O2023007', 'Sports Excellence Corp', 'BR147258369', '432 Athletic Drive, Block E, Tangerang', 'Approved'),
('O2023008', 'Tournament Pros Indonesia', 'BR258369147', '765 Championship Avenue, Level 4, Depok', 'Pending');

-- Sample data for Facility table
INSERT INTO Facility 
(FacilityID, FacilityType, Name, Capacity, RatePerHour, AvailabilityStatus) 
VALUES
('B2023001', 'Volleyball court', 'Pro Volleyball Court A', 50, 75.00, 1),
('B2023002', 'Volleyball court', 'Pro Volleyball Court B', 50, 75.00, 1),
('B2023003', 'Basketball court', 'Championship Court 1', 100, 100.00, 1),
('B2023004', 'Basketball court', 'Championship Court 2', 100, 100.00, 0),
('B2023005', 'Badminton court', 'Elite Badminton Court A', 30, 50.00, 1),
('B2023006', 'Badminton court', 'Elite Badminton Court B', 30, 50.00, 1),
('B2023007', 'Tennis court', 'Grand Tennis Court', 40, 90.00, 1),
('B2023008', 'Swimming pool', 'Olympic Pool', 200, 150.00, 0),
('B2023009', 'Gym', 'Fitness Center', 80, 45.00, 1),
('B2023010', 'Tennis court', 'Center Tennis Court', 40, 90.00, 1);

-- Verify the inserted data
SELECT * FROM TournamentOrganizer ORDER BY OrganizerID;
SELECT * FROM Facility ORDER BY FacilityID;

-- Create roles
CREATE ROLE DataAdmin;
CREATE ROLE ComplexManager;
CREATE ROLE TournamentOrganizer;
CREATE ROLE IndividualCustomer;
GO

-- Grant permissions for DataAdmin
GRANT CONTROL ON DATABASE::APArenaDB TO DataAdmin;
GRANT SELECT, DELETE ON TournamentOrganizer TO DataAdmin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Facility TO DataAdmin;
DENY UPDATE ON TournamentOrganizer TO DataAdmin;
GO

-- Grant permissions for ComplexManager
GRANT SELECT ON TournamentOrganizer TO ComplexManager;
GRANT UPDATE ON TournamentOrganizer TO ComplexManager;
GRANT SELECT ON Facility TO ComplexManager;
DENY INSERT, DELETE ON TournamentOrganizer TO ComplexManager;
DENY INSERT, UPDATE, DELETE ON Facility TO ComplexManager;
GO

-- Grant permissions for TournamentOrganizer role
GRANT SELECT ON Facility TO TournamentOrganizer;
DENY INSERT, UPDATE, DELETE ON Facility TO TournamentOrganizer;
GO

-- Grant permissions for IndividualCustomer
GRANT SELECT ON Facility TO IndividualCustomer;
DENY INSERT, UPDATE, DELETE ON Facility TO IndividualCustomer;
DENY SELECT, INSERT, UPDATE, DELETE ON TournamentOrganizer TO IndividualCustomer;
GO

-- Create stored procedure for TournamentOrganizer to update their own information
CREATE PROCEDURE UpdateOwnTournamentOrganizer
    @OrganizerID VARCHAR(8),
    @BusinessName VARCHAR(100),
    @BusinessRegistrationNumber VARCHAR(50),
    @Address VARCHAR(255)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM sys.login_token WHERE usage = 'USER' AND name = @OrganizerID)
    BEGIN
        UPDATE TournamentOrganizer
        SET BusinessName = @BusinessName,
            BusinessRegistrationNumber = @BusinessRegistrationNumber,
            Address = @Address,
            UpdatedAt = GETDATE()
        WHERE OrganizerID = @OrganizerID;
    END
    ELSE
        THROW 50000, 'You can only update your own information', 1;
END;
GO

-- Create stored procedure for ComplexManager to update approval status
CREATE PROCEDURE UpdateTournamentOrganizerStatus
    @OrganizerID VARCHAR(8),
    @ApprovalStatus VARCHAR(20)
AS
BEGIN
    IF IS_MEMBER('ComplexManager') = 1
    BEGIN
        UPDATE TournamentOrganizer
        SET ApprovalStatus = @ApprovalStatus,
            UpdatedAt = GETDATE()
        WHERE OrganizerID = @OrganizerID;
    END
    ELSE
        THROW 50000, 'Insufficient privileges', 1;
END;
GO


-- Enable system versioning for Facility table
ALTER TABLE Facility
ADD 
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN
    CONSTRAINT DF_Facility_ValidFrom DEFAULT SYSUTCDATETIME(),
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN
    CONSTRAINT DF_Facility_ValidTo DEFAULT CONVERT(DATETIME2, '9999-12-31 23:59:59.9999999'),
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
GO

ALTER TABLE Facility
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.FacilitiesHistory));
GO

-- Create procedures to query historical data
CREATE PROCEDURE GetTournamentOrganizerHistory
    @OrganizerID VARCHAR(8)
AS
BEGIN
    SELECT 
        OrganizerID,
        BusinessName,
        BusinessRegistrationNumber,
        Address,
        ApprovalStatus,
        ValidFrom,
        ValidTo
    FROM TournamentOrganizer FOR SYSTEM_TIME ALL
    WHERE OrganizerID = @OrganizerID
    ORDER BY ValidFrom DESC;
END;
GO

CREATE PROCEDURE GetFacilityHistory
    @FacilityID VARCHAR(8)
AS
BEGIN
    SELECT 
        FacilityID,
        FacilityType,
        Name,
        Capacity,
        RatePerHour,
        AvailabilityStatus,
        ValidFrom,
        ValidTo
    FROM Facility FOR SYSTEM_TIME ALL
    WHERE FacilityID = @FacilityID
    ORDER BY ValidFrom DESC;
END;
GO

-- Create procedure to get changes within a date range
CREATE PROCEDURE GetChangesInDateRange
    @TableName VARCHAR(100),
    @StartDate DATETIME2,
    @EndDate DATETIME2
AS
BEGIN
    IF @TableName = 'TournamentOrganizer'
    BEGIN
        SELECT 
            OrganizerID,
            BusinessName,
            BusinessRegistrationNumber,
            Address,
            ApprovalStatus,
            ValidFrom,
            ValidTo
        FROM TournamentOrganizer FOR SYSTEM_TIME 
            BETWEEN @StartDate AND @EndDate
        ORDER BY ValidFrom DESC;
    END
    ELSE IF @TableName = 'Facility'
    BEGIN
        SELECT 
            FacilityID,
            FacilityType,
            Name,
            Capacity,
            RatePerHour,
            AvailabilityStatus,
            ValidFrom,
            ValidTo
        FROM Facility FOR SYSTEM_TIME 
            BETWEEN @StartDate AND @EndDate
        ORDER BY ValidFrom DESC;
    END
END;
GO

-- Example of querying historical data
-- Get all changes to a specific tournament organizer
EXEC GetTournamentOrganizerHistory @OrganizerID = 'O2023001';

-- Get all changes to a specific facility
EXEC GetFacilityHistory @FacilityID = 'B2023001';

-- Get all changes in a date range
EXEC GetChangesInDateRange 
    @TableName = 'TournamentOrganizer',
    @StartDate = '2024-01-01',
    @EndDate = '2024-12-31';