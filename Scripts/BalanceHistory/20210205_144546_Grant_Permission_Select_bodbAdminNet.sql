/*<info serverAlias="DBBAH-BalanceRecord" ></info>*/
/*
	Created: Sol
	Date: 2021-02-05
	Task: new permission for bodbAdminNet account - [Redmine: #144546]
	DB: DBBAH-BalanceRecord
*/

USE BalanceRecord

GO

GRANT SELECT ON BalanceRecord_bk TO bodbAdminNet

GO