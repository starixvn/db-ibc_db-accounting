/*<info serverAlias="DBTXN-bodb02,DBAGE-bodb02,DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
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
	DB: DBTXN-bodb02,DBAGE-bodb02,DBCUST-CustDB
	
	Revisions:
		- 20181218@Percy: Add MsgNameCN - New Chinese Simplified [RedmineID: #105338]
	
*/
BEGIN
	-- Declare the return variable here
	DECLARE	@MsgName NVARCHAR(4000)

	SELECT	@MsgName = CASE @Language	WHEN 'E'	THEN MsgNameEN 
										WHEN 'CS'	THEN MsgNameCS
										WHEN 'CT'	THEN MsgNameCT
										WHEN 'TH'	THEN MsgNameTH
										WHEN 'J'	THEN MsgNameJP
										WHEN 'KO'	THEN MsgNameKO
										WHEN 'ES'	THEN MsgNameES
										WHEN 'VI'	THEN MsgNameVI
										WHEN 'CN'	THEN MsgNameCN
										ELSE MsgNameEN END 
										
	FROM	MsgError WITH (NOLOCK)
	WHERE	MsgID = @MsgID

	-- Return the result of the function
	RETURN	@MsgName
END
GO