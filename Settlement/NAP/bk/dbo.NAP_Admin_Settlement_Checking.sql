ALTER PROCEDURE [NAP_Admin_Settlement_Checking]
	@matchid int,
	@action varchar(10) = 'CAL',		
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20140108@Kathy
	Task : Settlement checking for Next Goal Bettype
	DB: DBTXN/BODB02 
	Original: Admin_Settlement_Checking

	Revisions:    
	
	
	Param's Explanation:
		- @matchid: The ID of match want to settlement
		- @action: indicate action performed
		 + CAL: Calc all
		 + CAL-HT: Calc HT bet only
		 + CAL-FT: Calc FT bet only
		- @ErrCode: if @ErrCode>0 Invalid of GoalRecord and TotalGoal
		- @ErrMsg: The message will be show if @ErrCode>0
*/

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
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBEXT.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION
	select 'DB053', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBAGE.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION
	select 'DB054', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DB054.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBACC.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
END
ELSE IF (@action = 'CAL-FT')
BEGIN
	INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125) 
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBEXT.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB053', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBAGE.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB054', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DB054.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from DBACC.bodb02.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)	
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

GRANT EXECUTE ON [NAP_Admin_Settlement_Checking] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Settlement_Checking] TO [vnteam] AS [dbo]
GO


