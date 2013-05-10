


ALTER PROCEDURE [dbo].[Admin_Recalculate_7] 
	@matchid int,
	@bettype smallint,
	@hth smallmoney,
	@hta smallmoney,
	@betcount int = 0
	-- add any params, please modify script in 'special section'
AS
/*
	Created by:20111116@Lukas
	Task: Settlement 
	DB: DB052.BODB_REVIEW
	
	Revisions:
		- 20090423@PhuongDao: Change DB04 to DB042
		- 20091126@Daniel: Check syncronize of remote replication 
		- 20100424@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
		- 20100826@Jamie: Combine code between DB052 and others 
		- 20110105@Lukas: Re-arrange bettype
		- 20110112@Lukas: Separate settlement for DB052
							- Save the settlement execution
							- use job to run settlement later
		- 20110909@Lukas: Separate settlement for DB053 (settlement process like at DB052)
		- 20111021@Joe: Apply rounding winlost amount to 2 decimal places
*/
BEGIN

	SET NOCOUNT ON
	Declare @modds smallmoney, @RemoteCount int


	
	/* -- Joe : remove check
	IF @@SERVERNAME in ('DBTW','DBBAK') AND @bettype = 7 and @betcount > 0
	BEGIN
	CountBet:
		SELECT @RemoteCount = COUNT(1) FROM bettrans WITH(NOLOCK) WHERE bettype = 7 AND matchid = @matchid
		IF @betcount > @RemoteCount
		BEGIN
			WAITFOR DELAY '00:01:00'
			GOTO CountBet
		END
	END
	*/
	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE betteam
		WHEN 'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
		WHEN 'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
		END,

	WinLost = ROUND(CASE
		WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
		WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -0.25	THEN actual_stake * 0.5
		WHEN @modds < -0.25	THEN 0
		END, 2),

	aWinLost = ROUND(CASE
		WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
		WHEN @modds =  0	THEN 0
		WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		WHEN @modds < -0.25	THEN actual_stake * apositiontaking
		END, 2),
	mWinLost = ROUND(CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
		END, 2),
	sWinLost = ROUND(CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
		END, 2),

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

	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--[status] NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)

END



