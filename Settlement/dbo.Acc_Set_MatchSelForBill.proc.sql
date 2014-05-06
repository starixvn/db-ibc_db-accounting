ALTER PROCEDURE [Acc_Set_MatchSelForBill]
	@matchid int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IsExistFGLG bit = 0 OUTPUT,	
	@IsExistHTFGLG bit = 0 OUTPUT,	
	@IsHTOnly bit = 0 OUTPUT,
	@IsExistsNG bit = 0 OUTPUT,
	@IsLive bit = 0 OUTPUT,
	@DelayTime INT = 0 OUTPUT
AS
/*	Creator: Viet Hoang
	Date: 2008-12-16
	Task: Select match info for billing
	DB: DBTXN/BODB02
	
	Original: account\editevent_bill.asp
	History:
		- 20081216@VinhTruong: Add calc HT for basket&football
			+ Not checking HAFT TIME for these two sports
		- 20081218@PhuongNguyen: Get IsNeutral from match table instead of match_remark table 
		- 20090310@KhoaTran: Add new sporttypes: 26-Rugby , 27-Cricket, 28-Field Hockey
		- 20090516@Daniel: Check match is ConfirmHT/FT for condition to allow to settle
		- 20090725@Daniel: Add return LIVE game
		- 20091211@Daniel: Discard VOID & REJECT tickets when checking Existing of FGLG tickets
		- 20100121@Daniel: Add check kickoff time for Suqash(30) and Winter sports(29)
		- 20100526@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100527@Jamie: Add new sport: 31-Entertainment 
		- 20100826@KhoaTran: Add bettype=21 in condition
		- 20101019@Thien: Select @DelayTime (requirement: Put delay on settlement of big matches on weekend)
		- 20110421@Lukas: add Netball game (sporttype = 32)
		- 20110620@Jamie: Refer Match in DB02 instead of DBTRANS
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books		
		- 20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP
		- 20120625@Elodie: Add 10 new sports with sport types: 33, 34, 35, 36, 37, 38, 39, 40, 41, 42 into group 4(CURRENT_TIMESTAMP - kickofftime >= 30)
		- 20120816@Dan: add virtual soccer
		- 20121113@Elodie: Exclude sporting solution product
		- 20121127@Lukas: show FGLG info in parlay tickets
		- 20130121@Elodie: Change link server DB02 to DBPRO
		- 20130822@Johnson: Get match information for match completed
		- 20131022@Lukas: add new sporttype 154 - Horse racing FixOdds
		- 20140422@Kathy: + Add new param @IsExistHTFGLG	
						  + Add new bettype 1H total goal, 1H FGLG (126, 127)  [Redmine:#14718]
	Param's Explanation:
		+ @IsExistFGLG = 1 : exist FGLG ticket
		+ @IsExistHTFGLG = 1 : exist HT FGLG ticket
		+ @IsLive = 1 : Match is offered LIVE betting
		
*/
SET NOCOUNT ON
set @ErrCode = 0

-------------------------------------------------------------
---Select @DelayTime (Put/check delay on settlement of big matches on weekend)
---------------------------VVVV------------------------------
DECLARE @NextAllowSettleTime datetime

SELECT @DelayTime = 0

--check whether it's at weekend peak-hour, from 7PM - 2AM (GMT+8)
--if datename(weekday, getdate()) in ('Saturday','Sunday') and datepart(hour, getdate()) between 7 and 14
--BEGIN
	select @NextAllowSettleTime = VValue from SystemSettings with (nolock) where VName = 'NextAllowSettleTime' 
	select @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
							ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END
--END
--------------------------------
if exists(	select	1 
			from	DBPRO.BODB02.dbo.match m with (nolock) 
					left join DBPRO.BODB02.dbo.match_remark mr with (nolock) on m.matchid = mr.matchid
			where m.matchid = @matchid AND 			
			(
			(sporttype in (1,180) and datediff(minute,kickofftime,CURRENT_TIMESTAMP) > 45)--bill soccer HT
			OR
			(sporttype in (2,3,26,32) and datediff(minute,kickofftime,CURRENT_TIMESTAMP) > 30)--bill Basket, Football HT
			OR
			(sporttype in (4,6,8) and datediff(minute,kickofftime,CURRENT_TIMESTAMP) >= 60)
			OR
			(sporttype in (5,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,27,28,29,30,31,33,34,35,36,37,38,39,40,41,42,99) and datediff(minute,kickofftime,CURRENT_TIMESTAMP) >= 30)
			OR 
			(sporttype in (154) and datediff(minute,kickofftime,CURRENT_TIMESTAMP) >= 5)
			OR
			(Isnull(ConfirmHT, 0) > 0)
			OR
			(isnull(ConfirmFT, 0) > 0)
			OR m.eventstatus = 'completed'
			)
		) --or (1 = 1)
		OR @matchid = 5542203 --viet@20130819

BEGIN
	IF EXISTS (select 1 from bettrans with (nolock) where bettype = 14 and matchid = @matchid 
				AND [statusID] NOT IN (101,102)
				)
		OR EXISTS (select 1 from bettransm with (nolock) where bettype = 14 and matchid = @matchid  AND statusID not in (103,101,102))
	BEGIN
		SELECT @IsExistFGLG = 1
	END

	IF EXISTS (select 1 from bettrans with (nolock) where bettype = 127 and matchid = @matchid 
				AND [statusID] NOT IN (101,102)
				)
		OR EXISTS (select 1 from bettransm with (nolock) where bettype = 127  and matchid = @matchid  AND statusID not in (103,101,102))
	BEGIN
		SELECT @IsExistHTFGLG = 1
	END

	if
	( 
		exists
		(--HT Soccer
			select	1 
			from	DBPRO.BODB02.dbo.match m with (nolock) 
					inner join DBPRO.BODB02.dbo.match_remark mr with (nolock) on m.matchid = mr.matchid
			where	m.matchid=@matchid 
					AND sporttype = 1 
					AND datediff(minute,kickofftime,CURRENT_TIMESTAMP) < 100
					AND (datediff(minute,kickofftime,CURRENT_TIMESTAMP) > 45 or isnull(ConfirmHT,0) > 0)
					AND isnull(ConfirmFT,0) = 0
		)
			
/*		OR			
		exists(--HT Basketball & Football
		select 1 
		from match with (nolock) 
		where matchid=@matchid 
			AND sporttype IN(2,3)
			AND datediff(minute,kickofftime,CURRENT_TIMESTAMP) < 60
			AND datediff(minute,kickofftime,CURRENT_TIMESTAMP) > 30) 
*/
	)		
	BEGIN
		Select @IsHTOnly = 1
	END
	Declare @status TABLE ([Group] tinyint, BetCount int, InRunning int)
	INSERT INTO @status
	SELECT
		CASE -- 0:FT , 1:HT , 2:FGLG, 3: HT FGNG
			WHEN bettype IN (7, 8, 12, 15, 21,30, 125, 126) THEN 1
			WHEN bettype = 14 THEN 2
			WHEN bettype = 127 THEN 3
			ELSE 0 END,
		--SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE WHEN [statusID] IN (101,102) THEN 0 ELSE 1 END),
		--SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
		SUM(CASE WHEN [statusID] = 0 THEN 1 ELSE 0 END)
	FROM
		bettrans with (nolock)
	WHERE
		matchid = @matchid and bettype not between 1301 and 1334 -- 20121113@Elodie: Exclude sporting solution product
	GROUP BY
		CASE WHEN bettype IN (7, 8, 12, 15, 21,30, 125, 126) THEN 1 
			 WHEN bettype = 14 THEN 2 
			 WHEN bettype = 127 THEN 3 
			 ELSE 0 END

	IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 0) INSERT INTO @status VALUES (0,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 1) INSERT INTO @status VALUES (1,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 2) INSERT INTO @status VALUES (2,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 3) INSERT INTO @status VALUES (3,0,0)

	Declare @FTStatus nvarchar(20), @HTStatus nvarchar(20), @FGLGStatus nvarchar(20), @HTFGLGStatus nvarchar(20)
	DECLARE @ParlayRunning BIT /* NULL no ticket, 1 running, 0 settled*/
			, @HTParlayRunning BIT
	
	SELECT TOP 1 @ParlayRunning = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
	FROM bettransm WITH(NOLOCK)
	WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102)

	SELECT TOP 1 @HTParlayRunning = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
	FROM bettransm WITH(NOLOCK)
	WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102)
	
		
	Select @FTStatus = CASE
			WHEN betcount  = 0 THEN N'No Ticket'
			WHEN inRunning = 0 THEN N'SETTLED'
			ELSE N'Running' END FROM @status WHERE [Group] = 0
	Select @HTStatus = CASE
			WHEN betcount  = 0 THEN N'No Ticket'
			WHEN inRunning = 0 THEN N'SETTLED'
			ELSE N'Running' END FROM @status WHERE [Group] = 1
	Select @FGLGStatus = CASE
			WHEN betcount  = 0 THEN CASE WHEN @ParlayRunning IS NULL THEN N'No Ticket'
										 WHEN @ParlayRunning = 1 THEN N'Parlay Running'	
										 WHEN @ParlayRunning = 0 THEN N'Parlay Settled'
									END
			WHEN inRunning = 0 THEN N'SETTLED'
			ELSE N'Running' END FROM @status WHERE [Group] = 2
	Select @HTFGLGStatus = CASE
			WHEN betcount  = 0 THEN CASE WHEN @HTParlayRunning IS NULL THEN N'No Ticket'
										 WHEN @HTParlayRunning = 1 THEN N'Parlay Running'	
										 WHEN @HTParlayRunning = 0 THEN N'Parlay Settled'
									END
			WHEN inRunning = 0 THEN N'SETTLED'
			ELSE N'Running' END FROM @status WHERE [Group] = 3

	IF EXISTS(select 1 from bettrans (nolock) where matchid = @matchid and bettype = 22)
		Select @IsExistsNG = 1
	
	IF EXISTS(select top 1 1 from bettrans (nolock) where matchid = @matchid and liveindicator = 1)
		Select @IsLive = 1


	select match.sporttype, match.betstatus, hthomescore,htawayscore,
		datediff(minute,match.kickofftime,CURRENT_TIMESTAMP) playtime,
		match.leagueid,		
		match.matchid, 
		match.homeid,
		match.awayid,		
		match.matchcode,match.eventdate,
		match.finalhomescore,match.finalawayscore,match.eventstatus,
		isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,
		isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		@HTStatus HTStatus,
		@FTStatus FTStatus,
		@FGLGStatus fglgstatus,
		@HTFGLGStatus HTFGLGStatus,
		mr.ishtcal,
		match.GoalRecord
	from	DBPRO.BODB02.dbo.match with (nolock) 		
			left outer join DBPRO.BODB02.dbo.match_remark mr with (nolock) on match.matchid = mr.matchid
	where match.matchid = @matchid
	order by match.eventdate,match.matchcode
END
ELSE
BEGIN
	Select @ErrMsg = 'Follow by match kick off time, this match is not over yet!!! Please check carefully !!!',
		@ErrCode = 101
	Return
END

GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelForBill] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSelForBill] TO [vnteam] AS [dbo]