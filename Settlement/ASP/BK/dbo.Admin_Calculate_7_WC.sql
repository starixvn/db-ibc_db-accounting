ALTER PROCEDURE [dbo].[Admin_Calculate_7_WC]
	@matchid int,
	@bettype tinyint,
	@hth smallmoney,
	@hta smallmoney,
	@betcount int = 0
WITH RECOMPILE
AS
/*
	Created by: Thien
	Date:2010-06-28
	Task: manual calculation for main WC matches 
	DB: DB052.BODB02
	
	Revisions:
		- 20100628@Phuc: put with recompile/update by batch per 100 agents.
*/
SET NOCOUNT ON

Declare @modds smallmoney, @RemoteCount int, @affectedagents int
	
CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

DECLARE @currecommend TABLE(recommend int PRIMARY KEY)

WHILE 1=1
BEGIN
	delete @currecommend
	delete top(100) from #tmpRecommend output DELETED.recommend into @currecommend
	set @affectedagents = @@rowcount
	
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
		INNER JOIN @currecommend ag on b.recommend = ag.recommend
	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--[status] NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)

	if @affectedagents <> 100 
		break
END
DROP TABLE #tmpRecommend


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_7_WC] TO [vnteam]