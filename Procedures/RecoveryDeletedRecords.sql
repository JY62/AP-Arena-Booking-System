USE [APArenaDB];
GO

CREATE PROCEDURE RecoverDeletedRecord
    @ID NVARCHAR(50),
    @TableName NVARCHAR(255),
    @IDColumn NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declare variables to construct dynamic SQL
    DECLARE @HistoryTable NVARCHAR(255);
    DECLARE @DynamicSQL NVARCHAR(MAX);
    DECLARE @ColumnList NVARCHAR(MAX);

    -- Construct the name of the history table
    SET @HistoryTable = @TableName + 'History';

    -- Check if the history table exists
    IF NOT EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = @HistoryTable
    )
    BEGIN
        RAISERROR('The history table %s does not exist.', 16, 1, @HistoryTable);
        RETURN;
    END

    -- Get the column list of the original table
    SELECT @ColumnList = STRING_AGG(QUOTENAME(COLUMN_NAME), ', ')
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @TableName
      AND TABLE_SCHEMA = 'dbo'; -- Adjust schema if needed

    -- Construct the dynamic SQL to recover the deleted record
    SET @DynamicSQL = '
        INSERT INTO ' + QUOTENAME(@TableName) + ' (' + @ColumnList + ')
        SELECT ' + @ColumnList + '
        FROM ' + QUOTENAME(@HistoryTable) + '
        WHERE ' + QUOTENAME(@IDColumn) + ' = @ID 
          AND OperationType = ''DELETE'' 
          AND ChangeDate = (
              SELECT MAX(ChangeDate)
              FROM ' + QUOTENAME(@HistoryTable) + '
              WHERE ' + QUOTENAME(@IDColumn) + ' = @ID AND OperationType = ''DELETE''
          )
    ';

    -- Execute the dynamic SQL
    EXEC sp_executesql @DynamicSQL, N'@ID NVARCHAR(50)', @ID = @ID;
    PRINT 'Record has been successfully recovered.';
END;

GRANT EXECUTE ON OBJECT::dbo.RecoverDeletedRecord TO DataAdmin;

-- Testing
EXECUTE AS LOGIN = 'DA0001';

EXEC RecoverDeletedRecord @ID = 'DA0002', @TableName = 'User', @IDColumn = 'UserID';

REVERT;
