USE DanceOfBlades;
go

/*
	### --- RANKINGS --- ###
*/
/*
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'ranking')
BEGIN
	EXEC('CREATE SCHEMA ranking');
END
go

ALTER AUTHORIZATION ON SCHEMA::ranking TO webPageUser;
go
*/

-- procedures - create ranking schema
-- -- PVP
DROP PROCEDURE IF EXISTS create_pvp_ranking_table;
go

CREATE PROCEDURE create_pvp_ranking_table
AS
BEGIN
	BEGIN TRY
		/* prepare group & datafiles */
		EXEC create_table_datafile 'pvp', 'FG_PVP', 4;

		/* create table */
		CREATE TABLE pvp (
			id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_pvp_uuid DEFAULT NEWID(),
			first_player_id UNIQUEIDENTIFIER NOT NULL,
			second_player_id UNIQUEIDENTIFIER NOT NULL,
			start_battle_date DATETIME NOT NULL CONSTRAINT DF_pvp_start_battle_date DEFAULT GETDATE(),	-- but battle can be planned
			duration_time TIMESTAMP,
			winner UNIQUEIDENTIFIER NULL,
			place VARCHAR(36),
			CONSTRAINT PK_pvp_uuid PRIMARY KEY (id),
			CONSTRAINT FK_pvp_first_player_uuid FOREIGN KEY (first_player_id) REFERENCES [user](id),
			CONSTRAINT FK_pvp_second_player_uuid FOREIGN KEY (second_player_id) REFERENCES [user](id),
			CONSTRAINT FK_pvp_winner_uuid FOREIGN KEY (winner) REFERENCES [user](id)	-- error when many battles don't have result - solve using unique index when winner isn't null insteda of ....?
		);

		/* change table schema */
		IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pvp')
		BEGIN
			--ALTER SCHEMA ranking TRANSFER dbo.pvp;

				/* create indexs */
			CREATE UNIQUE CLUSTERED INDEX PK_pvp_uuid ON pvp(id) WITH (DROP_EXISTING=ON) ON FG_PVP;		-- change filegroup and files for table

			CREATE NONCLUSTERED INDEX IX_pvp_first_player ON pvp(first_player_id);	-- columns for join operation - FK

			CREATE NONCLUSTERED INDEX IX_pvp_second_player ON pvp(second_player_id);	-- columns for join operation - FK

			CREATE NONCLUSTERED INDEX IX_pvp_start_battle_date ON pvp(start_battle_date);	-- column used to partitioning!
		END;
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE();
        ROLLBACK TRAN;
	END CATCH
END
go

-- -- STONE OF FREEDOM - stone containing list of adventurers defeating floor's boss
DROP PROCEDURE IF EXISTS create_stone_of_freedom;
go

CREATE OR ALTER PROCEDURE create_stone_of_freedom
AS
BEGIN
		/* prepare group & datafiles */
	EXEC create_table_datafile 'stone_of_freedom', 'FG_STONE_OF_FREEDOM', 1;

	/* create table */
	CREATE TABLE [stone_of_freedom] (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_stone_of_freedom_uuid DEFAULT NEWID(),
		avatar_id UNIQUEIDENTIFIER NOT NULL,
		dungon VARCHAR(60) NOT NULL,
		-- dungeon_id UNIQUEIDENTIFIER NOT NULL,
		battle_date DATETIME NOT NULL CONSTRAINT DF_stone_of_freedom_battle_date DEFAULT GETDATE(),
		CONSTRAINT PK_stone_of_freedom_uuid PRIMARY KEY (id),
		CONSTRAINT FK_stone_of_freedom_avatar FOREIGN KEY (avatar_id) REFERENCES avatar(id),
		-- CONSTRAINT FK_stone_of_freedom_dungeon FOREIGN KEY (dungeon_id) REFERENCES dungeon(id)
	);

	CREATE UNIQUE CLUSTERED INDEX PK_stone_of_freedom_uuid ON stone_of_freedom(id) WITH (DROP_EXISTING=ON) ON FG_STONE_OF_FREEDOM;		-- change filegroup and files for table
	
	CREATE NONCLUSTERED INDEX IX_stone_of_freedom_avatar ON stone_of_freedom(avatar_id);
	--CREATE NONCLUSTERED INDEX IX_stone_of_freedom_dungeon ON stone_of_freedom(dungeon_id);
END
go

-- -- -- CUSTOM RANKING
-- DROP PROCEDURE IF EXISTS create_new_ranking_table;
-- go

-- CREATE OR ALTER PROCEDURE create_new_ranking_table (@ranking_name VARCHAR(40))
-- AS
-- BEGIN
-- 	/* prepare group & datafiles */
-- 	DECLARE @group_name VARCHAR(35) = 'FG_' + UPPER(@ranking_name);
-- 	EXEC create_table_datafile @ranking_name, @group_name, 2;

-- 	DECLARE @comand VARCHAR(550);

-- 	/* create table 1:1 */
-- 	SET @comand = N'CREATE TABLE ' + @ranking_name + ' ( ' +
-- 			'id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_' + @ranking_name + '_uuid DEFAULT NEWID(), ' +
-- 			'participant_id UNIQUEIDENTIFIER NOT NULL, ' +
-- 			'join_date DATETIME NOT NULL CONSTRAINT DF_' + @ranking_name + '_join_date DEFAULT GETDATE(), ' +
-- 			'score INT NOT NULL CONSTRAINT DF_' + @ranking_name + '_score DEFAULT 0, ' +
-- 			-- 'ranking_book_id UNIQUEIDENTIFIER NOT NULL, ' +		-- are this field make sense????
-- 			'CONSTRAINT PK_' + @ranking_name + '_uuid PRIMARY KEY (id), ' +
-- 			'CONSTRAINT FK_' + @ranking_name + '_user_uuid FOREIGN KEY (participant_id) REFERENCES avatar(id), ' +
-- 			'CONSTRAINT UNQ_' + @ranking_name + '_participant UNIQUE (participant_id) ' + -- there cannot be two same participants
-- 			-- 'CONSTRAINT FK_' + @ranking_name + '_ranking_book_uuid FOREIGN KEY (ranking_book_id) REFERENCES menu(id), ' +
-- 		');'
-- 	EXEC(@comand);
-- 	PRINT(@comand);
		
-- 	/* change table schema */
-- 	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @ranking_name)
-- 	BEGIN
-- 		--SET @comand = N'ALTER SCHEMA ranking TRANSFER dbo.' + @ranking_name;				/* !!! ERROR !!! */
-- 		--PRINT(@comand);
-- 		--EXEC(@comand);
		
-- 			/* create indexs */
-- 		SET @comand = N'CREATE UNIQUE CLUSTERED INDEX PK_' + @ranking_name + '_uuid ON ' + @ranking_name + '(id) WITH (DROP_EXISTING=ON) ON ' + @group_name + ';';	-- change filegroup and files for table
-- 		EXEC(@comand);
-- 		PRINT(@comand);

-- 		SET @comand = N'CREATE NONCLUSTERED INDEX INDEX_' + @ranking_name + '_participant ON ' + @ranking_name + '(participant_id)';	-- column for join operation - FK
-- 		EXEC(@comand);
-- 		PRINT(@comand);

-- 	END;
-- END
-- go

-- tables
INSERT INTO [selection] VALUES
(default, 'PVP', 'EVENT_TYPE', null, GETDATE()),
(default, 'BOSS_RAID', 'EVENT_TYPE', null, GETDATE()),
(default, 'RAID', 'EVENT_TYPE', null, GETDATE()),
(default, 'TOURNAMENT', 'EVENT_TYPE', null, GETDATE());

DROP TABLE IF EXISTS [events_book];
go

CREATE TABLE [events_book]
(
	[id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_events_book_uuid DEFAULT NEWID(),
	[name] VARCHAR(40) NOT NULL,
	[slug] VARCHAR(40) NOT NULL,
	[description] VARCHAR(400),
	[level] TINYINT NOT NULL CONSTRAINT DF_events_book_level DEFAULT 1,
	[registration_opening_date] DATETIME2 NOT NULL CONSTRAINT DF_rankings_book_registration_opening_date DEFAULT GETDATE(),
	[start_event_date] DATETIME2 CONSTRAINT DF_events_book_start_event_date DEFAULT GETDATE(),
	[end_event_date] DATETIME2 NULL,
	[type] VARCHAR(25),	--np TURNAMENT, RAIDS, 
	CONSTRAINT PK_rankings_book_uuid PRIMARY KEY (id)
);
go

CREATE NONCLUSTERED INDEX IX_events_book_name ON events_book(name); 
go
	-- TODO: partition by start_event_date

-- create trigger - create new table afted insert new record to 'book' table
-- DLM trigger
-- DROP TRIGGER IF EXISTS create_new_ranking;
-- go 

-- CREATE TRIGGER create_new_ranking
-- ON rankings_book
-- AFTER INSERT
-- AS

-- 	DECLARE @name VARCHAR(40);
-- 	SELECT @name = slug FROM inserted;

-- 	IF (SELECT CAST (CASE WHEN type IN ('PVP') THEN 1 ELSE 0 END AS bit) FROM inserted) = 1
-- 	BEGIN
-- 			EXEC create_pvp_ranking_table;
-- 	END
-- 	ELSE IF (SELECT CAST (CASE WHEN type IN ('RAID', 'TOURNAMENT') THEN 1 ELSE 0 END AS bit) FROM inserted) = 1
-- 	BEGIN
-- 		EXEC create_new_ranking_table @name;
-- 	END
-- 	ELSE
-- 		PRINT('unrecognized ranking type')

-- 	-- TODO: add other rankings schemas !!!
-- 	/*
-- 	.
-- 	.
-- 	*/
-- go

-- -- ADD DROP TRIGGER - remove tables related to rankings_book
-- DROP TRIGGER IF EXISTS remove_ranking;
-- go 

-- CREATE TRIGGER remove_ranking
-- ON rankings_book
-- AFTER DELETE
-- AS
-- 	DECLARE @comand VARCHAR(80);
-- 	SET @comand = 'DROP TABLE IF EXISTS ' + (SELECT slug FROM deleted);

-- 	EXEC(@comand);
-- 	PRINT(@comand);
-- go

CREATE OR ALTER TRIGGER events_validator
ON events_book
INSTEAD OF INSERT
AS
	IF(NOT EXISTS (SELECT type FROM inserted WHERE type IN (SELECT name FROM selection WHERE type = 'EVENT_TYPE')))
	BEGIN
		RAISERROR('Invalid type - this type don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO events_book SELECT * FROM inserted;
	END
GO
/* defaulty create pvp table */
INSERT INTO events_book VALUES (default, 'pvp', 'pvp', 'some description', default, default, default, NULL, 'PVP');
INSERT INTO events_book VALUES (default, 'stone of freedom', 'stone-of-freedom', 'Stone containing the list of groups members defeating boss of each floor', default, default, default, NULL, 'BOSS_RAID');

/* delete ranking -- TEST */
--DELETE FROM rankings_book WHERE name = 'pvp';

/* create ranking -- TEST */
--INSERT INTO rankings_book VALUES (default, 'pioniers', 'pioniers', 'boks of pioniers achaivements', default, null, 'RAID');

--SELECT * FROM rankings_book;


/*
SELECT * FROM sys.triggers;
SELECT * FROM sys.trigger_events;
*/

/*
SELECT t.name, te.type_desc, t.is_disabled
FROM sys.trigger_events AS te
	INNER JOIN sys.triggers AS t
		ON t.object_id = te.object_id;
*/

--SELECT * FROM sys.master_files;

-- RAID
DROP TABLE IF EXISTS [event_participant];

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'event_participant')
BEGIN
	EXEC create_table_datafile 'event_participant', 'FG_EVENT_PARTICIPANT', 2;

	CREATE TABLE [event_participant]
	(
		[event_id] UNIQUEIDENTIFIER NOT NULL,
		[avatar_id] UNIQUEIDENTIFIER NOT NULL,
		[join_member_date] DATETIME2 CONSTRAINT DF_raid_participant_join_member_date DEFAULT GETDATE(),
		[score] INTEGER,

		CONSTRAINT PK_event_participant PRIMARY KEY ([event_id], [avatar_id]),
		CONSTRAINT FK_event_participant_event FOREIGN KEY ([event_id]) REFERENCES [events_book](id),
		CONSTRAINT FK_event_participant_avatar FOREIGN KEY ([avatar_id]) REFERENCES [avatar](id),
		CONSTRAINT UNQ_event_participant UNIQUE ([event_id], [avatar_id])
	);
END
go

CREATE UNIQUE CLUSTERED INDEX PK_event_participant ON [event_participant]([event_id], [avatar_id]) WITH (DROP_EXISTING=ON) ON FG_EVENT_PARTICIPANT;

-- RAID BOSSES
DROP TABLE IF EXISTS [event_boss];

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'event_boss')
BEGIN
	EXEC create_table_datafile 'event_boss', 'FG_EVENT_BOSS', 2;

	CREATE TABLE [event_boss]
	(
		[event_id] UNIQUEIDENTIFIER NOT NULL,
		[boss_id] UNIQUEIDENTIFIER NOT NULL,
		[difficultness_level] TINYINT NOT NULL CONSTRAINT DF_event_boss_diff_lvl DEFAULT 1 CONSTRAINT CK_event_boss_diff_lvl CHECK ([difficultness_level] BETWEEN 1 AND 10 ),
		[points] TINYINT NOT NULL,

		CONSTRAINT PK_event_boss PRIMARY KEY ([event_id], [boss_id]),
		CONSTRAINT FK_event_boss_raid_uuid FOREIGN KEY ([event_id]) REFERENCES [events_book]([id]),
		CONSTRAINT FK_event_boss_boss_uuid FOREIGN KEY (boss_id) REFERENCES [boss]([id])
	);

	CREATE UNIQUE CLUSTERED INDEX PK_event_boss ON [event_boss]([event_id], [boss_id]) WITH (DROP_EXISTING=ON) ON FG_EVENT_BOSS;

	CREATE NONCLUSTERED INDEX IX_event_boss_event_uuid ON [event_boss]([event_id]);	-- create index for fk key
	CREATE NONCLUSTERED INDEX IX_event_boss_boss_uuid ON [event_boss]([boss_id]);	-- create index for fk key
END
go


-- RAID BOSSES
DROP TABLE IF EXISTS [raid_boss_opponent];

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'raid_boss_opponent')
BEGIN
	EXEC create_table_datafile 'raid_boss_opponent', 'FG_RAID_BOSS_OPPONENT', 2;

	CREATE TABLE [raid_boss_opponent]
	(
		[raid_boss_raid_id] UNIQUEIDENTIFIER NOT NULL,
		[raid_boss_boss_id] UNIQUEIDENTIFIER NOT NULL,
		[avatar_id] UNIQUEIDENTIFIER NOT NULL,
		[guild_member] VARCHAR(35) NULL,
		[damage] INT CONSTRAINT DF_raid_boss_opponent_damage DEFAULT 0 CONSTRAINT CK_raid_boss_opponent_damage CHECK ([damage] >= 0),
		[magic_damage] INT CONSTRAINT DF_raid_boss_opponent_magic_damage DEFAULT 0 CONSTRAINT CK_raid_boss_opponent_magic_damage CHECK ([magic_damage] >= 0),
		[defense] INT CONSTRAINT DF_raid_boss_opponent_defense DEFAULT 0 CONSTRAINT CK_raid_boss_opponent_defense CHECK ([defense] >= 0),
		[magic_defense] INT CONSTRAINT DF_raid_boss_opponent_magic_defense DEFAULT 0 CONSTRAINT CK_raid_boss_opponent_magic_defense CHECK ([magic_defense] >= 0),
		
		CONSTRAINT PK_raid_boss_opponent PRIMARY KEY ([raid_boss_raid_id], [raid_boss_boss_id], [avatar_id]),
		CONSTRAINT FK_raid_boss_opponent_raid_boss FOREIGN KEY ([raid_boss_raid_id], [raid_boss_boss_id]) REFERENCES [event_boss]([event_id], [boss_id]),
		CONSTRAINT FK_raid_boss_opponent_avatar FOREIGN KEY ([avatar_id]) REFERENCES [avatar]([id])
	);

	CREATE UNIQUE CLUSTERED INDEX PK_raid_boss_opponent ON [raid_boss_opponent]([raid_boss_raid_id], [raid_boss_boss_id], [avatar_id]) WITH (DROP_EXISTING=ON) ON FG_RAID_BOSS_OPPONENT;

	CREATE NONCLUSTERED INDEX IX_raid_boss_opponent_raid_uuid ON [raid_boss_opponent]([raid_boss_raid_id]);	-- create index for fk key
	CREATE NONCLUSTERED INDEX IX_raid_boss_opponent_boss_uuid ON [raid_boss_opponent]([raid_boss_boss_id]);	-- create index for fk key

END
go

-- RADI MAP
DROP TABLE IF EXISTS [event_map];

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'event_map')
BEGIN
	EXEC create_table_datafile 'event_map', 'FG_EVENT_MAP', 2;

	CREATE TABLE [event_map]
	(
		[event_id] UNIQUEIDENTIFIER NOT NULL,
		[map_id] UNIQUEIDENTIFIER NOT NULL,

		CONSTRAINT PK_event_map PRIMARY KEY ([event_id], [map_id]),
		CONSTRAINT FK_event_map_raid_uuid FOREIGN KEY ([event_id]) REFERENCES [events_book]([id]),
		CONSTRAINT FK_event_map_map_uuid FOREIGN KEY (map_id) REFERENCES [map]([id])
	);

	CREATE UNIQUE CLUSTERED INDEX PK_event_map ON [event_map]([event_id], [map_id]) WITH (DROP_EXISTING=ON) ON FG_EVENT_MAP;

	CREATE NONCLUSTERED INDEX IX_event_map_event_uuid ON [event_map]([event_id]);	-- create index for fk key
	CREATE NONCLUSTERED INDEX IX_event_map_map_uuid ON [event_map]([map_id]);	-- create index for fk key
END
go

-- ----------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS tournament;

EXEC create_table_datafile 'tournament', 'FG_TOURNAMENT', 2;

CREATE TABLE tournament
(
	[id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_tournament_uuid DEFAULT NEWID(),
	[name] UNIQUEIDENTIFIER NOT NULL,
	[avatar] UNIQUEIDENTIFIER NOT NULL,
	[join_member_date] DATETIME CONSTRAINT DF_tournament_join_member_date DEFAULT GETDATE(),
	[score] INTEGER,

	CONSTRAINT PK_tournament_uuid PRIMARY KEY (id),
	CONSTRAINT FK_tournament_name_uuid FOREIGN KEY (name) REFERENCES [events_book](id),
	CONSTRAINT FK_tournament_user_uuid FOREIGN KEY ([avatar]) REFERENCES [avatar](id),
	CONSTRAINT UNQ_tournament UNIQUE ([name], [avatar])
);
GO
