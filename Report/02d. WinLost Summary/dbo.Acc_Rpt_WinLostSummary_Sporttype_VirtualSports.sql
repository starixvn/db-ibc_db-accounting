ALTER PROCEDURE [dbo].[Acc_Rpt_WinLostSummary_Sporttype_VirtualSports] 
	@fromdate DATETIME,
	@todate		DATETIME,
	@sporttype	INT
AS
	/*
		Created: Johnson
		Date: 2013-06-25
		Task: Get summary winlost for virtual sports(exclude virtual HR) by match
		DB: DBRPT/bodb_Report
		
		Revisions:
			- 20130822@Johnson: change to use rptWinlost instead rptWinlost2
		Parameter's Explanation:
	*/
SET NOCOUNT ON 
	Declare @RPT TABLE (
		matchcode nvarchar(50) COLLATE SQL_Latin1_General_CP1_CS_AS,
		HomeId int, AwayId int,		
		bettype smallint, leagueid int,
		realWinLost money, realPosition money, realCommission money, realTurnover money, realLineTotal money,
		virtualLineTotal money, virtualTurnover money		
	)
	
	Declare @mineventdate datetime,
			@f_date datetime,
			@t_date datetime
	
	SELECT @mineventdate = min(eventdate) from bodb02.dbo.match with(nolock)
		
	
	IF @todate >= @mineventdate
	BEGIN
		IF @fromdate < @mineventdate
			SELECT @f_date = @mineventdate
		ELSE
			SELECT @f_date = @fromdate
			
		SELECT @t_date = @todate
		
		INSERT INTO @RPT(
			matchcode, homeid, awayid, bettype, leagueid, 
			realWinlost, realPosition, realCommission, realTurnover, realLineTotal,
			virtualLineTotal, virtualTurnover
		)
		SELECT matchcode
			,homeid
			,awayid
			,b.bettype
			,m.leagueid
			,ISNULL(SUM(realWinlost),0) 
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0) as virtualTurnover								
		FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE winlostdate BETWEEN @f_date AND @t_date
			AND b.sporttype = @sporttype			
		GROUP BY matchcode, homeid, awayid, bettype, leagueid
		
	END
	
	IF @fromdate <@mineventdate
	BEGIN
		IF @todate < @mineventdate
			SELECT @t_date = @todate
		ELSE
			SELECT @t_date = @mineventdate - 1
			
		SELECT @f_date = @fromdate
	
		INSERT INTO @RPT(
			matchcode, homeid, awayid, bettype, leagueid, 
			realWinlost, realPosition, realCommission, realTurnover, realLineTotal,
			virtualLineTotal, virtualTurnover
		)
		SELECT matchcode
			,homeid
			,awayid
			,b.bettype
			,m.leagueid
			,ISNULL(SUM(realWinlost),0) 
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			,ISNULL(SUM(realTurnover),0) as virtualTurnover							
		FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE winlostdate BETWEEN @f_date AND @t_date
			AND b.sporttype = @sporttype			
		GROUP BY matchcode, homeid, awayid, bettype, leagueid
	END
	
	SELECT * FROM @RPT
	ORDER BY bettype, leagueid, matchcode, homeid

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLostSummary_Sporttype_VirtualSports] TO [bodbAdminNet]