/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="" viewers="" isFunction="0"></info>*/

/*
	 Created by: 20240628@Louisa
	 Task: mapping login with user on GLOBCUSTDB [Redmine:#206823]
	 DB: DBGLOB-GLOBCUSTDB

	 Revision:
		- 20240628@Louisa: mapping login with user on GLOBCUSTDB [Redmine:#206823]
*/


USE GLOBCUSTDB
GO

IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='wsv_nap' )
BEGIN
	CREATE USER [wsv_nap] FOR LOGIN [wsv_nap]
END
GO

ALTER USER [wsv_nap] WITH DEFAULT_SCHEMA=[dbo]
GO

--------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='wsv_xnap' )
BEGIN 
	CREATE USER [wsv_xnap] FOR LOGIN [wsv_xnap]
END
GO

ALTER USER [wsv_xnap] WITH DEFAULT_SCHEMA=[dbo]
GO

--------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='wsv_alp' )
BEGIN 
	CREATE USER [wsv_alp] FOR LOGIN [wsv_alp]
END
GO

ALTER USER [wsv_alp] WITH DEFAULT_SCHEMA=[dbo]
GO

--------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='wsv_alpv' )
BEGIN 
	CREATE USER [wsv_alpv] FOR LOGIN [wsv_alpv]
END
GO

ALTER USER [wsv_alpv] WITH DEFAULT_SCHEMA=[dbo]
GO

---------------------------
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='asv_cust' )
BEGIN 
	CREATE USER [asv_cust] FOR LOGIN [asv_cust]
END
GO

ALTER USER [asv_cust] WITH DEFAULT_SCHEMA=[dbo]
GO

---------------------------
---use for Acc_CustomerSelExistingUsernames
IF NOT EXISTS (SELECT TOP 1 1 FROM sys.sysusers WHERE name='vnteam' )
BEGIN 
	CREATE USER [vnteam] FOR LOGIN [vnteam]
END
GO

ALTER USER [vnteam] WITH DEFAULT_SCHEMA=[dbo]
GO

