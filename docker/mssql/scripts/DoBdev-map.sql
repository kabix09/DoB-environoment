USE DanceOfBlades;
go

DROP TABLE IF EXISTS map;
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'map')
BEGIN
	
	/* prepare group & datafiles */
	EXEC create_table_datafile 'map', 'FG_MAP', 1;

	CREATE TABLE map (
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_map_uuid DEFAULT NEWID(),
		name VARCHAR(50) NOT NULL,
		description VARCHAR(255),
		region UNIQUEIDENTIFIER NULL, -- parent region - if it's subplace on anyone map
		
		area_type VARCHAR(55) NOT NULL,
		terrain_type VARCHAR(55) NOT NULL,
		is_climate_influenced BIT NOT NULL,
		climate VARCHAR(55) NOT NULL CONSTRAINT DF_map_climat_type DEFAULT 'normal',
		dangerous_level TINYINT NOT NULL CONSTRAINT DF_map_dangerous_level DEFAULT 1,

		-- restrictions
		no_battle_zone BIT NOT NULL,		-- dla bitw jak pojedynki PVP
		no_violence_zone BIT NOT NULL,	-- dla zab�jst i napa�ci np w miastach
		no_escape_zone BIT NOT NULL,		-- dla ucieczki z niebezpiecznych stref
		no_magic_zone BIT NOT NULL,		-- dla u�ywania magii
		
		image VARCHAR(80) NOT NULL,

		CONSTRAINT PK_map_uuid PRIMARY KEY (id),
		CONSTRAINT FK_map_region_uuid FOREIGN KEY (region) REFERENCES map(id),
/*		
		CONSTRAINT CK_map_terrain_type CHECK (area_type IN ('country', 'town', 'district', 'cottage', 'settlement', 'castle', 'island', 'jungle', 'forest', 'marshland', 'waterfall', 'river', 'lake', 'desert', 'hills', 'cave', 'vulcano', 'plains', 'hell', 'haven')),	-- Settlement - osada' plains - r�wniny
		CONSTRAINT CK_map_area_type CHECK (terrain_type IN ('inhabited', 'environment', 'dungeon')),
		CONSTRAINT CK_map_climate CHECK (climat IN ('normal', 'snowy', 'sunny', 'windy', 'rainy', 'stormy', 'thunderous', 'foggy', 'poisonous')),
*/
		CONSTRAINT CK_map_dangerous_level CHECK (dangerous_level >= 1 AND dangerous_level <= 10)
	);
	--https://designingmaps.gaijin.com/2018/06/fantasy-map-types/
	--https://www.gaijin.com/wp-content/uploads/2018/06/ex-isometric-akhr.jpg

	CREATE UNIQUE CLUSTERED INDEX PK_map_uuid ON [map](id) WITH (DROP_EXISTING=ON) ON FG_MAP;  

	CREATE NONCLUSTERED INDEX IX_map_name ON map(name);
	CREATE NONCLUSTERED INDEX IX_map_region_uuid ON map(region);	-- columns for join operation - FK
	
END
go

/* prepare used selection options */
INSERT INTO [selection] VALUES
(default, 'Inhabited', 'MAP_AREA', null, GETDATE()),
(default, 'Environment', 'MAP_AREA', null, GETDATE()),
(default, 'Dungeon', 'MAP_AREA', null, GETDATE());

INSERT INTO [selection] VALUES
(default, 'Country', 'MAP_TERRAIN', null, GETDATE()),
(default, 'Town', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'District', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'Cottage', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'Settlement', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'Castle', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'Island', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Inhabited' ), GETDATE()),
(default, 'Jungle', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Forest', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Marshland', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Waterfall', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'River', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Lake', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Desert', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Hills', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Cave', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Vulcano', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Plains', 'MAP_TERRAIN', (SELECT id FROM [selection] WHERE name = 'Environment' ), GETDATE()),
(default, 'Hell', 'MAP_TERRAIN', null, GETDATE()),
(default, 'Haven', 'MAP_TERRAIN', null, GETDATE());

INSERT INTO [selection] VALUES
(default, 'Normal', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Snowy', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Sunny', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Windy', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Rainy', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Stormy', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Thunderous', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Foggy', 'MAP_CLIMATE', null, GETDATE()),
(default, 'Poisonous', 'MAP_CLIMATE', null, GETDATE());
go

CREATE OR ALTER TRIGGER map_validator
ON map
INSTEAD OF INSERT
AS
	IF(NOT EXISTS (SELECT terrain_type FROM inserted WHERE terrain_type IN (SELECT name FROM selection WHERE type = 'MAP_TERRAIN')))
	BEGIN
		RAISERROR('Invalid terrain - this terrain don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(NOT EXISTS (SELECT area_type FROM inserted WHERE area_type IN (SELECT name FROM selection WHERE type = 'MAP_AREA')))
	BEGIN
		RAISERROR('Invalid area - this area don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END


	IF(NOT EXISTS (SELECT climate FROM inserted WHERE climate IN (SELECT name FROM selection WHERE type = 'MAP_CLIMATE')))
	BEGIN
		RAISERROR('Invalid climate - this climate don`t exist', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO map SELECT * FROM inserted;
	END
GO


/* many to many - bots occured on many different maps */


/* find foreign keys and related tables :) */
/*
SELECT [fk].name, [table].name AS [table], [referenced_table].name AS [referenced table]
FROM sys.foreign_key_columns as [fk_column]
JOIN sys.foreign_keys as [fk] ON [fk].object_id = [fk_column].constraint_object_id
JOIN sys.tables as [table] ON [fk_column].parent_object_id = [table].object_id
JOIN sys.tables AS [referenced_table] ON [fk_column].referenced_object_id = [referenced_table].object_id
*/
-- WHERE [referenced_table].name = 'map'


/*
one monster can be in many zones with different respown time
bot respown/occured place
uuid,
monster,
zone/ map,
respown type
*/