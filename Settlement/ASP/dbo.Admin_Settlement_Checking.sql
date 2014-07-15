ALTER PROCEDURE [Admin_Settlement_Checking]
	@matchid int,
	@action varchar(10) = 'CAL',		
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 20090215@Khoa
Task : Settlement checking for Next Goal Bettype
DB: DBTXN/BODB02 

Revisions:    
	Vinh@20090218: 
		- Change to check GoalRecord based on input FT score
		- Check GoalRecord for Home and Away consistently
		- Add check replication data: add @action for checking FT & HT tickets
	Vinh@20090312: 
		- Remove check GoalRecord, check in the web instead
		- Add check Handicap value for NEXT GOAL (not allow > 1)
	Vinh@20090324: 
		- Add back param @action for checking replication for HT/FT/All bets
	PhuongDao@20090423:
		- Change from DB05 to DB052
	Thien@20090521: change alert message, include DB05 and DB052
	Thien@20110622: change the param name from DB02 to DBTrans. Add back DB05
	Lukas@20110907: Change linked-server from DB052 to DB053
	Tom@20110912: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books		
	20111014@Jamie: Remove checking total tickets for DB05
	20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP
	20120210@Viet: add check RUNNING tickets' count
	20120608@Jamie: Add DB054 checking 
	20121022@Elodie: Exclude sporting solution product
	20140514@Kathy: Add 2 new bettypes: 1H Total Goal and 1H FGLG (126, 127) [Redmine:#14718]
	
Param's Explanation:
	- @matchid: The ID of match want to settlement
	- @action: indicate action performed
	 + CAL: Calc all
	 + CAL-HT: Calc HT bet only
	 + CAL-FT: Calc FT bet only
    - @ErrCode: if @ErrCode>0 Invalid of GoalRecord and TotalGoal
    - @ErrMsg: The message will be show if @ErrCode>0
*/
return 
if exists(select 1 from bettrans with (nolock) where matchid = @matchid and bettype = 22 and (hdp1>1 or hdp2>1))
BEGIN
	select 
		@ErrCode = 101, 
		@ErrMsg = 'Invalid Handicap value for Next goal tickets! Cannot calculate!'    
		return                    
END	

--Check replication:
declare @temp as table(db varchar(10), betCNT int, runningCNT int, waitingCNT int)
declare @min1 int, @min2 int, @max1 int, @max2 int, @maxWaiting int

IF (@action = 'CAL-HT')
BEGIN
	INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125,126,127)
	UNION 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBEXT.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125,126,127)
	UNION
	select 'DB053', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBAGE.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125,126,127)
	UNION
	select 'DB054', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DB054.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125,126,127)
	UNION
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBACC.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125,126,127)	
END
ELSE IF (@action = 'CAL-FT')
BEGIN
	INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125,126,127) 
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBEXT.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125,126,127)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB053', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBAGE.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125,126,127)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB054', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DB054.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125,126,127)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBACC.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125,126,127)	
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END
ELSE IF (@action = 'CAL')
BEGIN
	INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBEXT.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB053', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBAGE.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB054', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DB054.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBACC.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END

select @min1= min(betCNT), @max1 = max(betCNT), @min2= min(runningCNT), @max2=max(runningCNT), @maxWaiting = max(waitingCNT)
from @temp
--where db <> 'DB052'
if @@servername = 'DB206' return
IF @max1 > @min1 OR @max2 > @min2 OR @maxWaiting > 0
BEGIN
	select 
		@ErrCode = 102, 
		@ErrMsg = 'System is not ready to calculate this match. Please try again after few minutes.'    
	return                    
END


GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Checking] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_Checking] TO [vnteam]