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
    OR @matchid in (796071 --Argentina vs. Mexico
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
