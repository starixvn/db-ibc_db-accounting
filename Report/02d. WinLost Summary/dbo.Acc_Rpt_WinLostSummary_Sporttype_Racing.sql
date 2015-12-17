USE [bodb_report]
GO

/****** Object:  StoredProcedure [dbo].[Acc_Rpt_WinLostSummary_Sporttype_CockFighting]    Script Date: 12/17/2015 10:52:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_WinLostSummary_Sporttype_CockFighting]
	@fromdate	DATETIME,
	@todate		DATETIME
AS
	/*
		Created: Johnson
		Date: 2013-06-24
		Task: Get summary winlost by match for racing
		DB: DBRPT/bodb_Report
		
		Revisions:
			- 20130716@Johnson: get min eventdate by oddsstatus = 'completed'			
			- 20130822@Johnson: change to use rptWinlost instead rptWinlost2
			- 20130917@Johnson: get @movebetday base on match14
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	Declare @RPT TABLE (
		ArenaID INT, FightNo INT,
		realWinLost money, realPosition money, realCommission money, realTurnover money, realLineTotal money,
		virtualTurnover money, virtualLineTotal money		
	)
	
	Declare @movebetsday datetime,
			@f_date datetime,
			@t_date datetime
	
	SELECT @movebetsday = max(eventdate) from bodb02.dbo.match14 with(nolock)
		
	
	IF @todate > @movebetsday
	BEGIN
		IF @fromdate <= @movebetsday
				SELECT @f_date = @movebetsday + 1
			ELSE
				SELECT @f_date = @fromdate
				
			SELECT @t_date = @todate
			
			INSERT INTO @RPT(
				ArenaID, FightNo, realWinlost, realPosition, realCommission, realTurnover, realLineTotal,
				virtualTurnover, virtualLineTotal
			)
			SELECT e.ArenaID
				--,b.bettype
				,e.FightNo
				,ISNULL(SUM(realWinlost),0)
				,ISNULL(SUM(realPosition),0)
				,ISNULL(SUM(realCommission),0)
				,ISNULL(SUM(realTurnover),0)
				,ISNULL(SUM(realLineTotal),0)
				,ISNULL(SUM(realTurnover),0) as virtualTurnover
				,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
			FROM rptWinlost b WITH(NOLOCK)
				INNER JOIN bodb02.dbo.EventInfo3rd e WITH(NOLOCK) ON b.matchid = e.FightNo
			WHERE b.winlostdate between @f_date and @t_date
				AND b.sporttype = @sporttype
			GROUP BY e.ArenaID, e.FightNo --, b.bettype
	END
	
	IF @fromdate <=@movebetsday
	BEGIN
		IF @todate <= @movebetsday
			SELECT @t_date = @todate
		ELSE
			SELECT @t_date = @movebetsday
			
		SELECT @f_date = @fromdate
				
		INSERT INTO @RPT(
			ArenaID, FightNo, realWinlost, realPosition, realCommission, realTurnover, realLineTotal,
			virtualTurnover, virtualLineTotal
		)
		SELECT e.ArenaID
			--,b.bettype
			,e.FightNo
			,ISNULL(SUM(realWinlost),0)
			,ISNULL(SUM(realPosition),0)
			,ISNULL(SUM(realCommission),0)
			,ISNULL(SUM(realTurnover),0)
			,ISNULL(SUM(realLineTotal),0)
			,ISNULL(SUM(realTurnover),0) as virtualTurnover
			,ISNULL(SUM(realLineTotal),0) as virtualLineTotal
		FROM rptWinlost b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.EventInfo3rd14 e WITH(NOLOCK) ON b.matchid = e.FightNo
		WHERE b.winlostdate between @f_date and @t_date
			AND b.sporttype = @sporttype
		GROUP BY e.ArenaID ,e.FightNo --,b.bettype
	END
	
	SELECT * FROM @RPT
	ORDER BY ArenaID, FightNo
	



GO

GRANT EXECUTE ON [dbo].[Acc_Rpt_WinLostSummary_Sporttype_CockFighting] TO [bodbAdminNet] AS [dbo]