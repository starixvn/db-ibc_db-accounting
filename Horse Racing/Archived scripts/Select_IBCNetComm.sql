set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

  ALTER PROCEDURE [dbo].[Select_IBCNetComm]
	@fromdate smalldatetime,	
	@todate smalldatetime
AS
/*
	Created by: Amy
	Date: 2011-01-15
	Task: rectify the IBC Net Comm
	DB: DB06.BODB02	
*/
	SET NOCOUNT ON
	-- select Balance Up Day and Move Bets Day
	DECLARE @BalanceUpDay smalldatetime
	SELECT 
		TOP 1 @BalanceUpDay = winlostdate
	FROM Bettrans WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0	and custid = 3	
		
	--insert company's comm setting that is recieved from Phumelela into this temp table.
DECLARE @CommSetting TABLE
(	PartnerType		tinyint,
	MatchID			int,
	ToteCommWin		smallmoney,
	ToteCommPlace	smallmoney,
	ToteCommWP		smallmoney,
	ToteFee			smallmoney
)
-----------------Select data from Bettrans--------------
IF @Todate >= @BalanceUpDay
BEGIN		
	INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
	SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
	o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
	FROM	outright o WITH (NOLOCK)
			INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
	WHERE	(o.eventdate between @fromdate and @Todate) AND (p.programDate between @fromdate and @Todate)

	INSERT INTO bodb_Report.dbo.rptHRWinlost_IBCComm (winlostdate , HRType, incomeIBCNetComm)		
	(
		SELECT	b.winlostdate, 
				cs.partnerType,
				--IBC Income 					
				SUM((CASE WHEN b.bettype = 33 THEN bm.TO3rd*cs.ToteCommWP  
						  WHEN b.bettype = 31 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommWin 
						  WHEN b.bettype = 32 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommPlace
						  ELSE 0 END)*b.actualrate )
				- SUM(b.scomm*b.actualrate) 
				- SUM(CASE WHEN cs.partnerType <> 1 THEN 0
						ELSE(CASE WHEN b.bettype = 33 THEN bm.TO3rd WHEN bettype IN (31,32) THEN b.actual_stake*(1 - b.tpositiontaking - isnull(b.oddsspread,0)) ELSE 0 END)*cs.ToteFee*b.actualrate END) incomeIBCNetComm
		FROM	bettrans b WITH (NOLOCK) 
				INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid 
				LEFT JOIN (
					SELECT refno,
					SUM(CASE WHEN bettype = 32 AND liveawayscore = 0 THEN 0 WHEN bettype = 31 OR (bettype = 32 AND liveawayscore <> 0) THEN stake*(1 -tpositiontaking - isnull(oddsspread,0)) ELSE 0 END) TO3rd						
					FROM	bettransm WITH (NOLOCK)
					GROUP BY refno
				)bm ON b.transid = bm.refno 
				
		WHERE	b.ruben = 1 AND 
				b.bettype IN (31,32,33) AND 
				--b.status NOT IN ('VOID','REJECT','DONE','REFUND')
				b.statusID NOT IN (101,102,103,121) AND
				(b.winlostdate BETWEEN @fromdate AND @Todate)
		GROUP BY b.winlostdate, cs.partnerType
	) 	
	
	-----------------Select data from Bettrans14--------------
	IF @BalanceUpDay <= @FromDate
	BEGIN	
		SELECT @BalanceUpDay=@FromDate
	
		INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
		SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
		o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
		FROM	outright14 o WITH (NOLOCK)
				INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
				INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
		WHERE	(o.eventdate between @BalanceUpDay and @Todate) AND (p.programDate between @BalanceUpDay and @todate)

		INSERT INTO bodb_Report.dbo.rptHRWinlost_IBCComm (winlostdate , HRType, incomeIBCNetComm)				
		(
			SELECT	b.winlostdate, 
					cs.partnerType,
					--IBC Income 					
					SUM((CASE WHEN b.bettype = 33 THEN bm.TO3rd*cs.ToteCommWP  
							  WHEN b.bettype = 31 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommWin 
							  WHEN b.bettype = 32 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommPlace
							  ELSE 0 END)*b.actualrate )
					- SUM(b.scomm*b.actualrate) 
					- SUM(CASE WHEN cs.partnerType <> 1 THEN 0
							ELSE(CASE WHEN b.bettype = 33 THEN bm.TO3rd WHEN bettype IN (31,32) THEN b.actual_stake*(1 - b.tpositiontaking - isnull(b.oddsspread,0)) ELSE 0 END)*cs.ToteFee*b.actualrate END) incomeIBCNetComm
			FROM	bettrans14 b WITH (NOLOCK) 
					INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid 
					LEFT JOIN (
						SELECT refno,
						SUM(CASE WHEN bettype = 32 AND liveawayscore = 0 THEN 0 WHEN bettype = 31 OR (bettype = 32 AND liveawayscore <> 0) THEN stake*(1 -tpositiontaking - isnull(oddsspread,0)) ELSE 0 END) TO3rd						
						FROM	bettransm14 WITH (NOLOCK)
						GROUP BY refno
					)bm ON b.transid = bm.refno 
					
			WHERE	b.ruben = 1 AND 
					b.bettype IN (31,32,33) AND 
					--b.status NOT IN ('VOID','REJECT','DONE','REFUND')
					b.statusID NOT IN (101,102,103,121) AND
					(b.winlostdate BETWEEN @BalanceUpDay AND @Todate)
			GROUP BY b.winlostdate, cs.partnerType
		) 				
	END
END
---------------Update data from bettrans_bk ---------------------
IF @Fromdate < @BalanceUpDay 
BEGIN	
	INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
	SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
	o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
	FROM	bodb_Archive.dbo.outright_bk o WITH (NOLOCK)
			INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
	WHERE	(o.eventdate between @fromdate and @Todate) AND (p.programDate between @Fromdate and @todate)

	INSERT INTO bodb_Report.dbo.rptHRWinlost_IBCComm (winlostdate , HRType, incomeIBCNetComm)		
	(
		SELECT	b.winlostdate, 
				cs.partnerType,
				--IBC Income 					
				SUM((CASE WHEN b.bettype = 33 THEN bm.TO3rd*cs.ToteCommWP  
						  WHEN b.bettype = 31 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommWin 
						  WHEN b.bettype = 32 THEN b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0))*cs.ToteCommPlace
						  ELSE 0 END)*b.actualrate )
				- SUM(b.scomm*b.actualrate) 
				- SUM(CASE WHEN cs.partnerType <> 1 THEN 0
						ELSE(CASE WHEN b.bettype = 33 THEN bm.TO3rd WHEN bettype IN (31,32) THEN b.actual_stake*(1 - b.tpositiontaking - isnull(b.oddsspread,0)) ELSE 0 END)*cs.ToteFee*b.actualrate END) incomeIBCNetComm
		FROM	bodb_Archive.dbo.bettrans_bk b WITH (NOLOCK) 
				INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid 
				LEFT JOIN (
					SELECT refno,
					SUM(CASE WHEN bettype = 32 AND liveawayscore = 0 THEN 0 WHEN bettype = 31 OR (bettype = 32 AND liveawayscore <> 0) THEN stake*(1 -tpositiontaking - isnull(oddsspread,0)) ELSE 0 END) TO3rd						
					FROM	bodb_Archive.dbo.bettransm WITH (NOLOCK)
					GROUP BY refno
				)bm ON b.transid = bm.refno 
				
		WHERE	b.ruben = 1 AND 
				b.bettype IN (31,32,33) AND 
				--b.status NOT IN ('VOID','REJECT','DONE','REFUND')
				b.statusID NOT IN (101,102,103,121) AND
				(b.winlostdate BETWEEN @Fromdate AND @Todate)
		GROUP BY b.winlostdate, cs.partnerType
	) 				
END


