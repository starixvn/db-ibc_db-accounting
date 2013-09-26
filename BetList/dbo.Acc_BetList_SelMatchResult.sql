ALTER PROCEDURE [dbo].[Age_BetList_SelMatchResult]
	@MatchID int,
	@RaceNo varchar(50)=NULL	
AS

/*
Created:
Task: Get Result
DB: DBAGE/bodb02

Revisions:    
	- 20091104@Jamie: Show the results of FOdds HR 
	- 20091130@Terry: Show the SCR info of FOdds HR
	- 20091130@Jamie: Get the HR results history (archive)
	- 20100123@Henry: Grant execute to Accounting site
	- 20100730@Henry: Grant execute to bodbExtAccNet
	- 20110307@Lukas: get more sporttype (152,153) & change column name (horseid -> runnerid)
	- 20110721@Johnson: get more columns for HR
	- 20110825@Johnson: get info horses scratched
	- 20110831@Johnson: correct event status when refund ticket
	- 20110907@Sophia: Add column IsHTCal, calculate for Pending Status.
	- 20111003@Sophia: Add column IsPending Pending Status.
	- 20120119@Sophia: Add Showtime for Table - hand - Shoe of Live Casino
	- 20130121@Dan: change linked server DB06 to DBARC
	- 20130226@Elodie: Show the results of Virtual HR
	- 20130826@Kathy: change Status column name
*/

SET NOCOUNT ON
	IF(@RaceNo is NULL )
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
				m.kickofftime,
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
				ISNULL(mr.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending	,
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
				m.kickofftime,
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
				ISNULL(mr.IsPending,0) as IsPending	,
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
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.eventdate,
				m.kickofftime,
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

			SELECT	matchcode AS horseNo, 
					CAST(o.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					o.odds,
					o.placeodds,
					o.leagueid AS meetingid,
					o.oddsstatus eventstatus,
					o.IsFavor,
					o.IsSCR,
					o.FOddsStatus
			FROM	Outright o WITH (NOLOCK)	
						INNER JOIN league l WITH(NOLOCK) ON o.leagueid = l.leagueid
			WHERE	o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND ( ISNULL(placing,0) <> 0 OR isScr = 1)		
			ORDER BY placing									
		END 
		ELSE IF EXISTS( SELECT 1 FROM Outright14 WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	Outright14 WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode AS horseNo, 
					CAST(o.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					o.odds,
					o.placeodds,
					o.leagueid AS meetingid,
					o.oddsstatus eventstatus,
					o.IsFavor,
					o.IsSCR,
					o.FOddsStatus
			FROM	Outright14 o WITH (NOLOCK)
						INNER JOIN league l WITH(NOLOCK) ON l.leagueid = o.leagueid
			WHERE	o.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND (ISNULL(placing,0) <> 0  OR isScr = 1)			
			ORDER BY placing
		END 
		ELSE IF EXISTS( SELECT 1 FROM DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK) WHERE orid = @matchid)
		BEGIN
			SELECT	@leagueid = leagueid , @eventdate = eventdate 
			FROM	DBARC.bodb_Archive.dbo.Outright_bk WITH (NOLOCK)
			WHERE	orid = @matchid 

			SELECT	matchcode AS horseNo, 
					CAST(bk.groupmatch AS INT) AS racename,
					placing AS place, 
					l.sporttype, 
					teamid horseid,
					bk.odds,
					bk.placeodds,
					bk.leagueid AS meetingid,
					bk.oddsstatus eventstatus,
					bk.IsFavor,
					bk.IsSCR,
					bk.FOddsStatus
			FROM	DBARC.bodb_Archive.dbo.Outright_bk bk WITH (NOLOCK)
						INNER JOIN league l WITH(NOLOCK) ON l.leagueid = bk.leagueid
			WHERE	bk.leagueid = @leagueid 
					AND groupmatch = @RaceNo
					AND eventdate = @eventdate 
					AND (ISNULL(placing,0)<> 0  OR isScr = 1)			
			ORDER BY placing
		END 	
		ELSE IF exists(select 1 from VSOutright WITH(NOLOCK) where orid = @RaceNo)
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	VSOutright o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
		ELSE IF exists(select 1 from VSOutright14 WITH(NOLOCK) where orid = @RaceNo)
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	VSOutright14 o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
		ELSE 
		BEGIN
			-- Virtual HR 
			SELECT	RacerNum AS horseNo, 
					r.EventTime AS racename,
					placing AS place, 
					r.SportType,
					o.RacerID horseid,
					o.WinOdds odds,
					o.placeodds,
					'' AS meetingid,
					o.EventStatus eventstatus,
					o.IsFavor,
					'' IsSCR,
					'' FOddsStatus
			FROM	DBARC.bodb_Archive.dbo.VSOutright_bk o WITH (NOLOCK)
					INNER JOIN VSRaceInfo r WITH (NOLOCK) ON r.EventID = o.EventID
			WHERE	o.EventID = @MatchID
					AND (ISNULL(placing,0) <> 0)
			ORDER BY placing
		END
	END

GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelMatchResult] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_BetList_SelMatchResult] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BetList_SelMatchResult] TO [vnteam]