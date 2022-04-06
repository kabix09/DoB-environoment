USE DanceOfBlades;

DROP TABLE IF EXISTS [Friendship];
go

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'friendship')
BEGIN
	CREATE TABLE [friendship] (
		requester_id UNIQUEIDENTIFIER NOT NULL,
		addressee_id UNIQUEIDENTIFIER NOT NULL,
		sent_date DATETIME2 NOT NULL,
		accepted_date DATETIME2 NULL,
		rejected_date DATETIME2 NULL,
		deleted_date DATETIME2 NULL,
		CONSTRAINT PK_friendship PRIMARY KEY (requester_id, addressee_id, sent_date),
		CONSTRAINT FK_friendship_requester FOREIGN KEY (requester_id) REFERENCES Avatar(id),
		CONSTRAINT FK_friendship_addressee FOREIGN KEY (addressee_id) REFERENCES Avatar(id)
	);

	CREATE NONCLUSTERED INDEX FK_friendship_requester ON [Friendship](requester_id);
	CREATE NONCLUSTERED INDEX FK_friendship_addressee ON [Friendship](addressee_id);

END
GO

CREATE OR ALTER TRIGGER friendship_validator
ON [friendship]
INSTEAD OF INSERT
AS
	IF(EXISTS (
		SELECT * FROM [Friendship] WHERE (
			(requester_id = (SELECT inserted.requester_id FROM inserted) AND addressee_id = (SELECT inserted.addressee_id FROM inserted))
		OR 
			(addressee_id = (SELECT inserted.requester_id FROM inserted) AND requester_id = (SELECT inserted.addressee_id FROM inserted))
		) AND DATEDIFF(SECOND, sent_date, (SELECT inserted.sent_date FROM inserted)) = 0
		))
	BEGIN
		RAISERROR('Frednship already exists', 16, 1);
		ROLLBACK TRANSACTION;
	END

	IF(@@TRANCOUNT = 1)
	BEGIN
		INSERT INTO [Friendship] SELECT * FROM inserted;
	END
GO


/*
	- sent date - sending invitation date
	- accept date - date of accepted invitation - null if not accepted yet
	- rejected date - data of rejected invitation- null if accepted or not rejected yet
	- deleterd date - date of deleted friend, available only after accepting invitation
*/

/* -!-!- TEST -!-!- */
/*SELECT * FROM avatar;

SELECT * FROM [Friendship];
DELETE FROM [Friendship] WHERE requester_id ='A15C353D-45BD-46B7-B46C-8C390E5E1F12' AND deleted_date IS NOT NULL;
INSERT INTO [Friendship] VALUES ('5B95D7DB-C69E-4B58-901E-F132D7179D08', 'A15C353D-45BD-46B7-B46C-8C390E5E1F12', '2021-09-24 17:49:23.7533333', NULL, NULL, NULL),

('5B95D7DB-C69E-4B58-901E-F132D7179D08', 'A15C353D-45BD-46B7-B46C-8C390E5E1F12', DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, -1, GETDATE()), NULL, DATEADD(HOUR, -5, GETDATE())),
('5B95D7DB-C69E-4B58-901E-F132D7179D08', 'A15C353D-45BD-46B7-B46C-8C390E5E1F12', GETDATE(), NULL, NULL, NULL),
('5B95D7DB-C69E-4B58-901E-F132D7179D08', '823C9FA5-21F2-48C1-883E-5A33C2788C40', DATEADD(DAY, -3, GETDATE()), GETDATE(), NULL, NULL),
('097E9206-D3DA-46AE-B09F-358844015ECA', '5B95D7DB-C69E-4B58-901E-F132D7179D08', DATEADD(HOUR, -5, GETDATE()), null, NULL, NULL);
*/
/*
('60583428-B3A0-42C5-90C9-59BDD2893490', 'A3A7F88A-5077-4519-B42E-E40BC66DE087', GETDATE(), NULL, NULL, NULL);

INSERT INTO [Friendship] VALUES
('A3A7F88A-5077-4519-B42E-E40BC66DE087', '60583428-B3A0-42C5-90C9-59BDD2893490', GETDATE(), NULL, NULL, NULL);
*/