DROP PROCEDURE sp_DeleteRecord;
GO;

CREATE PROCEDURE DeleteRecordById
    @TableName NVARCHAR(128), -- Name of the table
    @IDColumn NVARCHAR(128),  -- Name of the ID column
    @IDValue NVARCHAR(8)      -- Value of the ID to delete
AS
BEGIN
    BEGIN TRY
        -- Verify that the provided table and column names exist to prevent SQL injection
        IF NOT EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_NAME = @TableName
        )
        BEGIN
            RAISERROR('Table does not exist.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (
            SELECT 1 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_NAME = @TableName AND COLUMN_NAME = @IDColumn
        )
        BEGIN
            RAISERROR('Column does not exist.', 16, 1);
            RETURN;
        END

        -- Build the dynamic SQL query
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'DELETE FROM ' + QUOTENAME(@TableName) + 
                   N' WHERE ' + QUOTENAME(@IDColumn) + N' = @IDValue';

        -- Execute the dynamic SQL query
        EXEC sp_executesql @SQL, N'@IDValue NVARCHAR(8)', @IDValue;
    END TRY
    BEGIN CATCH
        -- Handle any errors
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;


-- Grant execution permission exclusively for DataAdmin
GRANT EXECUTE ON OBJECT::DeleteRecordById TO DataAdmin;

-- Testing
EXECUTE AS LOGIN = 'DA0001';

EXEC DeleteRecordById @TableName = 'User', @IDColumn = 'UserID', @IDValue = 'DA0002';

REVERT
