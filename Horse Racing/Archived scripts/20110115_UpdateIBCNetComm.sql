 ALTER PROCEDURE [dbo].[20110115_UpdateIBCNetComm]
	@winlostdate	datetime,	
AS
/*
	Created by: Amy
	Date: 2011-01-15
	Task: rectify the IBC Net Comm
	DB: DB06.BODB02	
*/
BEGIN
	SET NOCOUNT ON
	-- select Balance Up Day and Move Bets Day
	DECLARE @BalanceUpDay smalldatetime, @MoveBetsDay smalldatetime
	SELECT 
		TOP 1 @BalanceUpDay = winlostdate
	FROM Bettrans WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0	and custid = 3
	
	SELECT 		
		@MoveBetsDay = max(winlostdate) 
		FROM Bettrans14 WITH(NOLOCK)
		
	
	--insert company's comm setting that is recieved from Phumelela into this temp table.
DECLARE @CommSetting TABLE
(	PartnerType		tinyint,
	MatchID			int,
	ToteCommWin		smallmoney,
	ToteCommPlace	smallmoney,
	ToteCommWP		smallmoney,
	ToteFee			smallmoney
)
-----------------Update data from Bettrans--------------
IF @winlostdate > @MoveBetsDay
BEGIN	
	IF EXISTS(SELECT 1 FROM bettrans WITH (NOLOCK) WHERE winlostdate = @winlostdate AND bettype in (31,32,33))
	BEGIN
		IF EXISTS(SELECT 1 FROM bodb_Report.dbo.rptHRWinlost_amy WITH (NOLOCK) WHERE winlostdate = @winlostdate)			
		
			INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
			SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
			o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
			FROM	outright o WITH (NOLOCK)
					INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
					INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
			WHERE	o.eventdate = @winlostdate AND p.programDate = @winlostdate

			UPDATE b
			SET	incomeIBCNetComm = t1.incomeIBCNetComm
			FROM bodb_Report.dbo.rptHRWinlost_amy b
			INNER JOIN
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
						b.statusID NOT IN (101,102,103,121)
				GROUP BY b.winlostdate, cs.partnerType
			) t1 ON b.winlostdate = t1.winlostdate AND b.HRType = t1.PartnerType
			WHERE b.winlostdate = @winlostdate-- AND 1 = 0
		END
	END
END
-----------------Update data from Bettrans--------------
IF @winlostdate <= @MoveBetsDay AND @winlostdate > @BalanceUpDay
BEGIN
	IF EXISTS(SELECT 1 FROM bettrans14 WITH (NOLOCK) WHERE winlostdate = @winlostdate AND bettype in (31,32,33))
	BEGIN
		IF EXISTS(SELECT 1 FROM bodb_Report.dbo.rptHRWinlost_amy WITH (NOLOCK) WHERE winlostdate = @winlostdate)
					
			INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
			SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
					o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
			FROM	outright14 o WITH (NOLOCK)
					INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
					INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
			WHERE	o.eventdate = @winlostdate AND p.programDate = @winlostdate

			UPDATE b
			SET	incomeIBCNetComm = t1.incomeIBCNetComm
			FROM bodb_Report.dbo.rptHRWinlost_amy b
			INNER JOIN
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
						b.statusID NOT IN (101,102,103,121)
				GROUP BY b.winlostdate, cs.partnerType
			) t1 ON b.winlostdate = t1.winlostdate AND b.HRType = t1.PartnerType
			WHERE b.winlostdate = @winlostdate-- AND 1 = 0		
		END	
	END
END
---------------Update data from bettrans_bk ---------------------
IF @winlostdate<=@BalanceUpDay
BEGIN
	IF EXISTS(SELECT 1 FROM bodb_Archive.dbo.bettrans_bk WITH (NOLOCK) WHERE winlostdate = @winlostdate AND bettype in (31,32,33))
	BEGIN
		IF EXISTS(SELECT 1 FROM bodb_Report.dbo.rptHRWinlost_amy WITH (NOLOCK) WHERE winlostdate = @winlostdate)
		
			INSERT INTO @CommSetting (PartnerType, MatchID, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
			SELECT DISTINCT CASE isnumeric(o.programID) WHEN 0 THEN 1 ELSE (CASE m.partnerType WHEN 'RUK' THEN 2 WHEN 'ATR' THEN 3 WHEN 'ATRIRE' THEN 4  ELSE 5 END) END ,
					o.orid as matchid, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee
			FROM	bodb_Archive.dbo.outright_bk o WITH  (NOLOCK)
					INNER JOIN HorseMeeting m WITH (NOLOCK) ON o.leagueID = m.MeetingID 
					INNER JOIN LeagueDetail p WITH (NOLOCK) ON m.meetingID = p.leagueID 
			WHERE	o.eventdate = @winlostdate AND p.programDate = @winlostdate

			WHILE (@winlostdate)
			BEGIN
				UPDATE b TOP (1000) WITH (NOLOCK,ROWLOCK)
				SET	incomeIBCNetComm = t1.incomeIBCNetComm
				FROM bodb_Report.dbo.rptHRWinlost_amy b
				INNER JOIN
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
							b.statusID NOT IN (101,102,103,121)
					GROUP BY b.winlostdate, cs.partnerType
				) t1 ON b.winlostdate = t1.winlostdate AND b.HRType = t1.PartnerType
				WHERE b.winlostdate = @winlostdate-- AND 1 
				
				WAITFOR DELAY '00:00:10'   
			END
		END
	END
END

