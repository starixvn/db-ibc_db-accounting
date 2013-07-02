 ALTER PROCEDURE [dbo].[Acc_Rpt_WinLostSummary_Sporttype_Racing]
	@sporttype	INT,
	@fromdate	DATETIME,
	@todate		DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-06-24
		Task: Get summary winlost by match for racing
		DB: DBRPT/bodb_Report
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	Declare @RPT TABLE (
		race varchar(50), bettype smallint, meetingid int,
		realWinLost money, realPosition money, realCommission money, realTurnover money, realLineTotal money		
	)
	
	Declare @mineventdate datetime,
			@f_date datetime,
			@t_date datetime
	
	SELECT @mineventdate = min(eventdate) from bodb02.dbo.outright with(nolock)
		
	
	IF @todate >= @mineventdate
	BEGIN
		IF @fromdate < @mineventdate
				SELECT @f_date = @mineventdate
			ELSE
				SELECT @f_date = @fromdate
				
			SELECT @t_date = @todate
			
			INSERT INTO @RPT(
				race, bettype, meetingid, realWinlost, realPosition, realCommission, realTurnover, realLineTotal
			)
			SELECT m.groupmatch as race
				,b.bettype
				,m.leagueid
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0)
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realTurnover),0)
				,ISNULL(SUM(realLineTotal),0)
			FROM rptWinlost2 b WITH(NOLOCK)
				INNER JOIN bodb02.dbo.outright m WITH(NOLOCK) ON b.matchid = m.orid
			WHERE b.winlostdate between @f_date and @t_date
				AND b.sporttype = @sporttype
			GROUP BY m.groupmatch, b.bettype, m.leagueid
	END
	
	IF @fromdate <@mineventdate
	BEGIN
		IF @todate < @mineventdate
			SELECT @t_date = @todate
		ELSE
			SELECT @t_date = @mineventdate - 1
			
		SELECT @f_date = @fromdate
				
		INSERT INTO @RPT(
			race, bettype, meetingid, realWinlost, realPosition, realCommission, realTurnover, realLineTotal
		)
		SELECT m.groupmatch as race
			,b.bettype
			,m.leagueid
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realLineTotal),0)
		FROM rptWinlost2 b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.outright14 m WITH(NOLOCK) ON b.matchid = m.orid
		WHERE b.winlostdate between @f_date and @t_date
			AND b.sporttype = @sporttype
		GROUP BY m.groupmatch,b.bettype,m.leagueid
	END
	
	SELECT * FROM @RPT
	ORDER BY bettype,meetingid,CAST(race AS TINYINT)
	

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostSummary_Sporttype_Racing] TO [bodbAdminNet]
