ALTER PROCEDURE [dbo].[Acc_Rpt_HouseNetIncome_SB_Credit]
	@FromDate DATE,
	@ToDate	DATE
AS  
/*  Created: Victor  
	Date: 2016-05-27  
    Task : House month-to-date Net Income report
    DB: DBWH/bodb_dwrs  
   
    Revisions:
	Param's Explanation:   
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @Result TABLE (
		[Date] VARCHAR(12),
		HouseWL MONEY,
		ExtraPT MONEY
	)

	INSERT INTO @Result ([Date], HouseWL, ExtraPT)
	SELECT '01', 243.452, 12.4351
	UNION SELECT '02', 2134.34, 62.12
	UNION SELECT '03', 4454.25, 65.44
	UNION SELECT '04', 346.213, 1.56
	UNION SELECT '05', 123.466, 124.23
	UNION SELECT '06', 178.1234, 23.56
	UNION SELECT 'FullRange', 47454.474, 784.54

	SELECT * 
	FROM (SELECT [Order], [Date], Figure, value FROM @Result
			CROSS APPLY
			(SELECT 1, 'House Income', HouseWL 
			UNION ALL
			SELECT 2, 'Extra PT', ExtraPT) c ([Order], Figure, value)) a
	PIVOT
	(
		MAX(value)
		FOR [Date] in ([FullRange], [01], [02], [03], [04], [05], [06])
	) piv
	ORDER BY [Order] 
	
END
GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_HouseNetIncome_SB_Credit] TO [bodbAdminNet]
GO
GRANT VIEW definition ON [dbo].[Acc_Rpt_HouseNetIncome_SB_Credit] TO vnteam