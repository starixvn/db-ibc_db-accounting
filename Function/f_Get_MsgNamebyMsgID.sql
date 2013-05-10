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
	DB: DBTRANS.bodb02, DBLOG.bodb_CustomerLog, DB053.bodb02
	
	Revisions: 
	
*/
BEGIN
	-- Declare the return variable here
	DECLARE	@MsgName	NVARCHAR(4000)

	SELECT	@MsgName = CASE @Language	WHEN 'E'	THEN MsgNameEN 
										WHEN 'CS'	THEN MsgNameCS
										WHEN 'CT'	THEN MsgNameCT
										WHEN 'TH'	THEN MsgNameTH
										WHEN 'J'	THEN MsgNameJP
										WHEN 'KO'	THEN MsgNameKO
										WHEN 'ES'	THEN MsgNameES
										WHEN 'VI'	THEN MsgNameVI
										ELSE MsgNameEN END 
										
	FROM	MsgError WITH (NOLOCK)
	WHERE	MsgID = @MsgID

	-- Return the result of the function
	RETURN	@MsgName

END

GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_MsgNamebyMsgID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_MsgNamebyMsgID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_MsgNamebyMsgID] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_MsgNamebyMsgID] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_MsgNamebyMsgID] TO [bodbDownlineNetView]