/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExternalGroupSel]
AS

/*
	Created: 20140108@Lukas
	Task: get external group
	DB: DBPOL/NAP_UserControl
	
	Revisions:
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20190521@Paul: Migrate to DBPOL.NAP_UserControl [Redmine: 111865]
		- 20200807@Johnson: exclude sub groups [redmine:#136501]
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT GroupName 
	FROM dbo.eagroup WITH(NOLOCK)
	WHERE GroupID > 3
		AND ISNULL(ParentID,0) = 0
	ORDER BY GroupName
END
GO
