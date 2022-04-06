#!/bin/bash

# Run init-script with long timeout - and make it run in the background
/opt/mssql-tools/bin/sqlcmd -S localhost -l 30 -U SA -P "saPassword12" -i DoBdev-init.sql -i DoBdev-selection.sql -i DoBdev-user.sql -i DoBdev-friendship.sql -i DoBdev-menu.sql -i DoBdev-log.sql -i DoBdev-boss.sql -i DoBdev-map.sql -i DoBdev-rankings.sql -i DoBdev-item.sql &
#/opt/mssql-tools/bin/sqlcmd -S localhost -l 60 -U SA -P "saPassword12" -i DoBdev-selection.sql &
#/opt/mssql-tools/bin/sqlcmd -S localhost -l 90 -U SA -P "saPassword12" -i DoBdev-user.sql &
#/opt/mssql-tools/bin/sqlcmd -S localhost -l 120 -U SA -P "saPassword12" -i DoBdev-menu.sql &
#/opt/mssql-tools/bin/sqlcmd -S localhost -l 150 -U SA -P "saPassword12" -i DoBdev-rankings.sql &
# Start SQL server
/opt/mssql/bin/sqlservr