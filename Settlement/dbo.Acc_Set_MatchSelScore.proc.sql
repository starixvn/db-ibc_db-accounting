ALTER PROCEDURE [Acc_Set_MatchSelScore]
	@matchid int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IsExistFGLG bit = 0 OUTPUT,
	@IsExistLG bit = 0 OUTPUT,
	@IsSettleAbandonedMatchIBC bit = 0 output
AS

/*
	Created by: []
	Task: Update score 
	DB: DBTXN/BODB02 
	Original: \account\Calculate_SaveScore.asp
	
	Revisions:
		- 20081218@Phuong.Nguyen@UPDATED: 2008-12-18
		- 20100531@Henry: Change to use statusID instead of status
		- 20100827@Jamie: 1st Money Line 
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTRANS	
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books	
		- 20111025@Tom: 1. Include search Bettransm when bettype = 14 not exist in bettrans for case @IsExistFGLG.
						2. Add parameter @IsExistLG to check ticket Last Goal only in Bettrans and Bettransm.
		- 20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP
		- 20121113@Elodie: Exclude sporting solution product
		- 20130121@Elodie: Change link server DB02 to DBPRO
		- 20130401@Lukas: Get goalrecord field & correct fieldname fslgstatus -> fglgstatus
		- 20140313@Kathy: Execute settlement for abandoned/postponed matches (bettype:13,26,27) [Redmine:#12049]
*/
SET NOCOUNT ON 
DECLARE @sporttype tinyint
SELECT @IsExistLG = 0, @IsExistFGLG = 0, @IsSettleAbandonedMatchIBC = 0

SELECT @sporttype  = sporttype
from match with(NOLOCK)
where matchid = @matchid

IF EXISTS (select top 1 1 from bettrans with (nolock) where matchid = @matchid and bettype = 14 AND right(BETTEAM,1) = '2' AND statusID not in (103,101,102))
	SELECT @IsExistLG = 1
ELSE
	IF EXISTS (select top 1 1 from bettransm with (nolock) where matchid = @matchid and bettype = 14 AND right(BETTEAM,1) = '2' AND statusID not in (103,101,102))
		SELECT @IsExistLG = 1

IF (@IsExistLG = 0)
BEGIN
	IF EXISTS (select top 1 1 from bettrans with (nolock) where matchid = @matchid and bettype = 14 AND statusID not in (103,101,102))
		SELECT @IsExistFGLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm with (nolock) where matchid = @matchid and bettype = 14 AND statusID not in (103,101,102))
			SELECT @IsExistFGLG = 1
END
ELSE
	SELECT @IsExistFGLG = 1

IF (
		EXISTS (
			SELECT 1
			FROM bettrans WITH (NOLOCK)
			WHERE bettype IN (13, 26, 27) AND matchid = @matchid AND statusID NOT IN (101, 102, 103) AND ruben = 0
			AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156) 
			) AND @sporttype = 1
		)
BEGIN
	SELECT @IsSettleAbandonedMatchIBC = 1

	IF EXISTS (
			SELECT 1
			FROM bettrans WITH (NOLOCK)
			WHERE matchid = @matchid AND bettype IN (13, 26, 27) AND statusID NOT IN (101, 102) AND ruben = 1
			AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156)
			) OR @sporttype <> 1
	BEGIN
		SELECT @IsSettleAbandonedMatchIBC = 0
	END
END
/*
if exists (select 1 from match with (nolock) where eventstatus = 'completed' and matchid = @matchid)
BEGIN
	Select @ErrMsg = 'This match has been completed!!',
		@ErrCode = 101
	Return
END
*/
Declare @status TABLE ([Group] tinyint, BetCount int, InRunning int)
INSERT INTO @status
	SELECT
		CASE -- 0:FT , 1:HT , 2:FGLG
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1
			WHEN bettype = 14 THEN 2
			ELSE 0 END,
		--SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE WHEN [statusID] IN (101,102) THEN 0 ELSE 1 END),
		--SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
		SUM(CASE WHEN [statusID] = 0 THEN 1 ELSE 0 END)
	FROM
		bettrans with (nolock)
	WHERE
		matchid = @matchid and bettype not between 1301 and 1334
	GROUP BY
		CASE WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1 WHEN bettype = 14 THEN 2 ELSE 0 END

IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 0) INSERT INTO @status VALUES (0,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 1) INSERT INTO @status VALUES (1,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 2) INSERT INTO @status VALUES (2,0,0)

Declare @FTStatus nvarchar(10), @HTStatus nvarchar(10), @FGLGStatus nvarchar(10)

Select @FTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'SETTLED'
		ELSE N'Running' END FROM @status WHERE [Group] = 0
Select @HTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'SETTLED'
		ELSE N'Running' END FROM @status WHERE [Group] = 1
Select @FGLGStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'SETTLED'
		ELSE N'Running' END FROM @status WHERE [Group] = 2

select	match.sporttype, match.betstatus, hthomescore,htawayscore,
		datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,	
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
		match.goalrecord
from	DBPRO.BODB02.dbo.match with (nolock) 	
		left outer join DBPRO.BODB02.dbo.match_remark mr with (nolock) on match.matchid = mr.matchid
where match.matchid = @matchid
order by match.eventdate,match.matchcode





GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelScore] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchSelScore] TO [VNTeam]
GO 