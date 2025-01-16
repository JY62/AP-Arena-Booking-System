-- Create a SQL Server login
CREATE LOGIN TestLogin WITH PASSWORD = 'YourStrongPasswordHere!';

-- Create a user for testing
USE APArenaDB;
CREATE USER TestUser FOR LOGIN TestLogin;

-- Grant SELECT permission
GRANT SELECT ON [User] TO TestUser;
-- Deny UNMASK permission (to ensure masking is applied)
DENY UNMASK TO TestUser;

-- Switch to the TestUser context
EXECUTE AS USER = 'TestUser';

-- Run the SELECT query to verify masking
SELECT * FROM [User];

-- Revert back to the original user
REVERT;


