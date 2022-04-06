/*
	###--- CREATE DATABASE ---###
*/
USE DanceOfBlades;
go
/*
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'webpage')
BEGIN
	EXEC('CREATE SCHEMA webpage');
END
go
*/
--ALTER AUTHORIZATION ON schema::webpage TO webPageUser;	-- zmiana w�a�ciciela schematu
--ALTER USER webPageUser WITH DEFAULT_SCHEMA = game;	-- zmiana domy�lnego schematu dla urzytkownika

/* ###--- CREATE TABLES ---### */

/* --- menu --- */
--DROP TABLE IF EXISTS menu;

IF NOT EXISTS (
	SELECT * 
	FROM sys.tables t 
		JOIN sys.schemas s 
		ON (t.schema_id = s.schema_id)
	WHERE s.name = 'dbo' AND t.name = 'menu'	--webpage
)
BEGIN
	CREATE TABLE menu(
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_menu_uuid DEFAULT NEWID(),
		parent_id UNIQUEIDENTIFIER NULL,
		category VARCHAR(30) NOT NULL,
		hierarchy TINYINT NOT NULL,	-- tree level
		sequency TINYINT NOT NULL,
		CONSTRAINT PK_menu_uuid PRIMARY KEY (id),
		CONSTRAINT FK_menu_uuid FOREIGN KEY (parent_id) REFERENCES menu(id)
	);
	CREATE NONCLUSTERED INDEX FK_menu_parent_uuid ON menu(parent_id); -- WHERE parent_id IS NOT NULL?!!	-- mssql don't create (???) index on foreign key so it's needed to create it manually
	
	INSERT INTO menu VALUES
	('8ddcd518-adbd-484e-8b86-e4101003ab73', null, 'Home', 1, 1),
	('e0a80c98-6f85-4e25-a794-490aab37e7c1', null, 'World', 1, 2),
	('1ff5626e-da17-47bc-9e09-b0148b4ea769', 'e0a80c98-6f85-4e25-a794-490aab37e7c1', 'Maps', 2, 1),
	('bb473344-e834-402a-aa33-132d61d0bb69', 'e0a80c98-6f85-4e25-a794-490aab37e7c1', 'Characters', 2, 2),
	('b267e292-84f4-4ee4-8b0a-e1bfc643cc47', 'bb473344-e834-402a-aa33-132d61d0bb69', 'NPC', 3, 1),
	('f8e2f255-615e-46b7-bfb9-3f38a398db71', 'bb473344-e834-402a-aa33-132d61d0bb69', 'Heroes', 3, 2),
	('60a50459-1704-4bf0-8002-79bf61c0696e', 'bb473344-e834-402a-aa33-132d61d0bb69', 'Comrades', 3, 3),
	('415dab92-5a8a-4fcb-923f-79629aa16039', null, 'Items', 1, 3),
	('774bd1d0-efc9-4f9a-8735-9fa548d25468', '415dab92-5a8a-4fcb-923f-79629aa16039', 'Weapons', 2, 1),
	('bd581bb6-5d2f-4dce-ba9f-af5e4c6aa30e', '415dab92-5a8a-4fcb-923f-79629aa16039', 'Outfits', 2, 2),
	('6a5b9e08-6d1d-435b-9a3a-8dd8431f0552', '415dab92-5a8a-4fcb-923f-79629aa16039', 'Grimuars', 2, 3),
	('1197bd71-7e0e-4eb2-a2c0-1cff6a13cffa', '415dab92-5a8a-4fcb-923f-79629aa16039', 'Potions', 2, 4),
	('a36e64cd-c284-419a-99af-ff48302f4345', '415dab92-5a8a-4fcb-923f-79629aa16039', 'Others', 2, 5),
	('5459170f-1581-45ca-b702-f1ee4f49fee3', null, 'Magic', 1, 4),
	('e3a13231-572e-44a6-8ce2-78d3203f6485', '5459170f-1581-45ca-b702-f1ee4f49fee3', 'Art Of War', 2, 1),
	('399e0159-68dd-44f0-a3a9-b950fdfe9359', '5459170f-1581-45ca-b702-f1ee4f49fee3', 'Spells', 2, 2),
	('6f58f789-e698-4a02-85f1-50135bd1c383', '5459170f-1581-45ca-b702-f1ee4f49fee3', 'Skills', 2, 3),
	('54d78a1a-5ab7-48ec-bc6a-6e9ac33b2035', null, 'Tasks', 1, 5),
	('96df2199-b6d7-4d4d-8016-0610c1647ab7', '54d78a1a-5ab7-48ec-bc6a-6e9ac33b2035', 'Tournaments', 2, 1),
	('0a01c404-0d62-492c-b2aa-428fc7447d90', '54d78a1a-5ab7-48ec-bc6a-6e9ac33b2035', 'Raids', 2, 2),
	('2b12e2d0-ca9d-4716-97e8-ec23e3380599', '54d78a1a-5ab7-48ec-bc6a-6e9ac33b2035', 'Quests', 2, 3),
	('f57de275-cf51-4f1c-8608-25c926686f24', '54d78a1a-5ab7-48ec-bc6a-6e9ac33b2035', 'Orders', 2, 4),
	('6ee7b59f-3a46-4df3-8c0d-8b49c6615261', null, 'Library', 1, 6),
	('b0ec8218-5453-4af9-a2ac-15a2d308e933', '6ee7b59f-3a46-4df3-8c0d-8b49c6615261', 'Stone Of Freedom ', 2, 1),
	('c0785812-9850-45a3-80f5-bcea52d1a652', '6ee7b59f-3a46-4df3-8c0d-8b49c6615261', 'Book Of Masters', 2, 2),
	('0fb1688a-975c-423e-ac62-e0114fac4ca1', '6ee7b59f-3a46-4df3-8c0d-8b49c6615261', 'Pioneers', 2, 3),
	('444e6638-00c7-46c6-852a-57e9afa60be3', '6ee7b59f-3a46-4df3-8c0d-8b49c6615261', 'Adventure Hunters', 2, 4);

END;
go

--DROP TABLE webpage.menu;
