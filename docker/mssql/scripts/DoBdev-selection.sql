USE DanceOfBlades;
go

-- table contains list of different types to choose
DROP TABLE IF EXISTS selection;
go

-- IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'selection')
-- BEGIN
	CREATE TABLE [selection] (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_selection_uuid DEFAULT NEWID(),
		name VARCHAR(100) NOT NULL,
		type VARCHAR(60) NOT NULL,
		dependency_tag UNIQUEIDENTIFIER NULL,
		creation_date DATETIME NOT NULL CONSTRAINT DF_selection_create_date DEFAULT GETDATE(),
		CONSTRAINT PK_selection_uuid PRIMARY KEY (id),
		CONSTRAINT FK_selection_uuid FOREIGN KEY (dependency_tag) REFERENCES [selection](id),
		CONSTRAINT UC_selection_name UNIQUE (name, type),
		CONSTRAINT CK_selection_type CHECK (type IN ('AVATAR_RACE', 'AVATAR_CLASS', 'MAP_TERRAIN', 'MAP_AREA', 'MAP_CLIMATE', 'MAP_DANGEROUS_LEVEL', 'GUILD_ACHIEVEMENT', 'EVENT_TYPE', 'RACE', 'ITEM_GROUP', 'ITEM_TYPE')), -- table name _ table field [, 'MAP_TYPE', 'MAP_REGION']
	)
	go

	CREATE OR ALTER TRIGGER selector_validator
	ON [selection]
	INSTEAD OF INSERT
	AS
		IF(EXISTS (
			SELECT * FROM [selection] WHERE (
				(name IN (SELECT inserted.name FROM inserted) AND type IN (SELECT inserted.type FROM inserted))
			)))
		BEGIN
			RAISERROR('Selector already exists', 16, 1);
			ROLLBACK TRANSACTION;
		END

		IF(@@TRANCOUNT = 1)
		BEGIN
			INSERT INTO [selection] SELECT * FROM inserted;
		END
	go

	INSERT INTO [selection] VALUES
	(default, 'Knight', 'AVATAR_CLASS', null, default),
	(default, 'Warrior', 'AVATAR_CLASS', null, default),
	(default, 'Paladin', 'AVATAR_CLASS', null, default),
	(default, 'Rogue', 'AVATAR_CLASS', null, default),
	(default, 'Hunter', 'AVATAR_CLASS', null, default),
	(default, 'Druid', 'AVATAR_CLASS', null, default),
	(default, 'Shaman', 'AVATAR_CLASS', null, default),
	(default, 'Priest', 'AVATAR_CLASS', null, default),
	(default, 'Mage', 'AVATAR_CLASS', null, default),
	(default, 'Warlock', 'AVATAR_CLASS', null, default),
	
	(default, 'Human', 'AVATAR_RACE', null, default),
	(default, 'Elf', 'AVATAR_RACE', null, default),
	(default, 'Dark elf', 'AVATAR_RACE', null, default),
	(default, 'Dwarf', 'AVATAR_RACE', null, default),
	(default, 'Giant', 'AVATAR_RACE', null, default),
	(default, 'Fairy', 'AVATAR_RACE', null, default),

	(default, 'Normal', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Experienced', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Hard', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Advanced', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Bloodlust', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Extremal', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Death expects fools', 'MAP_DANGEROUS_LEVEL', null, default),
	(default, 'Run for glory', 'MAP_DANGEROUS_LEVEL', null, default);

--END
go