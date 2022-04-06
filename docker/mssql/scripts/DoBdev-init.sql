IF EXISTS (SELECT * FROM sys.databases WHERE name = 'DanceOfBlades')
BEGIN
	USE master;
	
	DROP DATABASE DanceOfBlades;
END
go

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DanceOfBlades')
BEGIN
	CREATE DATABASE DanceOfBlades;
END
go

USE DanceOfBlades;
go


/* create login & user and add roles */
IF EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'webPageLogin')
BEGIN
	DROP LOGIN webPageLogin;
END
go

CREATE LOGIN webPageLogin 
	WITH PASSWORD = 'webPageLogin12',
	DEFAULT_DATABASE = DanceOfBlades;
go

IF EXISTS (SELECT * FROM sys.database_principals WHERE type_desc = 'SQL_USER' AND name = 'webPageUser')
BEGIN
	ALTER ROLE db_owner DROP MEMBER webPageUser;

	USE master;
	DROP USER webPageUser;
	USE DanceOfBlades;
END
go

CREATE USER webPageUser FOR LOGIN webPageLogin;
go

ALTER ROLE db_owner ADD MEMBER webPageUser;
go


/* helpful procedures */
CREATE OR ALTER PROCEDURE create_filegroup (
	@filegroup_name VARCHAR(30)
)
AS
BEGIN
	BEGIN TRY
		DECLARE @query VARCHAR(300);

		SET @query = 'IF NOT EXISTS (SELECT * FROM sys.filegroups WHERE name = ' + (SELECT QUOTENAME(@filegroup_name, '''')) + ') ALTER DATABASE ' + (SELECT DB_NAME()) + ' ADD FILEGROUP ' + @filegroup_name ;
	
		/* exec query */
		IF @@TRANCOUNT > 0
			BEGIN
			/*
				DECLARE @cmd VARCHAR(600) = N'sqlcmd -S . -d ' + (SELECT DB_NAME()) + N' -E -Q "' + @query + + N'" -t 15 ';
				EXEC xp_cmdshell @cmd;
				PRINT(@cmd);
			*/
				COMMIT TRANSACTION;
				EXEC (@query);
				PRINT(@query);
				BEGIN TRANSACTION;
			END
		ELSE
			BEGIN
				EXEC (@query);
				PRINT(@query);
			END
	END TRY
	BEGIN CATCH
		PRINT 'create_filegroup';
		PRINT ERROR_MESSAGE();
        ROLLBACK TRAN;
	END CATCH
	--sqlcmd -S . -d DanceOfBladesDev -E -Q "IF NOT EXISTS (SELECT * FROM sys.filegroups WHERE name = 'FG_TEST') ALTER DATABASE DanceOfBladesDev ADD FILEGROUP FG_TEST;" -t 15
	--PRINT 'sqlcmd -S . -d DanceOfBladesDev -E -Q "IF NOT EXISTS (SELECT * FROM sys.filegroups WHERE name =''FG_TEST'') ALTER DATABASE DanceOfBladesDev ADD FILEGROUP FG_TEST;" -t 15 ';
END
go

CREATE OR ALTER PROCEDURE create_table_datafile (
	@file_name VARCHAR(30),
	@group_name VARCHAR(30),
	@files_amount TINYINT 
)
AS
BEGIN
	EXEC create_filegroup @group_name;

	BEGIN TRY
		
		DECLARE @fullDataFilePath VARCHAR(150) = '/var/opt/mssql/data/';
		DECLARE @numberOfRepetitions TINYINT = 0;
		DECLARE @full_name VARCHAR(30);
		DECLARE @query VARCHAR(300);

		WHILE(@numberOfRepetitions < @files_amount)
		BEGIN
			SET @numberOfRepetitions = @numberOfRepetitions + 1;

			SET @full_name = @file_name + '_' + (SELECT CAST(@numberOfRepetitions AS VARCHAR));

			--SELECT @query = 'PRINT ' + quotename(q.file_name, '''')+';' FROM (SELECT * FROM @dataFilesList WHERE id = @point) q;
			SET @query = 'ALTER DATABASE ' + (SELECT DB_NAME()) + ' ADD FILE ( ' +
				'NAME = ' + (SELECT QUOTENAME(@full_name, '''')) + ', ' + 
				'SIZE = 8MB,  ' + 
				'FILEGROWTH = 64MB, ' + 
				'FILENAME = ' + (SELECT QUOTENAME(@fullDataFilePath + DB_NAME() + '_' + @full_name + '.ndf', '''')) + 
				' ) TO FILEGROUP ' +  (SELECT quotename(@group_name)) + ';'

			/* exec query */
			IF @@TRANCOUNT > 0
				BEGIN
				/*	
					DECLARE @cmd VARCHAR(600) = N'sqlcmd -S . -d ' + (SELECT DB_NAME()) + N' -E -Q "' + @query + + N'" -t 15 ';
					EXEC xp_cmdshell @cmd;
					PRINT(@cmd);
				*/
					COMMIT TRANSACTION;
					EXEC (@query);
					PRINT(@query);
					BEGIN TRANSACTION;
				END
			ELSE
				BEGIN
					EXEC (@query);
					PRINT(@query);
				END
		END
	END TRY
	BEGIN CATCH
		PRINT 'create_table_datafile';
		PRINT ERROR_MESSAGE();
        ROLLBACK TRAN;
	END CATCH
END
go

--SELECT * FROM INFORMATION_SCHEMA.ROUTINES;	-- WHERE LEFT(ROUTINE_NAME, 3) NOT IN ('sp_', 'xp_', 'ms_')

/*
	-- indexes info
SELECT OBJECT_NAME(OBJECT_ID), name [index_name], type_desc [index_type]
FROM sys.indexes
WHERE OBJECT_NAME(OBJECT_ID) IN ('user', 'guild', 'avatar', 'guild_members', 'rankings_book', 'menu', 'pvp')
*/

/*
	-- logins & principals info
SELECT * FROM sys.sql_logins;

SELECT * FROM sys.database_principals WHERE type_desc = 'SQL_USER';

SELECT p2.name [user_name], p1.name [role_name] FROM sys.database_role_members
	JOIN sys.database_principals AS p1 ON p1.principal_id = sys.database_role_members.role_principal_id
	JOIN sys.database_principals AS p2 ON p2.principal_id = sys.database_role_members.member_principal_id;
*/
