USE DanceOfBlades;
go

-- DROP TABLE log;
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'log')
BEGIN
	CREATE TABLE log(
		id UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_log_uuid DEFAULT NEWID(),
		user_ip VARCHAR(45) NOT NULL,	-- IPv4-mapped IPv6 (45 characters) : --https://stackoverflow.com/questions/1076714/max-length-for-client-ip-address
		user_browser_data VARCHAR(255) NOT NULL,
		user_town VARCHAR(80),
		device_system VARCHAR(55) NOT NULL,
		start_session_date DATETIME2 NOT NULL CONSTRAINT DF_log_start_session_date DEFAULT GETDATE(),	-- login time
		user_id UNIQUEIDENTIFIER NOT NULL,
		CONSTRAINT PK_log_uuid PRIMARY KEY (id),
		CONSTRAINT FK_log_user_uuid FOREIGN KEY (user_id) REFERENCES [user](id),
		CONSTRAINT CK_log_device_system CHECK (device_system IN ('desktop', 'mobile', 'other'))
	);

	CREATE NONCLUSTERED INDEX FK_log_user_uuid ON log(user_id);
	CREATE NONCLUSTERED INDEX IX_log_session_sart_date ON log(start_session_date);	-- column for searching value
END
go
 