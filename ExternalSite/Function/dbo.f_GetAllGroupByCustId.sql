USE [bodb_ACC]
GO

ALTER FUNCTION [dbo].[f_GetAllGroupExtraPTByCustId]
(
	@CustID INT
)

/*
	Creator: Percy
	Date: 20160720
	DBAGE.bodb_Age
	Remark: get all group by superId

	Revisions:
		- Return table @CustExtraPTGroup TABLE (GroupId INT, GroupName VARCHAR(50), FromDate DATETIME, ToDate DATETIME, [Primary] TINYINT)
			+ Primary: 0: no, 1: is primary, 2: to be primary
*/

RETURNS @CustExtraPTGroup TABLE (GroupId INT, GroupName VARCHAR(50), EffectiveDate DATETIME, [Primary] TINYINT, OrderId TINYINT)
AS
BEGIN
	INSERT INTO @CustExtraPTGroup (GroupId, GroupName, EffectiveDate, [Primary], OrderId)
	SELECT d.GroupId, d.GroupName, s.EffectiveDate, CASE WHEN s.EffectiveDate IS NULL THEN 0 ELSE CASE WHEN s.EffectiveDate <= CONVERT(DATE, GETDATE()) THEN 1 ELSE 2 END END, 10
	FROM
		dbo.Acc_DWLList_ExtraPT d WITH(NOLOCK)
		LEFT JOIN
		(
			SELECT GroupName, MIN(FromDate) AS EffectiveDate
			FROM bodb_Acc.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperID = @CustID AND (CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate OR FromDate > CONVERT(DATE, GETDATE()))
			GROUP BY GroupName
		) s ON d.GroupName = s.GroupName
	WHERE d.GroupName <> 'BC'
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM @CustExtraPTGroup WHERE [Primary] = 1)
	BEGIN
		DECLARE @EffectiveDate DATETIME
		SELECT  @EffectiveDate = MAX(ToDate) FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID

		INSERT INTO @CustExtraPTGroup (GroupId, GroupName, EffectiveDate, [Primary], OrderId)
		SELECT 0, 'No Extra PT', DATEADD(DAY, 1, @EffectiveDate), 1, 1
	END
	ELSE
	BEGIN
		INSERT INTO @CustExtraPTGroup (GroupId, GroupName, EffectiveDate, [Primary], OrderId)
		SELECT 0, 'No Extra PT', NULL, 0, 1
	END

	RETURN
END