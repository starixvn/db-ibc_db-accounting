/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupHeadline_Sel]
AS

/*
	Created: 20210302@Percy
	DB: DBCUST-CustDB
	Task: Select all group headlines

	Revisions:
		- 20210302@Percy: Initialize SP [RemineID: #146710]
*/

BEGIN
	SET NOCOUNT ON

	SELECT cgh.GroupId AS GroupHeadlineId, c.UserName AS HeadlineName
	FROM dbo.CustGroupHeadline cgh WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON cgh.CustId = c.CustId
END
GO