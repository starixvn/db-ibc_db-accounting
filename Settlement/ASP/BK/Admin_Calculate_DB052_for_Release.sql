ALTER PROCEDURE [dbo].[Admin_Calculate_1]
	@matchid int,
	@bettype tinyint,
	@fth smallmoney,
	@fta smallmoney,
	@betcount int = 0
AS
/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB052.BODB02
	
	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20091126@Daniel: Check syncronize of remote replication 
		- 20100424@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20100628@Thien: put exception to skip for MAIN World Cup matches. These matches will be calculated manually in DB05/DB052
*/
SET NOCOUNT ON
---------------------------------------------------
IF @@SERVERNAME <> 'DB052'
    OR @matchid in (796071 --Argentina - Mexico
                    ,797608	--Netherlands - Slovakia
                    ,798155	--Brazil - Chile
                    ,797609 --Paraguay Japan
                    ,798156 --Spain Portugal
                    ,799855	--Brazil - Netherlands
                    ,798903	--Uruguay - Ghana
                    ,799441 --Argentina - Germany
                    ,800279	--Spain - Paraguay
                    ,801785	--Netherlands - Uruguay
                    ,802350	--Spain-Germany
                    ,803952	--Germany-Uruguay
                    ,803953	--Spain-Netherlands
                    )
BEGIN
    RETURN
END
---------------------------------------------------
Declare @modds smallmoney, @RemoteCount int

CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

UPDATE b
SET @modds = modds = CASE betteam
	WHEN N'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
	WHEN N'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
	END,

WinLost = CASE
	WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
	WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
	WHEN @modds =  0	THEN actual_stake
	WHEN @modds = -0.25	THEN actual_stake * 0.5
	WHEN @modds < -0.25	THEN 0
	END,

aWinLost = CASE
	WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
	WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
	WHEN @modds =  0	THEN 0
	WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
	WHEN @modds < -0.25	THEN actual_stake * apositiontaking
	END,
mWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
	END,
sWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
	END,

PlayerComm = CASE
	WHEN @modds >  0.25 	THEN playerdiscount * stake
	WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds < -0.25 	THEN playerdiscount * stake
	END,
Comm = CASE
	WHEN @modds >  0.25 	THEN discount * stake * (1-apositiontaking)
	WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds < -0.25 	THEN discount * stake * (1-apositiontaking)
	END,
aComm = CASE
	WHEN @modds >  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	END,
sComm = CASE
	WHEN @modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END,

Status = CASE
	WHEN @modds > 0 THEN N'WON'
	WHEN @modds = 0 THEN N'DRAW'
	WHEN @modds < 0 THEN N'LOSE'
	END,
StatusID = CASE
	WHEN @modds > 0 THEN 112 --WON
	WHEN @modds = 0 THEN 111 --DRAW
	WHEN @modds < 0 THEN 113 --LOSE
	END,
ruben=1
FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
    INNER JOIN #tmpRecommend ag ON b.recommend = ag.recommend
WHERE
	matchid=@matchid AND
	bettype=@bettype AND
	--[status] NOT IN (N'VOID', N'REJECT')
	statusID NOT IN (101,102)
	
DROP TABLE #tmpRecommend


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_1] TO [vnteam]
GO
ALTER PROCEDURE [dbo].[Admin_Calculate_3]
	@matchid int,
	@bettype tinyint,
	@totalgoal smallmoney
AS

/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB052.BODB02
	
	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20100517@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- - 20100628@Thien: put exception to skip for MAIN World Cup matches. These matches will be calculated manually in DB05/DB052

*/
SET NOCOUNT ON
---------------------------------------------------
IF @@SERVERNAME <> 'DB052'
    OR @matchid in (796071 --Argentina - Mexico
                    ,797608	--Netherlands - Slovakia
                    ,798155	--Brazil - Chile
                    ,797609 --Paraguay Japan
                    ,798156 --Spain Portugal
                    ,799855	--Brazil - Netherlands
                    ,798903	--Uruguay - Ghana
                    ,799441 --Argentina - Germany
                    ,800279	--Spain - Paraguay
                    ,801785	--Netherlands - Uruguay
                    ,802350	--Spain-Germany
                    ,803952	--Germany-Uruguay
                    ,803953	--Spain-Netherlands
                    )
BEGIN
    RETURN
END
---------------------------------------------------

Declare @modds smallmoney

CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

UPDATE b
SET @modds = modds = CASE betteam
	WHEN N'h' THEN @totalgoal-hdp1
	WHEN N'a' THEN hdp1-@totalgoal
	END,

WinLost = CASE
	WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
	WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
	WHEN @modds =  0	THEN actual_stake
	WHEN @modds = -0.25	THEN actual_stake * 0.5
	WHEN @modds < -0.25	THEN 0
	END,

aWinLost = CASE
	WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
	WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
	WHEN @modds =  0	THEN 0
	WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
	WHEN @modds < -0.25	THEN actual_stake * apositiontaking
	END,
mWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
	END,
sWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
	END,

PlayerComm = CASE
	WHEN @modds >  0.25 	THEN playerdiscount * stake
	WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds < -0.25 	THEN playerdiscount * stake
	END,
Comm = CASE
	WHEN @modds >  0.25 	THEN discount * stake * (1-apositiontaking)
	WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds < -0.25 	THEN discount * stake * (1-apositiontaking)
	END,
aComm = CASE
	WHEN @modds >  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	END,
sComm = CASE
	WHEN @modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END,

Status = CASE
	WHEN @modds > 0 THEN N'WON'
	WHEN @modds = 0 THEN N'DRAW'
	WHEN @modds < 0 THEN N'LOSE'
	END,
StatusID = CASE
	WHEN @modds > 0 THEN 112 --WON
	WHEN @modds = 0 THEN 111 --DRAW
	WHEN @modds < 0 THEN 113 --LOSE
	END,
ruben=1
FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
    INNER JOIN #tmpRecommend ag ON b.recommend = ag.recommend
WHERE
	matchid=@matchid AND
	bettype=@bettype AND
	--status NOT IN (N'VOID', N'REJECT')
	statusID NOT IN (101,102)
	
DROP TABLE #tmpRecommend

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_3] TO [vnteam]

GO

 ALTER PROCEDURE [dbo].[Admin_Calculate_7]
	@matchid int,
	@bettype tinyint,
	@hth smallmoney,
	@hta smallmoney,
	@betcount int = 0
AS
/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB052.BODB02
	
	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20091126@Daniel: Check syncronize of remote replication 
		- 20100424@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20100628@Thien: put exception to skip for MAIN World Cup matches. These matches will be calculated manually in DB05/DB052
*/
SET NOCOUNT ON
---------------------------------------------------
IF @@SERVERNAME <> 'DB052'
    OR @matchid in (796071 --Argentina - Mexico
                    ,797608	--Netherlands - Slovakia
                    ,798155	--Brazil - Chile
                    ,797609 --Paraguay Japan
                    ,798156 --Spain Portugal
                    ,799855	--Brazil - Netherlands
                    ,798903	--Uruguay - Ghana
                    ,799441 --Argentina - Germany
                    ,800279	--Spain - Paraguay
                    ,801785	--Netherlands - Uruguay
                    ,802350	--Spain-Germany
                    ,803952	--Germany-Uruguay
                    ,803953	--Spain-Netherlands
                    )
BEGIN
    RETURN
END
---------------------------------------------------
Declare @modds smallmoney, @RemoteCount int
	
CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

UPDATE b
SET @modds = modds = CASE betteam
	WHEN 'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
	WHEN 'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
	END,

WinLost = CASE
	WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
	WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
	WHEN @modds =  0	THEN actual_stake
	WHEN @modds = -0.25	THEN actual_stake * 0.5
	WHEN @modds < -0.25	THEN 0
	END,

aWinLost = CASE
	WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
	WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
	WHEN @modds =  0	THEN 0
	WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
	WHEN @modds < -0.25	THEN actual_stake * apositiontaking
	END,
mWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
	END,
sWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
	END,

PlayerComm = CASE
	WHEN @modds >  0.25 	THEN playerdiscount * stake
	WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds < -0.25 	THEN playerdiscount * stake
	END,
Comm = CASE
	WHEN @modds >  0.25 	THEN discount * stake * (1-apositiontaking)
	WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds < -0.25 	THEN discount * stake * (1-apositiontaking)
	END,
aComm = CASE
	WHEN @modds >  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	END,
sComm = CASE
	WHEN @modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END,

[status] = CASE
	WHEN @modds > 0 THEN 'WON'
	WHEN @modds = 0 THEN 'DRAW'
	WHEN @modds < 0 THEN 'LOSE'
	END,
StatusID = CASE
	WHEN @modds > 0 THEN 112 --WON
	WHEN @modds = 0 THEN 111 --DRAW
	WHEN @modds < 0 THEN 113 --LOSE
	END,
ruben=1
FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
    INNER JOIN #tmpRecommend ag ON b.recommend = ag.recommend
WHERE
	matchid=@matchid AND
	bettype=@bettype AND
	--[status] NOT IN (N'VOID', N'REJECT')
	statusID NOT IN (101,102)

DROP TABLE #tmpRecommend


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_7] TO [vnteam]
GO
ALTER PROCEDURE [dbo].[Admin_Calculate_8]
	@matchid int,
	@bettype tinyint,
	@totalht smallmoney
AS
/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB052.BODB02
	
	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20100517@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and another for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20100628@Thien: put exception to skip for MAIN World Cup matches. These matches will be calculated manually in DB05/DB052
*/
SET NOCOUNT ON
---------------------------------------------------
IF @@SERVERNAME <> 'DB052'
    OR @matchid in (796071 --Argentina - Mexico
                    ,797608	--Netherlands - Slovakia
                    ,798155	--Brazil - Chile
                    ,797609 --Paraguay Japan
                    ,798156 --Spain Portugal
                    ,799855	--Brazil - Netherlands
                    ,798903	--Uruguay - Ghana
                    ,799441 --Argentina - Germany
                    ,800279	--Spain - Paraguay
                    ,801785	--Netherlands - Uruguay
                    ,802350	--Spain-Germany
                    ,803952	--Germany-Uruguay
                    ,803953	--Spain-Netherlands
                    )
BEGIN
    RETURN
END
---------------------------------------------------

Declare @modds smallmoney

CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

UPDATE b
SET @modds = modds = CASE betteam
	WHEN 'h' THEN @totalht-hdp1
	WHEN 'a' THEN hdp1-@totalht
	END,

WinLost = CASE
	WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
	WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
	WHEN @modds =  0	THEN actual_stake
	WHEN @modds = -0.25	THEN actual_stake * 0.5
	WHEN @modds < -0.25	THEN 0
	END,

aWinLost = CASE
	WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
	WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
	WHEN @modds =  0	THEN 0
	WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
	WHEN @modds < -0.25	THEN actual_stake * apositiontaking
	END,
mWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
	END,
sWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
	END,

PlayerComm = CASE
	WHEN @modds >  0.25 	THEN playerdiscount * stake
	WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds < -0.25 	THEN playerdiscount * stake
	END,
Comm = CASE
	WHEN @modds >  0.25 	THEN discount * stake * (1-apositiontaking)
	WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds < -0.25 	THEN discount * stake * (1-apositiontaking)
	END,
aComm = CASE
	WHEN @modds >  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	END,
sComm = CASE
	WHEN @modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END,

Status = CASE
	WHEN @modds > 0 THEN 'WON'
	WHEN @modds = 0 THEN 'DRAW'
	WHEN @modds < 0 THEN 'LOSE'
	END,
StatusID = CASE
	WHEN @modds > 0 THEN 112 --WON
	WHEN @modds = 0 THEN 111 --DRAW
	WHEN @modds < 0 THEN 113 --LOSE
	END,
ruben=1
FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
    INNER JOIN #tmpRecommend ag ON b.recommend = ag.recommend
WHERE
	matchid=@matchid AND
	bettype=@bettype AND
	--status NOT IN (N'VOID', N'REJECT')
	statusID NOT IN (101,102)

DROP TABLE #tmpRecommend

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_8] TO [vnteam]

GO

 ALTER PROCEDURE [dbo].[Admin_Calculate_4]
	@matchid int,
	@bettype tinyint,
	@correctscore nvarchar(10),
	@goaldiff smallmoney,
	@FGLG2 nvarchar(10) = NULL
AS
/*
	Created by:[]
	Date:[]
	Task: Settlement 
	DB: DB052.BODB02
	
	Revisions:
		- 20090113: Include the Settle FGLG for bettransm
		- 20100517@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113) + Bettransm (WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
*/
SET NOCOUNT ON
---------------------------------------------------
IF @@SERVERNAME <> 'DB052'
    OR (@bettype = 4 and @matchid in (796071 --Argentina - Mexico
                    ,797608	--Netherlands - Slovakia
                    ,798155	--Brazil - Chile
                    ,797609 --Paraguay Japan
                    ,798156 --Spain Portugal
                    ,799855	--Brazil - Netherlands
                    ,798903	--Uruguay - Ghana
                    ,799441 --Argentina - Germany
                    ,800279	--Spain - Paraguay
                    ,801785	--Netherlands - Uruguay
                    ,802350	--Spain-Germany
                    ,803952	--Germany-Uruguay
                    ,803953	--Spain-Netherlands
                    ))
BEGIN
    RETURN
END
---------------------------------------------------
Declare @modds smallmoney

CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

IF @FGLG2 IS NULL OR @FGLG2 = ''
BEGIN
	select @FGLG2 = @correctscore
END

UPDATE b
SET @modds = modds = CASE
	WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1
	WHEN betteam = '5:0' AND @goaldiff >=  5 THEN 1
	WHEN betteam = '0:5' AND @goaldiff <= -5 THEN 1
	ELSE -1
	END,

WinLost = CASE
	WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end)
	WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * 0.5
	WHEN @modds =  0	THEN actual_stake
	WHEN @modds = -0.25	THEN actual_stake * 0.5
	WHEN @modds < -0.25	THEN 0
	END,

aWinLost = CASE
	WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -apositiontaking
	WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -apositiontaking * 0.5
	WHEN @modds =  0	THEN 0
	WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
	WHEN @modds < -0.25	THEN actual_stake * apositiontaking
	END,
mWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -mpositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -mpositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
	END,
sWinLost = CASE
	WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking
	WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,14,15,16) then odds-1 else odds end) end) * -spositiontaking * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
	WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
	END,

PlayerComm = CASE
	WHEN @modds >  0.25 	THEN playerdiscount * stake
	WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
	WHEN @modds < -0.25 	THEN playerdiscount * stake
	END,
Comm = CASE
	WHEN @modds >  0.25 	THEN discount * stake * (1-apositiontaking)
	WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
	WHEN @modds < -0.25 	THEN discount * stake * (1-apositiontaking)
	END,
aComm = CASE
	WHEN @modds >  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
	END,
sComm = CASE
	WHEN @modds >  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds =  0    	THEN 0
	WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
	WHEN @modds < -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
	END,

Status = CASE
	WHEN @modds > 0 THEN 'WON'
	WHEN @modds = 0 THEN 'DRAW'
	WHEN @modds < 0 THEN 'LOSE'
	END,
StatusID = CASE
	WHEN @modds > 0 THEN 112 --WON
	WHEN @modds = 0 THEN 111 --DRAW
	WHEN @modds < 0 THEN 113 --LOSE
	END,
ruben=1
FROM dbo.bettrans b WITH (ROWLOCK, UPDLOCK)
    INNER JOIN #tmpRecommend ag ON b.recommend = ag.recommend
WHERE
	matchid=@matchid AND
	bettype=@bettype AND
	--status NOT IN ('VOID', 'REJECT')
	statusID NOT IN (101,102)
	
DROP TABLE #tmpRecommend
	
	
-------------Start:Settle FGLG for bettransm-------------
if @bettype = 14
BEGIN
	declare @matchdate datetime
	select @matchdate=eventdate from match where matchid=@matchid

	UPDATE dbo.bettransm with (updlock)
	SET
		@modds =
			case 
				WHEN (betteam = @correctscore OR betteam = @FGLG2) THEN 1					
				ELSE -1
			END,
		ruben = CASE WHEN @modds IS NULL THEN 0 ELSE 1 END,
		winlostdate=@matchdate,
		[status]=
			case
				when @modds<0 then N'LOSE'
				when @modds>0 then N'WON'
			end ,
		statusID = 
			case
				when @modds<0 then 113 --LOSE
				when @modds>0 then 112 --WON
			end ,
		statuswinlost=
			case
				when @modds<=-0.5 then 4 -- LOSE
				when @modds>= 0.5 then 2 -- WIN
			end
	-- ========================
	FROM dbo.bettransm with (INDEX=IX_matchid)
	WHERE bettype = @bettype and matchid = @matchid
END 

-------------Stop:Settle FGLG for bettransm-------------


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_4] TO [VNTeam]