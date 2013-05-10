ALTER PROCEDURE [dbo].[Admin_Calculate_1_WC]
	@matchid int,
	@bettype tinyint,
	@fth smallmoney,
	@fta smallmoney,
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
	
	Set @affectedagents = @@rowcount
	
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
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_1_WC] TO [vnteam]

GO
ALTER PROCEDURE [dbo].[Admin_Calculate_3_WC]
	@matchid int,
	@bettype tinyint,
	@totalgoal smallmoney
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

Declare @modds smallmoney, @affectedagents int

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
		INNER JOIN @currecommend ag on b.recommend = ag.recommend
	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--status NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)

	if @affectedagents <> 100 
		break
END
DROP TABLE #tmpRecommend

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_3_WC] TO [vnteam]

GO
ALTER PROCEDURE [dbo].[Admin_Calculate_4_WC]
	@matchid int,
	@bettype tinyint,
	@correctscore nvarchar(10),
	@goaldiff smallmoney,
	@FGLG2 nvarchar(10) = NULL
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

Declare @modds smallmoney, @affectedagents int

CREATE TABLE #tmpRecommend(recommend INT  PRIMARY KEY)
INSERT INTO #tmpRecommend(recommend)
SELECT DISTINCT recommend
FROM dbo.bettrans (nolock) WHERE matchid = @matchid and bettype = @bettype

IF @FGLG2 IS NULL OR @FGLG2 = ''
BEGIN
	select @FGLG2 = @correctscore
END

DECLARE @currecommend TABLE(recommend int PRIMARY KEY)

WHILE 1=1
BEGIN
	delete @currecommend
	delete top(100) from #tmpRecommend output DELETED.recommend into @currecommend
	set @affectedagents = @@rowcount

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
		INNER JOIN @currecommend ag on b.recommend = ag.recommend
	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--status NOT IN ('VOID', 'REJECT')
		statusID NOT IN (101,102)

	if @affectedagents <> 100 
		break
END
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
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_4_WC] TO [VNTeam]

GO
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

GO

ALTER PROCEDURE [dbo].[Admin_Calculate_8_WC]
	@matchid int,
	@bettype tinyint,
	@totalht smallmoney
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

Declare @modds smallmoney, @affectedagents int

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
		INNER JOIN @currecommend ag on b.recommend = ag.recommend
	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--status NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)

	if @affectedagents <> 100 
		break
END
DROP TABLE #tmpRecommend

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_8_WC] TO [vnteam]



