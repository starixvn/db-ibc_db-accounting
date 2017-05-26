/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[Acc_GroupExtraPT_Group_Sel]
AS

/*
	Created by: Percy
	Date: 2017-04-13
	DB: DBACC.bodb_ACC
	Task: Manage Extra PT Group - Select extra pt group [RedmineID: #74292]

	Revisions:

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT GroupId, GroupName
	FROM dbo.Acc_DWLList_ExtraPT WITH (NOLOCK)
	ORDER BY GroupId
END