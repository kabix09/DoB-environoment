USE DanceOfBlades;
go

-- USER TABLE
DROP TABLE IF EXISTS [user];
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'user')
BEGIN
	/* prepare group & datafiles */
	EXEC create_table_datafile 'user', 'FG_USER', 2;

	/* create table */
	CREATE TABLE [user] (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_user_uuid DEFAULT NEWID(),
		email VARCHAR(55) NOT NULL,
		password VARCHAR(255) NOT NULL,
		roles VARCHAR(255) NOT NULL CONSTRAINT DF_user_role DEFAULT '["ROLE_USER"]',
		last_login_date DATETIME2(6) NOT NULL CONSTRAINT DF_user_last_login DEFAULT GETDATE(),
		create_account_date DATETIME2(6) NOT NULL CONSTRAINT DF_user_create_date DEFAULT GETDATE(),
		accept_terms_date DATETIME2(6) NULL,
		is_active BIT NOT NULL CONSTRAINT DF_user_is_active DEFAULT 0
		CONSTRAINT PK_user_uuid PRIMARY KEY (id),
		CONSTRAINT UNQ_user_email UNIQUE (email),
	);
	CREATE UNIQUE CLUSTERED INDEX PK_user_uuid ON [user](id) WITH (DROP_EXISTING=ON) ON FG_USER;	-- change filegroup and files for table
	
	CREATE NONCLUSTERED INDEX IX_user_create_account_date ON [user](create_account_date);	-- column used to partitioning
END
go

-- USER KEYS
DROP TABLE IF EXISTS user_keys;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'user_keys')
BEGIN
	CREATE TABLE user_keys (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_user_keys_uuid DEFAULT NEWID(),
		value VARCHAR(255) NOT NULL,
		user_id UNIQUEIDENTIFIER NOT NULL,
		type VARCHAR(35) NOT NULL,
		create_date DATETIME2(6) NOT NULL CONSTRAINT DF_user_keys_create DEFAULT GETDATE(),
		expiration_date DATETIME2(6) NOT NULL,
		CONSTRAINT PK_user_keys_uuid PRIMARY KEY (id),
		CONSTRAINT FK_user_keys_user_id FOREIGN KEY (user_id) REFERENCES [user](id),
		CONSTRAINT CK_user_key_type CHECK (type IN ('ACTIVATE_ACCOUNT', 'OTHER'))	--ACTIVATE_ACCOUNT
	);

	CREATE NONCLUSTERED INDEX IX_user_keys_user_uuid ON user_keys(user_id);
END
go

-- GUILD TABLE
DROP TABLE IF EXISTS guild;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'guild')
BEGIN
	/* prepare group & datafiles */
	EXEC create_table_datafile 'guild', 'FG_GUILD', 3;

	/* create table */
	CREATE TABLE guild (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_guild_uuid DEFAULT NEWID(),	--	is necessary???
		name VARCHAR(35) NOT NULL,
		level TINYINT NOT NULL CONSTRAINT DF_guild_level DEFAULT 0,
		coins INT NOT NULL CONSTRAINT DF_guild_coins DEFAULT 0,
		type VARCHAR(35) NOT NULL,
		create_date DATETIME2(6) NOT NULL CONSTRAINT DF_guild_create_date DEFAULT GETDATE(),
		CONSTRAINT PK_guild_uuid PRIMARY KEY (id),
		CONSTRAINT UNQ_guild UNIQUE (name, type)
	);
	CREATE UNIQUE CLUSTERED INDEX PK_guild_uuid ON guild(id) WITH (DROP_EXISTING=ON) ON FG_GUILD;	-- change filegroup and files for table

	CREATE NONCLUSTERED INDEX IX_guild_name ON guild(name);
	CREATE NONCLUSTERED INDEX IX_user_create_date ON guild(create_date);		-- column used to partitioning
END
go

	

-- AVATAR TABLE
DROP TABLE IF EXISTS avatar;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'avatar')
BEGIN
	
	/* prepare group & datafiles */
	EXEC create_table_datafile 'avatar', 'FG_AVATAR', 2;

	/* create table 1:1 */
	CREATE TABLE [avatar] (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_avatar_uuid DEFAULT NEWID(),
		nick VARCHAR(35) NOT NULL,
		level TINYINT NOT NULL CONSTRAINT DF_avatar_level DEFAULT 1,
		race VARCHAR(15) NOT NULL,
		class VARCHAR(15) NOT NULL,
		gift VARCHAR(25) NULL,	-- talent
		specialization VARCHAR(25) NULL,
		nickname VARCHAR(30) NULL,
		--guild_id UNIQUEIDENTIFIER NULL,
		coins INT NOT NULL CONSTRAINT DF_avatar_coins DEFAULT 0,
		image VARCHAR(150) NULL,
		user_id UNIQUEIDENTIFIER NOT NULL,
		CONSTRAINT PK_avatar_uuid PRIMARY KEY (id),
		CONSTRAINT FK_avatar_user_id FOREIGN KEY (user_id) REFERENCES [user](id),
		CONSTRAINT UNQ_avatar_user_id UNIQUE (user_id)
		--CONSTRAINT FK_avatar_guild_id FOREIGN KEY (guild_id) REFERENCES guild(id)
	);
	CREATE UNIQUE CLUSTERED INDEX PK_avatar_uuid ON [avatar](id) WITH (DROP_EXISTING=ON) ON FG_AVATAR;  

	CREATE NONCLUSTERED INDEX IX_avatar_nick ON avatar(nick);
	CREATE NONCLUSTERED INDEX IX_avatar_user_uuid ON avatar(user_id);	-- columns for join operation - FK
		
		/* unlike specjalization, it has to be unique */
	CREATE UNIQUE NONCLUSTERED INDEX UNQ_IX_avatar_nickname ON avatar(nickname) WHERE nickname IS NOT NULL; -- allow to many NULL and provide unique nickname
END
go

/* prepare used selection options */
-- INSERT INTO [selection] VALUES
-- (default, 'Knight', 'AVATAR_CLASS', NULL, default),
-- (default, 'Warrior', 'AVATAR_CLASS', NULL, default),
-- (default, 'Paladin', 'AVATAR_CLASS', NULL, default),
-- (default, 'Rogue', 'AVATAR_CLASS', NULL, default),
-- (default, 'Hunter', 'AVATAR_CLASS', NULL, default),
-- (default, 'Druid', 'AVATAR_CLASS', NULL, default),
-- (default, 'Shaman', 'AVATAR_CLASS', NULL, default),
-- (default, 'Priest', 'AVATAR_CLASS', NULL, default),
-- (default, 'Mage', 'AVATAR_CLASS', NULL, default),
-- (default, 'Warlock', 'AVATAR_CLASS', NULL, default),
	
-- (default, 'Human', 'AVATAR_RACE', NULL, default),
-- (default, 'Elf', 'AVATAR_RACE', NULL, default),
-- (default, 'Dark elf', 'AVATAR_RACE', NULL, default),
-- (default, 'Dwarf', 'AVATAR_RACE', NULL, default),
-- (default, 'Giant', 'AVATAR_RACE', NULL, default),
-- (default, 'Fairy', 'AVATAR_RACE', NULL, default);
-- go

/* specjalization: enchanter (zaklinacz) */
/* nickname: titaia (kr�lowa wr�el) s*/
CREATE OR ALTER TRIGGER avatar_validator
ON avatar
INSTEAD OF INSERT
AS
	IF(NOT EXISTS (SELECT race FROM inserted WHERE race IN (SELECT name FROM selection WHERE type = 'AVATAR_RACE')))
	BEGIN
		RAISERROR('Invalid race', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(NOT EXISTS (SELECT class FROM inserted WHERE class IN (SELECT name FROM selection WHERE type = 'AVATAR_CLASS')))
	BEGIN
		RAISERROR('Invalid class', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO avatar SELECT * FROM inserted;
	END
GO

--https://www.researchgate.net/figure/The-four-types-of-players-and-their-performances-in-the-game-world_fig1_330832073
/* character class - Death, Rogue (z�odziej), Hunter, Knight, Warrior, Paladin, Druid, Shaman, Priest, Mage, Warlock (czarnoksi�nik) */
/* character race - Human, Elf, Dark elf, Dwarf, Giant, Fairy | TYPE - PURE RACE / crossbreed */

-- GUILD MEMBER TABLE
DROP TABLE IF EXISTS guild_members;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'guild_members')
BEGIN
	/* prepare group & datafiles */
	EXEC create_table_datafile 'guild_members', 'FG_GUILD_MEMBERS', 3;

	/* create table */
	CREATE TABLE guild_members (
		--id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_guild_member_uuid DEFAULT NEWID(),
		guild_id UNIQUEIDENTIFIER NOT NULL,
		avatar_id UNIQUEIDENTIFIER NOT NULL,
		--guild_name VARCHAR(35) NOT NULL,
		--guild_type VARCHAR(35) NOT NULL,
		join_date DATETIME2(6) NOT NULL CONSTRAINT DF_guild_member_join_date DEFAULT GETDATE(),
		role VARCHAR(50) NOT NULL CONSTRAINT DF_guild_member_role DEFAULT '["ROLE_MEMBER"]',
		--CONSTRAINT PK_guild_member_uuid PRIMARY KEY (id),
		--CONSTRAINT PK_guild_member PRIMARY KEY (avatar_id, guild_name, guild_type),
		CONSTRAINT PK_guild_member PRIMARY KEY (guild_id, avatar_id),
		CONSTRAINT FK_guild_member_avatar FOREIGN KEY (avatar_id) REFERENCES avatar(id),
		--CONSTRAINT FK_guild_member_guild FOREIGN KEY (guild_name, guild_type) REFERENCES guild(name, type)
		CONSTRAINT FK_guild_member_guild FOREIGN KEY (guild_id) REFERENCES guild(id),
	);

	/* rebuild clustered index associated with primary key on other file's group */
	--CREATE UNIQUE CLUSTERED INDEX PK_guild_member ON guild_members(avatar_id, guild_name, guild_type) WITH (DROP_EXISTING=ON) ON FG_GUILD_MEMBERS;  
	CREATE UNIQUE CLUSTERED INDEX PK_guild_member ON guild_members(guild_id, avatar_id) WITH (DROP_EXISTING=ON) ON FG_GUILD_MEMBERS;  

	CREATE NONCLUSTERED INDEX IX_guild_members_avatar ON guild_members(avatar_id);	-- columns for join operation - FK
	--CREATE NONCLUSTERED INDEX IX_guild_members_guild ON guild_members(guild_name, guild_type); -- columns for join operation - FK
	CREATE NONCLUSTERED INDEX IX_guild_members_guild ON guild_members(guild_id);
END
go

--DELETE FROM [user] WHERE email='hermes06@gmail.com';
--SELECT * FROM user_keys;
/*
	SELECT * FROM sys.filegroups;
	SELECT * FROM sys.database_files;
*/

-- SELECT * FROM sys.partition_schemes;

/*
SELECT p.function_id, p.name, r.value
FROM sys.partition_range_values AS r
	JOIN sys.partition_functions AS p
		ON p.function_id = r.function_id;
*/
--SELECT * FROM sys.partition_functions;
--SELECT * FROM sys.partition_range_values;


/*
	-- example function & schema

	/* create partition logic - create 4 partitions */
	/*
	IF NOT EXISTS (SELECT * FROM sys.partition_functions WHERE name = 'fn_user_partition')
	BEGIN
		CREATE PARTITION FUNCTION fn_user_partition (DATETIME)
		AS RANGE LEFT
		FOR VALUES
		(
			GETDATE(),
			DATEADD(YEAR, +2, GETDATE()),
			DATEADD(YEAR, +4, GETDATE())
		)
	END

	IF NOT EXISTS (SELECT * FROM sys.partition_schemes WHERE name = 's_user_create_account_date')
	BEGIN
		CREATE PARTITION SCHEME s_user_create_account_date
		AS PARTITION fn_user_partition
		ALL TO (FG_USER);
	END
	*/
	--CREATE UNIQUE CLUSTERED INDEX PK_user_uuid ON [user](id);	-- WITH (DROP_EXISTING=ON) ON FG_USER - PRIMARY KEY index MUST be UNIQUE  (index != constrain but must contain the same fields)
*/