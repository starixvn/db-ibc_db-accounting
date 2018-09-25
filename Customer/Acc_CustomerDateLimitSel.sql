/*<info serverAlias="DBAGE-bodb_AGE" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb_Age
GO

ALTER PROCEDURE [dbo].[Acc_CustomerDateLimitSel] @userName NVARCHAR(100) = ''
	,@PageSize INT = 0
	,@PageIndex INT = 0
	,@TotalRecords INT = 0 OUTPUT
AS
/*
	Created: 20180429@Razor
	DB: DBAGE/bodb_AGE
	Task: 

	Revisions:
		-20180429@Razor: init - [Readmine: #96025]
		
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RowStart INT
		,@RowEnd INT
	DECLARE @temp TABLE (
		CustId INT
		,UserName NVARCHAR(100)
		,LimitDays INT
		,MinDate DATETIME
		,RowNum INT
		)

	SELECT @PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT @userName = ISNULL(@userName, '')

	INSERT INTO @temp (
		CustId
		,UserName
		,LimitDays
		,MinDate
		,RowNum
		)
	SELECT c.custId
		,c.UserName
		,l.LimitDays
		,l.MinDate
		,ROW_NUMBER() OVER (
			ORDER BY c.UserName
			) AS RowNum
	FROM dbo.Age_CustDateLimit l WITH (NOLOCK)
		INNER JOIN [bodb02].[dbo].[custInfo] c WITH (NOLOCK) ON c.custId = l.custId
	WHERE c.UserName LIKE '%' + @userName + '%'

	SELECT UserName, CustId, MinDate, LimitDays
	FROM @temp
	WHERE RowNum BETWEEN @RowStart
			AND @RowEnd

	SELECT @TotalRecords = COUNT(CustId)
	FROM @temp
END
GO


