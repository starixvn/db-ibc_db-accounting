ALTER PROCEDURE [dbo].[Admin_Calculate_SS]
	@matchid int,
	@bettype int,
	@oddsid	int,
	@betteam Varchar(10)
AS
/*
	Created by:[Victor]
	Date:[20120920]
	Task: Settlement 
	DB: DBTrans.BODB02
	Revisions:
		- 20121018@Elodie: Remove Write Log
*/
SET NOCOUNT ON
	Declare @modds smallmoney	
			
IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE @betteam
		WHEN betteam THEN 1 -- win
		ELSE -1 -- lose
		END,

	WinLost = CASE
		WHEN @modds = 1  	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype >= 1300 then odds-1 else odds end) end)
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -1	THEN 0
		END,

	aWinLost = CASE
		WHEN @modds = 1		THEN stake * (case when odds<0 then 1 else (case when bettype >= 1300 then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0	THEN 0
		WHEN @modds = -1	THEN actual_stake * apositiontaking
		END,
	mWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype >= 1300 then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1 	THEN actual_stake * mpositiontaking
		END,
	sWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype >= 1300 then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1 	THEN actual_stake * spositiontaking
		END,

	PlayerComm = CASE
		WHEN @modds = 1 	THEN playerdiscount * stake
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1 	THEN playerdiscount * stake
		END,
	Comm = CASE
		WHEN @modds = 1 	THEN discount * stake * (1-apositiontaking)
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1 	THEN discount * stake * (1-apositiontaking)
		END,
	aComm = CASE
		WHEN @modds = 1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		END,
	sComm = CASE
		WHEN @modds = 1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		WHEN @modds =  0    THEN 0
		WHEN @modds = -1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		END,

	Status = CASE
		WHEN @modds = 1		THEN N'WON'
		WHEN @modds = 0		THEN N'DRAW'
		WHEN @modds = -1	THEN N'LOSE'
		END,
	StatusID = CASE
		WHEN @modds = 1		THEN 112 --WON
		WHEN @modds = 0		THEN 111 --DRAW
		WHEN @modds = -1	THEN 113 --LOSE
		END,
	ruben=1

	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		Oddsid=@Oddsid AND
		statusID NOT IN (101,102)	
GO


