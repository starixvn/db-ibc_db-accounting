 ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostSummary_Match]
	@fromdate	DATETIME,
	@todate		DATETIME,
	@sporttype	INT,
	@bettype	INT
 AS
	/*
		Created: Johnson
		Date: 2013-06-24
		Task: Get winlost summary details by match 
		DB: DBRPT/bodb_Report
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	
	Declare @RPT TABLE (
		matchcode nvarchar(50) COLLATE SQL_Latin1_General_CP1_CS_AS,
		HomeId int, AwayId int,		
		liveindicator bit, bType smallint, leagueid int,
		WinLost money, Position money, Commission money, Admin2 money,
		isNeutral bit
	)

	SELECT
	FROM 
	
	

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Match] TO [bodbAdminNet]