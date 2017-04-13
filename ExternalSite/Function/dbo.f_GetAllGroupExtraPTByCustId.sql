USE [bodb_ACC]
GO

ALTER FUNCTION [dbo].[f_GetAllGroupExtraPTByCustId]
(
	@CustID INT
)

/*
	Creator: Percy
	Date: 20160720
	DBACC.bodb_ACC
	Remark: get all group by superId

	Revisions:
*/

RETURNS @CustExtraPTGroup TABLE (GroupId INT, GroupName VARCHAR(50), EffectiveDate DATETIME, [Primary] BIT)
AS
BEGIN
	INSERT INTO @CustExtraPTGroup (GroupId, EffectiveDate, [Primary])
	SELECT d.GroupId, s.EffectiveDate, CASE WHEN ISNULL(s.EffectiveDate, '9999-12-31') > CONVERT(DATE, GETDATE()) THEN 0 ELSE 1 END
	FROM (
		SELECT GroupId FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName <> 'BC'
		UNION ALL SELECT 0
	) AS d
		LEFT JOIN
		(
			SELECT GroupId, MIN(FromDate) AS EffectiveDate
			FROM bodb_Acc.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperID = @CustID
				AND (
					CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate
					OR FromDate > CONVERT(DATE, GETDATE())
				)
				AND GroupName <> 'BC'
			GROUP BY GroupId
		) s ON d.GroupId = s.GroupId
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM @CustExtraPTGroup WHERE GroupId = 0)
	BEGIN
		INSERT INTO @CustExtraPTGroup (GroupId, EffectiveDate, [Primary])
		SELECT 0, NULL, 0
	END

	UPDATE c
	SET c.GroupName = a.GroupName
	FROM @CustExtraPTGroup c
		INNER JOIN dbo.Acc_DWLList_ExtraPT a WITH(NOLOCK) ON c.GroupId = a.GroupId

	UPDATE @CustExtraPTGroup
	SET GroupName = ''
	WHERE GroupId = 0

	RETURN
END