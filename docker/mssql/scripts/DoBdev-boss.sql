USE DanceOfBlades;
go

-- BOSS TABLE
DROP TABLE IF EXISTS boss;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'boss')
BEGIN
	/* prepare group & datafiles */
	EXEC create_table_datafile 'boss', 'FG_BOSS', 1;

	/* create table */
	CREATE TABLE [boss] (
		[id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_boss_uuid DEFAULT NEWID(),
		[name] VARCHAR(55) NOT NULL,	-- or maybe as foregin key to bots table
		[level] INT NOT NULL,
		[description] VARCHAR(255) NOT NULL,
		[strength] INT NOT NULL CONSTRAINT DF_boss_strength DEFAULT 2,
		[defence] INT NOT NULL CONSTRAINT DF_boss_defence DEFAULT 1,
		[health] INT NOT NULL CONSTRAINT DF_boss_health DEFAULT 150,
		[magic] INT NOT NULL CONSTRAINT DF_boss_magic DEFAULT 0,
		[speed] INT NOT NULL CONSTRAINT DF_boss_speed DEFAULT 3,
		[race] VARCHAR(55) NOT NULL,
		[slug] VARCHAR(55) NOT NULL,
		[create_date] DATETIME2 NOT NULL CONSTRAINT DF_boss_dreate_date DEFAULT GETDATE(),

		CONSTRAINT PK_boss_uuid PRIMARY KEY (id),
		CONSTRAINT CK_boss_strength CHECK (strength >= 1 AND strength <= 15),
		CONSTRAINT CK_boss_defence CHECK (defence >= 1 AND defence <= 15),
		CONSTRAINT CK_boss_magic CHECK (magic >= 0),
		CONSTRAINT CK_boss_health CHECK (health >= 0),
		CONSTRAINT CK_boss_speed CHECK (speed >= 0)

	);

	CREATE UNIQUE CLUSTERED INDEX PK_boss_uuid ON boss(id) WITH (DROP_EXISTING=ON) ON FG_BOSS;	-- change filegroup and files for table
END
go

CREATE OR ALTER TRIGGER boss_validator
ON boss
INSTEAD OF INSERT
AS
	IF(NOT EXISTS (SELECT race FROM inserted WHERE race IN (SELECT name FROM selection WHERE type = 'RACE') OR race IN (SELECT name FROM selection WHERE type = 'AVATAR_RACE')))
	BEGIN
		RAISERROR('Invalid boss race - this race don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO boss SELECT * FROM inserted;
	END
GO