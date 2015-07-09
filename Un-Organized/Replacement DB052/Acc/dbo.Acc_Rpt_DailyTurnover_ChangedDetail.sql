USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_DailyTurnover_ChangedDetail]    Script Date: 12/13/2012 03:45:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_Rpt_DailyTurnover_ChangedDetail]
	@fromdate datetime
AS
/*
Created: Minzy@20120405
Task : Get agency, ibc turnover, bet count changed detail

DB: DB06.bodb02
Original: 

Revisions:
	20120511@Minzy: Fix when get data from bettrans14, must get team name from match14
	Daniel@20120605: exclude 3rd party bettypes when checking void bet case
	20121213@Dan: Change linked server from DB052-->DBLOG

	
Param's Explanation:

*/
BEGIN
	
	SET NOCOUNT ON
	DECLARE @datelog DATETIME
	SET @datelog = dateadd(d,1,@fromdate) 
	-- Temp table to save changed stake,bet count detail
	CREATE TABLE #temp(	logdate DATETIME,
					actionid INT,
					DetailID BIGINT,-- matchid or transid(void ticket)
					UserID INT,
					Total_Virtual MONEY,
					Total_Actual MONEY,
					Super_Virtual MONEY,
					Super_Actual MONEY,
					Master_Virtual MONEY,
					Master_Actual MONEY,
					Agent_Virtual MONEY,
					Agent_Actual MONEY,
					IBC_Virtual MONEY,
					IBC_Actual MONEY
					--TicketCNT INT,
					--NormalCNT INT,
					--RejectCNT INT
			)


	-- Consider to include bettrans_BK into query or not.
	IF @fromdate <= (select max(distinct eventdate) from match14 (nolock))
	BEGIN
		INSERT INTO #temp(logdate,DetailID,actionid,UserID,Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual)--TicketCNT,NormalCNT,RejectCNT)
		SELECT l.logdate,l.matchid,l.actionid,l.UserID,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Total_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Total_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *spositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Super_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *spositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Super_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *mpositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Master_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *mpositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Master_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *apositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Agent_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *apositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Agent_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * (1-tpositiontaking) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) IBC_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * (1-tpositiontaking) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) IBC_Virtual
				--SUM(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else 1 end)  +0  TicketCNT,
				--SUM(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else 1 end)  NormalCNT,
				--0 RejectCNT
		FROM DBLOG.bodb_customerlog.dbo.userlog_settle l WITH (nolock)
			INNER JOIN bodb02.dbo.bettrans14 b WITH (nolock) ON (l.matchid = b.matchid AND b.currency <> 20)
			LEFT JOIN bodb02.dbo.zzzbettrans z WITH (nolock) ON  (b.transid=z.transid)
		WHERE		b.winlostdate = @fromdate 
			AND		l.logdate between @datelog AND getdate()
			AND		l.actionid IN(	100,-- calculate all new game
								101,-- calculate FT
								102,-- calculate HT
								103,-- Undo Settlement
								108,-- Calculate FGLG
								109,-- Refund All
								110,-- Refund HT
								111,-- Refund FT
								112,-- Refund FGLG
								123,-- Calculate All for Abandoned/Postponed match
								124,-- Calculate FT for Abandoned/Postponed match
								125	-- Calculate HT for Abandoned/Postponed match	
							)
			AND		((l.actionid IN(100,123) AND b.bettype <> 14 )-- cal all
							OR ((l.actionid IN(101,124) AND b.bettype NOT IN(7,8,15,12,21,30,125,14))-- cal FT
							OR (l.actionid IN(102,125) AND b.bettype IN(7,8,15,12,21,30,125) )-- cal HT
							OR (l.actionid =103 ) -- undo
							OR (l.actionid =108 AND b.bettype = 14 )-- cal FGLG
							OR (l.actionid  = 109 AND b.bettype <> 14 )-- refund all 
							OR (l.actionid  = 111 AND b.bettype NOT IN(7,8,15,12,21,30,125,14))-- refund  FT
							OR (l.actionid =110 AND b.bettype IN(7,8,15,12,21,30,125) )-- refund HT
							OR (l.actionid =112 AND b.bettype = 14)-- refund FGLG
						))
		GROUP BY l.logdate,l.matchid,l.actionid,l.UserID
		ORDER BY l.logdate,l.matchid,l.actionid,l.UserID

		-- Void ticket
		INSERT INTO #temp(logdate,actionid,DetailID,UserID,Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual)--TicketCNT,NormalCNT,RejectCNT)
		SELECT z.transdate,-1,z.transid,b.creator,
			abs(b.stake) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Total_Actual,
			abs(b.stake) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Total_Virtual,
			abs(b.stake) *spositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Super_Actual,
			abs(b.stake) *spositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Super_Virtual,
			abs(b.stake) *mpositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Master_Actual,
			abs(b.stake) *mpositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Master_Virtual,
			abs(b.stake) *apositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Agent_Actual,
			abs(b.stake) *apositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Agent_Virtual,
			abs(b.stake) * (1-tpositiontaking) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end IBC_Actual,
			abs(b.stake) * (1-tpositiontaking) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end IBC_Virtual
			--CASE z.status WHEN 'running' THEN 1 ELSE 0 END TicketCNT,
			--CASE z.status WHEN 'running' THEN 0 ELSE 1 END NormalCNT,
			--1 RejectCNT
		FROM	 bodb02.dbo.zzzbettrans z WITH (nolock)
				INNER JOIN bodb02.dbo.bettrans14 b  WITH (nolock)
				ON  b.transid=z.transid
		WHERE	z.transdate between @datelog AND getdate()
			AND z.status <> 'running'
			AND b.winlostdate = @fromdate 
			AND	b.currency <> 20
			and b.matchid > 29 -- exclude transfer, mix parlay, system parlay
			and (b.bettype < 9 OR b.bettype between 11 and 30 OR b.bettype between 121 and 999)	
	END

	ELSE
	BEGIN

		INSERT INTO #temp(logdate,DetailID,actionid,UserID,Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual)--TicketCNT,NormalCNT,RejectCNT)
		SELECT l.logdate,l.matchid,l.actionid,l.UserID,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Total_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Total_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *spositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Super_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *spositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Super_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *mpositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Master_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *mpositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Master_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *apositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Agent_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) *apositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) Agent_Virtual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * (1-tpositiontaking) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) IBC_Actual,
				sum(abs(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else b.stake end) * (1-tpositiontaking) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end) IBC_Virtual
				--SUM(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else 1 end)  +0  TicketCNT,
				--SUM(case when b.statusID IN (101,102) and z.transdate < l.logdate then 0 else 1 end)  NormalCNT,
				--0 RejectCNT
		FROM DBLOG.bodb_customerlog.dbo.userlog_settle l WITH (nolock)
			INNER JOIN bodb02.dbo.bettrans b WITH (nolock) ON (l.matchid = b.matchid AND b.currency <> 20)
			LEFT JOIN bodb02.dbo.zzzbettrans z WITH (nolock) ON  (b.transid=z.transid)
		
		WHERE		b.winlostdate = @fromdate 
			AND		l.logdate between @datelog AND getdate()
			AND		l.actionid IN(	100,-- calculate all new game
								101,-- calculate FT
								102,-- calculate HT
								103,-- Undo Settlement
								108,-- Calculate FGLG
								109,-- Refund All
								110,-- Refund HT
								111,-- Refund FT
								112,-- Refund FGLG
								123,-- Calculate All for Abandoned/Postponed match
								124,-- Calculate FT for Abandoned/Postponed match
								125	-- Calculate HT for Abandoned/Postponed match	
							)
			AND		((l.actionid IN(100,123) AND b.bettype <> 14 )-- cal all
							OR ((l.actionid IN(101,124) AND b.bettype NOT IN(7,8,15,12,21,30,125,14))-- cal FT
							OR (l.actionid IN(102,125) AND b.bettype IN(7,8,15,12,21,30,125) )-- cal HT
							OR (l.actionid =103 ) -- undo
							OR (l.actionid =108 AND b.bettype = 14 )-- cal FGLG
							OR (l.actionid  = 109 AND b.bettype <> 14 )-- refund all 
							OR (l.actionid  = 111 AND b.bettype NOT IN(7,8,15,12,21,30,125,14))-- refund  FT
							OR (l.actionid =110 AND b.bettype IN(7,8,15,12,21,30,125) )-- refund HT
							OR (l.actionid =112 AND b.bettype = 14)-- refund FGLG
						))
		GROUP BY l.logdate,l.matchid,l.actionid,l.UserID
		ORDER BY l.logdate,l.matchid,l.actionid,l.UserID

		-- Void ticket
		INSERT INTO #temp(logdate,actionid,DetailID,UserID,Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual)--TicketCNT,NormalCNT,RejectCNT)
		SELECT z.transdate,-1,z.transid,b.creator,
			abs(b.stake) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Total_Actual,
			abs(b.stake) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Total_Virtual,
			abs(b.stake) *spositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Super_Actual,
			abs(b.stake) *spositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Super_Virtual,
			abs(b.stake) *mpositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Master_Actual,
			abs(b.stake) *mpositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Master_Virtual,
			abs(b.stake) *apositiontaking * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Agent_Actual,
			abs(b.stake) *apositiontaking * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end Agent_Virtual,
			abs(b.stake) * (1-tpositiontaking) * actualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end IBC_Actual,
			abs(b.stake) * (1-tpositiontaking) * virtualrate * case when b.betteam in ('a','h') then case when abs(b.odds) > 1 then abs(b.odds) else 1 end else 1 end IBC_Virtual
			--CASE z.status WHEN 'running' THEN 1 ELSE 0 END TicketCNT,
			--CASE z.status WHEN 'running' THEN 0 ELSE 1 END NormalCNT,
			--1 RejectCNT
		FROM	 bodb02.dbo.zzzbettrans z WITH (nolock)
				INNER JOIN bodb02.dbo.bettrans b  WITH (nolock)
				ON  b.transid=z.transid
		WHERE	z.transdate between @datelog AND getdate()
			AND z.status <> 'running'
			AND b.winlostdate = @fromdate 
			AND	b.currency <> 20
			and b.matchid > 29 -- exclude transfer, mix parlay, system parlay
			and (b.bettype < 9 OR b.bettype between 11 and 30 OR b.bettype between 121 and 999)		
	END
	
	UPDATE #temp
	SET	Total_Actual = Total_Actual * -1,
		Total_Virtual = Total_Virtual * -1,
		Super_Actual = Super_Actual * -1,
		Super_Virtual = Super_Virtual  * -1,
		Master_Actual = Master_Actual * -1,
		Master_Virtual = Master_Virtual * -1,
		Agent_Actual = Agent_Actual * -1,
		Agent_Virtual = Agent_Virtual * -1,
		IBC_Actual = IBC_Actual * -1,
		IBC_Virtual =IBC_Virtual  * -1
		--NormalCNT = NormalCNT * -1,
		--RejectCNT = CASE WHEN actionid IN(-1,-2) THEN RejectCNT WHEN actionid IN(109,110,111,112) THEN  NormalCNT ELSE RejectCNT  * -1 END,
		--TicketCNT =  (NormalCNT * -1) + CASE WHEN actionid IN(-1,-2) THEN RejectCNT WHEN actionid IN(109,110,111,112) THEN  NormalCNT  ELSE RejectCNT  * -1 END
	WHERE actionid  IN (-1,-2,103,109,110,111,112)

	-- Retrun result
	IF @fromdate <= (select max(distinct eventdate) from match14 (nolock))
	BEGIN
		SELECT CONVERT(VARCHAR(20), logdate, 120)  [DateTime],
				CASE #temp.actionid WHEN -1 THEN 'Void Settled Bet'  ELSE l.ActionNameEN  END [Action],
				CASE #temp.actionid WHEN -1 THEN convert( nvarchar(50),DetailID) WHEN -2 THEN convert( nvarchar(50),DetailID)  
												ELSE teamname.homename + '-vs-' + teamname.awayname + ' $ ' + convert( nvarchar(50),teamname.matchcode) END [Detail] ,
				c.username [Username],
				Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual--TicketCNT,NormalCNT,RejectCNT
		FROM #temp 
			LEFT JOIN DBLOG.bodb_CustomerLog.dbo.LogAction l ON #temp.actionid = l.actionid
			LEFT JOIN ( SELECT m.matchid,m.matchcode,ht.teamname homename,at.teamname awayname
						FROM bodb02.dbo.[match14] m INNER JOIN bodb02.dbo.team ht ON m.homeid = ht.teamid
										INNER JOIN bodb02.dbo.team at ON m.awayid = at.teamid) as teamname
				ON #temp.actionid <> -1 AND #temp.DetailID = teamname.matchid
			INNER JOIN  bodb02.dbo.Customer c ON c.custID = #temp.UserID
		ORDER BY logdate DESC	
	END
	ELSE
	BEGIN
		SELECT CONVERT(VARCHAR(20), logdate, 120)  [DateTime],
				CASE #temp.actionid WHEN -1 THEN 'Void Settled Bet'  ELSE l.ActionNameEN  END [Action],
				CASE #temp.actionid WHEN -1 THEN convert( nvarchar(50),DetailID) WHEN -2 THEN convert( nvarchar(50),DetailID)  
												ELSE teamname.homename + '-vs-' + teamname.awayname + ' $ ' + convert( nvarchar(50),teamname.matchcode) END [Detail] ,
				c.username [Username],
				Total_Actual,Total_Virtual,Super_Actual,Super_Virtual,Master_Actual,Master_Virtual,Agent_Actual,Agent_Virtual,IBC_Actual,IBC_Virtual--TicketCNT,NormalCNT,RejectCNT
		FROM #temp 
			LEFT JOIN DBLOG.bodb_CustomerLog.dbo.LogAction l ON #temp.actionid = l.actionid
			LEFT JOIN ( SELECT m.matchid,m.matchcode,ht.teamname homename,at.teamname awayname
						FROM bodb02.dbo.[match] m INNER JOIN bodb02.dbo.team ht ON m.homeid = ht.teamid
										INNER JOIN bodb02.dbo.team at ON m.awayid = at.teamid) as teamname
				ON #temp.actionid <> -1 AND #temp.DetailID = teamname.matchid
			INNER JOIN  bodb02.dbo.Customer c ON c.custID = #temp.UserID
		ORDER BY logdate DESC	
	END


	DROP TABLE #temp		
END




