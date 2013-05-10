ALTER PROCEDURE [dbo].[Admin_Calculate_s161_Pregame]
	@matchid int,
	@bettype smallint,
	@betteam nvarchar(1),
	@firstball_NO int = 0
AS
/*
	Created by:[Joe]
	Date:[20100930]
	Task: Settlement 
	DB: DBO2.BODB02
	
	Revisions:
		- 20110105@Lukas: Re-arrange bettype
		- 20111014@Tim:	fix bettype 89 settlement because 89 is always decimal, so need to -1
		- 20111107@Tim: Remove redundant @modds check
		- 20120426@Lukas: Get from production & exclude DB044
		- 20120530@Jamie: Add Log to trace bug 
		- 20120626@Viet: add new bettype 90 (number group)
		- 20120702@Dan: add new bettype 90 (number group) - update
*/
SET NOCOUNT ON
	Declare @modds smallmoney
	DECLARE	@LogData VARCHAR(1000)
			

IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE
		WHEN bettype = 90 AND (HDP1 = 1) AND (CEILING(@firstball_NO/5.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 2) AND (CEILING(@firstball_NO/15.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 3) AND (CEILING(@firstball_NO/25.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 4) AND (@firstball_NO%5 = case betteam when 5 then 0 else betteam end) THEN 1 
		WHEN bettype in (81,82,83,84,85,86,88) AND @betteam = 'x' THEN 0 --draw
		WHEN bettype in (81,82,83,84,85,86,88) AND @betteam = betteam THEN 1
		ELSE -1 -- lose
		END,	
	WinLost = CASE
		WHEN @modds = 1  	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype = 90 then odds-1 else odds end) end)
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -1	THEN 0
		END,

	aWinLost = CASE
		WHEN @modds = 1	THEN stake * (case when odds<0 then 1 else (case when bettype = 90 then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0	THEN 0
		WHEN @modds = -1	THEN actual_stake * apositiontaking
		END,
	mWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype = 90 then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1 	THEN actual_stake * mpositiontaking
		END,
	sWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype = 90 then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1 	THEN actual_stake * spositiontaking
		END,

	PlayerComm = CASE
		WHEN @modds = 1 	THEN playerdiscount * stake
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1 	THEN playerdiscount * stake
		END,
	Comm = CASE
		WHEN @modds = 1 	THEN discount * stake * (1-apositiontaking)
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1 	THEN discount * stake * (1-apositiontaking)
		END,
	aComm = CASE
		WHEN @modds = 1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		END,
	sComm = CASE
		WHEN @modds = 1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		END,

	Status = CASE
		WHEN @modds = 1 THEN N'WON'
		WHEN @modds = 0 THEN N'DRAW'
		WHEN @modds = -1 THEN N'LOSE'
		END,
	StatusID = CASE
		WHEN @modds = 1 THEN 112 --WON
		WHEN @modds = 0 THEN 111 --DRAW
		WHEN @modds = -1 THEN 113 --LOSE
		END,
	ruben=1

	WHERE
		matchid=@matchid AND
		bettype=@bettype AND
		liveindicator = 0 AND
		--status NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)
		
	-- LOG
	SELECT @LogData = 'Admin_Calculate_s161_Pregame MatchID:' + CONVERT(VARCHAR(20),@MatchID) + ' Bettype:' + CONVERT(VARCHAR(20),@Bettype) +' Betteam:' +@betteam
	EXEC dbo.WriteLog_UserLog 161, @LogData		
	
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_s161_Pregame] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_s161_Pregame] TO [vnteam]