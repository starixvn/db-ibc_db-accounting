/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_Group_Sel]
AS

/*
	Created: 20170413@Percy
	DB: DBACC.bodb_ACC -> DBCUST.CustDB
	Task: Manage Extra PT Group - Select extra pt group [RedmineID: #74292]

	Revisions:
		- 20170413@Percy: Add new SP [RemineID: #74292]
		- 20191216@Percy: Hide 3 groups: ACCTHAI2, ACCTHAI56, ACCTHAI99 [RemineID: #125418]
		- 20210301@Percy: Change BC to real Extra PT Group [RedmineID: #146710]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT GroupId, GroupName
	FROM dbo.Acc_DWLList_ExtraPT WITH (NOLOCK)
	WHERE IsDisabled = 0
	ORDER BY GroupName
END
GO