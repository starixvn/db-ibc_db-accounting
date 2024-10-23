/*<info serverAlias="DBTXN-CustDB,DBAGE-bodb02,DBCUST-CustDB,DBACC-bodb02,DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_xnap,wsv_alp,wsv_alpv" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Get_MsgNamebyMsgID]
(
	@MsgID		INT,
	@Language	NVARCHAR(5)='E' 
)
RETURNS NVARCHAR(4000) 
AS
/*
	Created by: Jamie
	Date: 2012-11-26
	Task: Get the content of message from msgID 
	DB: DBTXN-CustDB,DBAGE-bodb02,DBCUST-CustDB,DBACC-bodb02
	
	Revisions:
		- 20181218@Percy: Add MsgNameCN - New Chinese Simplified [RedmineID: #105338]
		- 20200729#Sophia: Add deploy at DBTXN-CustDB [Redmine: #136992]
		- 20230227@Bobby: AutoJob clear balance downlines [RedmineID: #182071]
		- 20230810@Luke: LAP - SEA Localization [Redmine: #187132]
		- 20231124@Luke: LAP - Support Indonesian & Thai language [Redmine: #196246]
		- 20240704@Helen: add meta data DBGLOB-GLOBCUSTDB - [Redmine:206823]
*/
BEGIN
	-- Declare the return variable here
	DECLARE	@MsgName NVARCHAR(4000)

	SELECT	@MsgName = CASE @Language	WHEN 'E'	THEN MsgNameEN 
										WHEN 'CS'	THEN ISNULL(MsgNameCS, MsgNameEN)
										WHEN 'CT'	THEN ISNULL(MsgNameCT, MsgNameEN)
										WHEN 'TH'	THEN ISNULL(MsgNameTH, MsgNameEN)
										WHEN 'J'	THEN ISNULL(MsgNameJP, MsgNameEN)
										WHEN 'KO'	THEN ISNULL(MsgNameKO, MsgNameEN)
										WHEN 'ES'	THEN ISNULL(MsgNameES, MsgNameEN)
										WHEN 'VI'	THEN ISNULL(MsgNameVI, MsgNameEN)
										WHEN 'CN'	THEN ISNULL(MsgNameCN, MsgNameEN)
										WHEN 'ID'	THEN ISNULL(MsgNameIN, MsgNameEN)
										ELSE MsgNameEN END 
										
	FROM	MsgError WITH (NOLOCK)
	WHERE	MsgID = @MsgID

	-- Return the result of the function
	RETURN	@MsgName
END
GO