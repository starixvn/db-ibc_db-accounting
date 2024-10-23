/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" viewers="" isFunction="0"></info>*/
CREATE VIEW [dbo].[MsgError]
AS
/*
	Created: Helens
	Date: 2024-07-04
	Task: Scale out dbcust - error message
	DB: DBGLOB-GLOBCUSTDB
	
	Revisions:
		- 20240704@Helen:Scale out dbcust - error message - [Redmine:206823]
		
	Parameter's Explanation:
		
*/	
SELECT [MsgID], [MsgGroupID], [MsgNameEN], [MsgNameCT], [MsgNameCS], [MsgNameJP], [MsgNameTH], [MsgNameKO], [MsgNameES], [MsgNameVI], [IsActive], [MsgNameCN], [MsgNameIN]
FROM CUSTDB.dbo.MsgError WITH (NOLOCK)
