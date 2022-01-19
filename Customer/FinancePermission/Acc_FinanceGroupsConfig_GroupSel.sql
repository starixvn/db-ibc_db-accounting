/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_FinanceGroupsConfig_GroupSel]
AS
/*
	Created: 20220114@Malcolm
	Task :  NAP - Admin - Finance Groups Config 
	DB: DBCUST/CUSTDB

	Revisions:
		- 20220114@Malcolm: Initialize SP [Redmine: #164833]

	Param's Explanation:

		               
*/

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT GroupId
	FROM Acc_FinancePermission WITH(NOLOCK)
	WHERE GroupId NOT IN (0, 1)
	ORDER BY GroupId DESC
END
GO
