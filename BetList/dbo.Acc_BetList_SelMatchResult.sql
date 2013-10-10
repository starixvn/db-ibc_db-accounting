ALTER PROCEDURE [dbo].[Acc_BetList_SelMatchResult]
	@MatchID int,
	@RaceNo varchar(50)=NULL
AS

/*
Created:
Task: Get Result
DB: DBAGE/bodb02
Original: Age_BetList_SelMatchResult

Revisions:    
	- 20091104@Jamie: Show the results of FOdds HR 
	- 20091130@Terry: Show the SCR info of FOdds HR
	- 20091130@Jamie: Get the HR results history (archive)
	- 20100123@Henry: Grant execute to Accounting site
	- 20100730@Henry: Grant execute to bodbExtAccNet
	- 20110307@Lukas: get more sporttype (152,153) & change column name (horseid -> runnerid)
	- 20110907@Sophia: Add column IsHTCal, calculate for Pending Status. Edit eventstatus
	- 20111003@Sophia: Add column IsPending Pending Status.
	- 20120130@Sopghia: Add Showtime for Table - hand - Shoe of Live Casino
	- 20120921@Elodie: Get kickofftime field
	- 20130121@Dan: change linked server DB06 to DBARC
	- 20130226@Elodie: Show the results of Virtual HR
	- 20131010@Kathy: Turn to use GlobalShowTime for display the Kick-off-Time [redmine:#6076]
*/

SET NOCOUNT ON
	IF(@RaceNo is NULL)
	BEGIN
		IF exists(SELECT 1 FROM match WITH(NOLOCK) WHERE matchid = @matchid)
		BEGIN	
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.GlobalShowTime AS kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund, 
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate,
				ISNULL(mr.IsPending,0) as IsPending,
				m.showtime	
			FROM match m WITH(NOLOCK)
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END
		IF exists(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @matchid)	
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.globalshowtime AS kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund, 
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate,
				ISNULL(mr.IsPending,0) as IsPending,
				m.showtime	
			FROM match14 m WITH(NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END
		ELSE
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,globalshowtime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.globalshowtime AS kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund,  
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate,
				ISNULL(mr.IsPending,0) as IsPending,
				m.showtime
			FROM DBARC.bodb_archive.dbo.Match_BK m WITH(NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
		END
	END
	ELSE
	BEGIN
		DECLARE	@leagueid INT, @eventdate DATETIME 
		IF exists(select 1 from outright WITH(NOLOCK) where orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	Outright WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode, 
					placing, 
					l.sporttype, 
					teamid runner,
					o.leagueid,
					'' EventTime,
					'' HorseNo,
					'' WinOdds,
					'' PlaceOdds,
					'' IsFavor
			FROM	Outright o WITH (NOLOCK)	
			INNER JOIN league l WITH(NOLOCK) ON o.leagueid = l.leagueid
			WHERE	o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND isnull(placing,0) <> 0
			ORDER BY placing
		
			SELECT	 matchcode
					,teamid 	
					,CONVERT(VARCHAR,SCRTime,108) SCRTime
					,risk Deduction
			FROM	Outright WITH (NOLOCK)
			WHERE	leagueid = @leagueid 
					AND groupmatch = @raceNo 
					AND eventdate = @eventdate 
					AND IsSCR = 1	
					AND FOddsStatus = 'completed'
			ORDER BY CAST (matchcode AS TINYINT) 
			
		END 
		ELSE IF EXISTS( SELECT 1 FROM Outright14 WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	Outright14 WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode, 
					placing, 
					l.sporttype, 
					teamid runner, 
					o.leagueid,
					'' EventTime,
					'' HorseNo,
					'' WinOdds,
					'' PlaceOdds,
					'' IsFavor
			FROM	Outright14 o WITH (NOLOCK)
						INNER JOIN league l WITH(NOLOCK) ON l.leagueid = o.leagueid
			WHERE	o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND isnull(placing,0) <> 0
			ORDER BY placing	
			SELECT	 matchcode
					,teamid 	
					,CONVERT(VARCHAR,SCRTime,108) SCRTime
					,risk Deduction
			FROM	Outright14 WITH (NOLOCK)
			WHERE	leagueid = @leagueid 
					AND groupmatch = @raceNo 
					AND eventdate = @eventdate 
					AND IsSCR = 1	
					AND FOddsStatus = 'completed'
			ORDER BY CAST (matchcode AS TINYINT) 
		END 
		ELSE IF EXISTS( SELECT 1 FROM DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode, 
					placing, 
					l.sporttype, 
					teamid runner, 
					bk.leagueid,
					'' EventTime,
					'' HorseNo,
					'' WinOdds,
					'' PlaceOdds,
					'' IsFavor
			FROM	DBARC.bodb_Archive.dbo.Outright_bk bk WITH (NOLOCK)
						INNER JOIN league l WITH(NOLOCK) ON l.leagueid = bk.leagueid
			WHERE	bk.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND isnull(placing,0) <> 0
			ORDER BY placing	

			SELECT	 matchcode
					,teamid 	
					,CONVERT(VARCHAR,SCRTime,108) SCRTime
					,risk Deduction
			FROM	DBARC.bodb_archive.dbo.Outright_bk WITH (NOLOCK)
			WHERE	leagueid = @leagueid 
					AND groupmatch = @raceNo 
					AND eventdate = @eventdate 
					AND IsSCR = 1	
					AND FOddsStatus = 'completed'
			ORDER BY CAST (matchcode AS TINYINT) 
		END 
		ELSE IF EXISTS( SELECT 1 FROM VSOutright WITH (NOLOCK) WHERE orid = @RaceNo)
		BEGIN			
			SELECT	'' matchcode, 
					placing, 
					r.sporttype, 
					RacerID runner, 
					r.leagueid,
					r.EventTime,
					RacerNum HorseNo,
					o.WinOdds,
					o.PlaceOdds,
					o.IsFavor
			FROM	VSOutright o WITH (NOLOCK)
						INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID 
					AND isnull(placing,0) <> 0
			ORDER BY placing	
			
			SELECT	'' matchcode,0,'' SCRTime,0 Deduction			
		END 
		ELSE IF EXISTS( SELECT 1 FROM VSOutright14 WITH (NOLOCK) WHERE orid = @RaceNo)
		BEGIN			
			SELECT	'' matchcode, 
					placing, 
					r.sporttype, 
					RacerID runner, 
					r.leagueid,
					r.EventTime,
					RacerNum HorseNo,
					o.WinOdds,
					o.PlaceOdds,
					o.IsFavor
			FROM	VSOutright14 o WITH (NOLOCK)
						INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID 
					AND isnull(placing,0) <> 0
			ORDER BY placing	
			
			SELECT	'' matchcode,0,'' SCRTime,0 Deduction			
		END 
		ELSE IF EXISTS( SELECT 1 FROM DBARC.bodb_archive.dbo.VSOutright_bk WITH (NOLOCK) WHERE orid = @RaceNo)
		BEGIN			
			SELECT	'' matchcode, 
					placing, 
					r.sporttype, 
					RacerID runner, 
					r.leagueid,
					r.EventTime,
					RacerNum HorseNo,
					o.WinOdds,
					o.PlaceOdds,
					o.IsFavor
			FROM	DBARC.bodb_archive.dbo.VSOutright_bk o WITH (NOLOCK)
						INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID 
					AND isnull(placing,0) <> 0
			ORDER BY placing	
			
			SELECT	'' matchcode,0,'' SCRTime,0 Deduction			
		END 
	END

GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelMatchResult] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelMatchResult] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetList_SelMatchResult] TO [vnteam]