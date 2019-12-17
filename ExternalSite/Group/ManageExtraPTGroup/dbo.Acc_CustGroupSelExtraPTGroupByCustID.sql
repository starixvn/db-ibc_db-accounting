/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustGroupSelExtraPTGroupByCustID]
	@CustID INT
AS
/*
	Creator: Percy
	Date: 2016-07-25
	Task: Select ExtraPT Group by SuperID
	DB: DBACC/bodb02

	Revisions:
		- 20170413@Percy: Change way get to-be-primary group [RedmineID: #74292]
		- 20170926@Percy: Move this SP from DBAGE.bodb_Age to DBACC.bodb02 [RedmineID: #83600]
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20191216@Percy: Add NoOfMember field [RedmineID: #125418]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())

	DECLARE @GroupExtraPT TABLE (GroupId INT, GroupName VARCHAR(50), EffectiveDate DATETIME, [Primary] BIT)

	INSERT INTO @GroupExtraPT (GroupId, GroupName, EffectiveDate, [Primary])
	SELECT GroupId, GroupName, EffectiveDate, [Primary]
	FROM dbo.f_GetAllGroupExtraPTByCustId(@CustID)

	-- Get number of members belong to super
	DECLARE @NoOfMember INT
	SELECT  @NoOfMember = COUNT(1) FROM dbo.Customer WITH (NOLOCK) WHERE srecommend = @CustID AND roleid = 1

	SELECT
		c.GroupName,
		CASE WHEN e.[Primary] = 1 THEN e.EffectiveDate ELSE NULL END AS EffectiveDate,
		e.[Primary] AS IsPrimary
		,@NoOfMember AS NoOfMember
	FROM
		(
			SELECT GroupName FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID
			UNION SELECT 'No Extra PT'
		) c
		INNER JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
	ORDER BY CASE WHEN e.GroupId = 0 THEN 0 ELSE 1 END, e.GroupName
END
GO