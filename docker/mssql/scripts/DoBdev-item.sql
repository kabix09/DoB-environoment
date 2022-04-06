USE DanceOfBlades
go

DROP TABLE IF EXISTS [item];
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'item')
BEGIN
	EXEC create_table_datafile 'item', 'FG_ITEM', 2;

	CREATE TABLE [item] (
		[id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_item_uuid DEFAULT NEWID(),
		[name] VARCHAR(75) NOT NULL,
		[description] VARCHAR(255) NULL,
		[level] TINYINT CONSTRAINT CK_item_level CHECK ([level] >=1 AND [level] <= 9) CONSTRAINT DF_item_level DEFAULT 1,
		[type] VARCHAR(30) NOT NULL,
		[group] VARCHAR(30) NOT NULL CONSTRAINT DF_item_group DEFAULT 'other',
		-- ciezkosc
		-- value - power / deffence 
		[value] INTEGER NOT NULL,
		--[value_type] VARCHAR(50) NOT NULL, -- deffensive, offensive, support
		[required_user_level] TINYINT CONSTRAINT CK_item_required_user_level CHECK ([required_user_level] >=1),
		[image] VARCHAR(120) NOT NULL,
		
		CONSTRAINT PK_item_uuid PRIMARY KEY (id)
	)

	CREATE UNIQUE CLUSTERED INDEX PK_item_uuid ON [item](id) WITH (DROP_EXISTING=ON) ON FG_ITEM;  

	-- prepare selections for validator
	INSERT INTO [selection] VALUES
		(default, 'Weapon', 'ITEM_GROUP', null, default),
		(default, 'Outfit', 'ITEM_GROUP', null, default),
		(default, 'Magic item', 'ITEM_GROUP', null, default),
		(default, 'Other', 'ITEM_GROUP', null, default);

	DECLARE @weapon UNIQUEIDENTIFIER = (SELECT id FROM [selection] WHERE name = 'Weapon' );
	DECLARE @outfit UNIQUEIDENTIFIER = (SELECT id FROM [selection] WHERE name = 'Outfit' );
	DECLARE @magicItem UNIQUEIDENTIFIER = (SELECT id FROM [selection] WHERE name = 'Magic item' );
	DECLARE @other UNIQUEIDENTIFIER = (SELECT id FROM [selection] WHERE name = 'Other' );

	INSERT INTO [selection] VALUES
		(default, 'Sword', 'ITEM_TYPE', @weapon, default),
		(default, 'Half sword', 'ITEM_TYPE', @weapon, default),
		(default, 'Knife', 'ITEM_TYPE', @weapon, default),
		(default, 'Two-handed sword', 'ITEM_TYPE', @weapon, default),
		(default, 'Axe', 'ITEM_TYPE', @weapon, default),
		(default, 'Hammer', 'ITEM_TYPE', @weapon, default),
		(default, 'Staff', 'ITEM_TYPE', @weapon, default),
		(default, 'Wand', 'ITEM_TYPE', @weapon, default),
		(default, 'Magic sword', 'ITEM_TYPE', @weapon, default),
		
		(default, 'Shield', 'ITEM_TYPE', @outfit, default),
		(default, 'Armor', 'ITEM_TYPE', @outfit, default),
		(default, 'Shoes', 'ITEM_TYPE', @outfit, default),
		(default, 'Gloves', 'ITEM_TYPE', @outfit, default),
		(default, 'Coat', 'ITEM_TYPE', @outfit, default),

		(default, 'Grimuar', 'ITEM_TYPE', @magicItem, default),
		(default, 'Scrool', 'ITEM_TYPE', @magicItem, default),

		(default, 'Potion', 'ITEM_TYPE', @other, default);
END
GO
-- check the correctness
CREATE OR ALTER TRIGGER item_type_validator
ON [item]
INSTEAD OF INSERT
AS

	IF(NOT EXISTS (SELECT * FROM inserted WHERE [group] IN (SELECT name FROM selection WHERE type = 'ITEM_GROUP')))
	BEGIN
		RAISERROR('Invalid item group - this group don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	DECLARE @groupId UNIQUEIDENTIFIER = (SELECT id FROM [selection] WHERE name = (SELECT [group] FROM [inserted]))

	IF(NOT EXISTS (SELECT *	 FROM inserted WHERE type IN (SELECT name FROM selection WHERE dependency_tag = @groupId)))
	BEGIN
		RAISERROR('Invalid item type - this type doesn`t match for group or don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO [item] SELECT * FROM inserted;
	END
GO

-- **************************************************************************************************
-- CREATE TABLE [item_bonus_desc] (
-- 	[id] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_item_bonus_uuid DEFAULT NEWID(),
-- 	[name] VARCHAR(75) NOT NULL,
-- 	[description] VARCHAR(255) NULL,
-- 	[value] 
-- );

-- -- bonus validator
-- -- check supported parameter

-- CREATE TABLE [item_bonus_] (
-- 	[item] UNIQUEIDENTIFIER NOT NULL,
-- 	[bonus] UNIQUEIDENTIFIER NOT NULL,
-- 	[value] INTEGER NOT NULL,
-- 	[supported_parameter] VARCHAR(55) NOT NULL -- speed, attach, damage, 
-- 	--	[supported_parameter] VARCHAR(55) NOT NULL -- speed, attach, damage, 
-- 	-- the same item and bonus may affect on few parameters
-- );
-- /* 
-- 	default, example name, shield
-- */

DROP TABLE IF EXISTS [boss_drop];
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'boss_drop')
BEGIN
	EXEC create_table_datafile 'boss_drop', 'FG_BOSS_DROP', 1;

	CREATE TABLE [boss_drop] (
		[item_id] UNIQUEIDENTIFIER NOT NULL,
		[boss_id] UNIQUEIDENTIFIER NOT NULL,
		[probability] FLOAT CONSTRAINT CK_boss_drop_probability CHECK ([probability] >= 0),  -- czy wartosc 0 ma sens - w praktyce oznacza ze item nie moze zostac wydropiony
		
		CONSTRAINT PK_boss_drop PRIMARY KEY (item_id, boss_id),
		CONSTRAINT FK_boss_drop_item FOREIGN KEY (item_id) REFERENCES [item](id),
		CONSTRAINT FK_boss_drop_boss FOREIGN KEY (boss_id) REFERENCES [boss](id)

	)
		CREATE UNIQUE CLUSTERED INDEX PK_boss_drop ON [boss_drop](item_id, boss_id) WITH (DROP_EXISTING=ON) ON FG_BOSS_DROP;  

		CREATE NONCLUSTERED INDEX IX_boss_drop_item ON [boss_drop](item_id);
		CREATE NONCLUSTERED INDEX IX_boss_drop_boss ON [boss_drop](boss_id);
END
GO
/*
	Page-object-info database
	
	id
	slug
	description
	create date
	edit date
	object id - item, boss, skill, 
*/