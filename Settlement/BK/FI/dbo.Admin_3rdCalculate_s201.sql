ALTER PROCEDURE [dbo].[Admin_3rdCalculate_s201]
	@positionID bigint, -- transid
	@tickValue money, -- Market Outcome
	@timestamp bigint, -- their system TimeStamp
	@payout smallint, -- Outcome of ticket
	@checktime datetime = null --3rd party settle time
AS
/*
Created by:[]
Date:
Task: 
DB: DBTRANS.BODB02	
	Revisions:
		-- 20100517@Henry: Update column StatusID of Bettrans
		-- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		-- 20101007@Henry: Change column transid from INT to BIGINT
		-- 20110106@Lukas: Re-arrange bettype
*/
	DECLARE @modds smallmoney
	DECLARE @result int, @status nvarchar(10), @bettype smallint, @ruben tinyint

	IF @checktime IS NULL SET @checktime=getdate()

	UPDATE dbo.bettrans with (UPDLOCK, ROWLOCK)
	SET
		/* --3rdparty give outcome mapping
		@payout = 1 -> @modds =  1 : WON
		@payout = 2 -> @modds = -1 : LOSE
		@payout = 3 -> @modds = 0 : DRAW
		*/
		hdp2 = @tickValue,
		checktime = @checktime,
		@modds = modds = CASE @payout 
			WHEN 1 THEN 1.0 --won
			WHEN 3 THEN 0 --draw
			ELSE -1.0 END, --other case lose
	
	WinLost = CASE
		WHEN @modds >  0.25	THEN actual_stake + stake * (odds-1)
		WHEN @modds =  0.25	THEN actual_stake + stake * (odds-1) * 0.5
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -0.25	THEN actual_stake * 0.5
		WHEN @modds < -0.25	THEN 0
		END,

	aWinLost = CASE
		WHEN @modds >  0.25	THEN stake * (odds-1) * -apositiontaking
		WHEN @modds =  0.25	THEN stake * (odds-1) * -apositiontaking * 0.5
		WHEN @modds =  0	THEN 0
		WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		WHEN @modds < -0.25	THEN actual_stake * apositiontaking
		END,
	mWinLost = CASE
		WHEN @modds >  0.25 	THEN stake * (odds-1) * -mpositiontaking
		WHEN @modds =  0.25 	THEN stake * (odds-1) * -mpositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
		END,
	sWinLost = CASE
		WHEN @modds >  0.25 	THEN stake * (odds-1) * -spositiontaking
		WHEN @modds =  0.25 	THEN stake * (odds-1) * -spositiontaking * 0.5
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
		WHEN @modds = 1.0 THEN N'WON'
		WHEN @modds = 0 THEN N'DRAW'
		WHEN @modds = -1.0 THEN N'LOSE'
		END,
	statusID = CASE
		WHEN @modds > 0 THEN 112
		WHEN @modds = 0 THEN 111
		WHEN @modds < 0 THEN 113
		END,

	ruben=1 --has been Settle
	WHERE
		transid = @positionID and bettype between 51 and 66 
		and 
		--[status] = N'running'
		statusID = 0

	SET @result = @@ROWCOUNT
	IF @result = 0
	BEGIN
		SELECT @status = [status], @bettype = bettype, @ruben = ruben
		FROM dbo.bettrans with (nolock)
		WHERE transid = @positionID
		
		IF @@ROWCOUNT = 0 SET @result=-1	-- transid not found
		ELSE IF @bettype not between 51 and 66 SET @result=-2	-- not finance bettype
		ELSE IF @ruben = 1 SET @result=-4 -- the transid has been Settle
		ELSE IF @status <> N'running' SET @result=-3 -- not running bet
	END

	SELECT @result


GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdCalculate_s201] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Admin_3rdCalculate_s201] TO [Dot_Member]
GO
