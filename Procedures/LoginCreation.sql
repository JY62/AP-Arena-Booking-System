USE APArenaDB;
GO

-- CreateLogin Procedure for server login
CREATE PROCEDURE CreateLogin
    @UserType VARCHAR(50),
    @Password NVARCHAR(255),
    @GeneratedUserID VARCHAR(8) OUTPUT -- Output parameter to return UserID
AS
BEGIN
    -- Declare variables
    DECLARE @UserID VARCHAR(8);
    DECLARE @RoleName NVARCHAR(50);
    DECLARE @SQL NVARCHAR(MAX);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Generate UserID based on UserType
        IF @UserType = 'Data Admin'
            SET @UserID = 'DA' + RIGHT('0000' + CAST((NEXT VALUE FOR dbo.DataAdminSequence) AS VARCHAR(4)), 4);
        ELSE IF @UserType = 'Complex Manager'
            SET @UserID = 'CM' + RIGHT('0000' + CAST((NEXT VALUE FOR dbo.ComplexManagerSequence) AS VARCHAR(4)), 4);
        ELSE IF @UserType = 'Tournament Organizer'
            SET @UserID = 'TO' + RIGHT('0000' + CAST((NEXT VALUE FOR dbo.TournamentOrganizerSequence) AS VARCHAR(4)), 4);
        ELSE IF @UserType = 'Individual Customers'
            SET @UserID = 'IC' + RIGHT('0000' + CAST((NEXT VALUE FOR dbo.IndividualCustomerSequence) AS VARCHAR(4)), 4);
        -- Determine role name based on UserType
        SET @RoleName = 
            CASE 
                WHEN @UserType = 'Data Admin' THEN 'DataAdmin'
                WHEN @UserType = 'Complex Manager' THEN 'ComplexManager'
                WHEN @UserType = 'Tournament Organizer' THEN 'TournamentOrganizer'
                WHEN @UserType = 'Individual Customers' THEN 'IndividualCustomer'
                ELSE NULL
            END;
        -- Build and execute dynamic SQL for creating the login
        SET @SQL = N'CREATE LOGIN [' + @UserID + N'] WITH PASSWORD = ''' + @Password + N''';';
        EXEC sp_executesql @SQL;
        -- Assign login to the respective role
        EXEC sp_addrolemember @RoleName, @UserID;
        -- Assign the generated UserID to the output parameter
        SET @GeneratedUserID = @UserID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Steps to test CreateLogin and CreateAccount
-- Create the sequence object for generating unique numeric IDs (Run only once)
CREATE SEQUENCE dbo.DataAdminSequence AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.ComplexManagerSequence AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.TournamentOrganizerSequence AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE dbo.IndividualCustomerSequence AS INT START WITH 1 INCREMENT BY 1;
GO

-- Execute the CreateLogin procedure to create a new login
DECLARE @GeneratedUserID VARCHAR(8);
EXEC CreateLogin 
    @UserType = 'Data Admin', 
    @Password = 'SecurePassword123!', 
    @GeneratedUserID = @GeneratedUserID OUTPUT;

-- View the Generated UserID. Then, use this UserID for account login
SELECT @GeneratedUserID AS GeneratedUserID;
GO