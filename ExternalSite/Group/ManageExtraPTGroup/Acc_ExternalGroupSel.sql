/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExternalGroupSel]
AS

/*
	Created: 20140108@Lukas
	Task: get external group
	DB: DBEAS/bodb_EAS
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT GroupName 
	FROM dbo.eagroup WITH(NOLOCK)
	WHERE GroupID > 3
	ORDER BY GroupName
END
GO
