 
ALTER PROCEDURE [dbo].[Admin_Recalculate_28]
	@matchid int,
	@bettype smallint,
	@fth smallmoney,
	@fta smallmoney
AS
/*
	Created by: 20111116
	Task: Settlement 
	DB: DB052.BODB_REVIEW
	
	Revisions:
		- 20111021@Joe: Apply rounding winlost amount to 2 decimal places
*/
BEGIN


	SET NOCOUNT ON
	Declare @modds smallmoney

	UPDATE bettrans with (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE
		WHEN betteam = '1' AND ( hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
		WHEN betteam = '2' AND ( hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
		WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
		ELSE -1
		END,

	WinLost = ROUND(CASE
		WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end)
		WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * 0.5
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -0.25	THEN actual_stake * 0.5
		WHEN @modds < -0.25	THEN 0
		END, 2),

	aWinLost = ROUND(CASE
		WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -apositiontaking * 0.5
		WHEN @modds =  0	THEN 0
		WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		WHEN @modds < -0.25	THEN actual_stake * apositiontaking
		END, 2),
	mWinLost = ROUND(CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -mpositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
		END, 2),
	sWinLost = ROUND(CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6,13,15,16,24,25,26,27,28) then odds-1 else odds end) end) * -spositiontaking * 0.5
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

	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		--status NOT IN ('VOID', 'REJECT')
		statusID NOT IN (101,102)

END


