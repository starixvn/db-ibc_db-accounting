ALTER PROCEDURE [dbo].[Admin_Calculate_s161_Live]
	@matchid int,
	@DrawSeq tinyint,
	@Number tinyint
AS
/*
	Created by:[Joe]
	Date:[20100930]
	Task: Settlement 
	DB: DBO2.BODB02
	
	Revisions:R
		-20100930@Joe : add @DrawSeq to handle automatic live settle for each ball draw
		-20110721@Victor: 	Add New Bettype 88,89 Settlement Rule
		-20111014@Tim:	fix bettype 89 settlement because 89 is always decimal, so need to -1
		-20111107@Tim: Remove redundant @modds check
		-20120426@Lukas: Get from production & exclude DB044
		-20120626@Viet: add new bettype 90 (number group)
*/
SET NOCOUNT ON
	Declare @modds smallmoney

IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN
		
	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET @modds = modds = CASE
		WHEN bettype = 85 AND (betteam = N'h') AND (@Number >= 38)   THEN 1
		WHEN bettype = 85 AND (betteam = N'a') AND (@Number <= 37)   THEN 1
		WHEN bettype = 86 AND (betteam = N'h') AND (@Number %2 = 1)  THEN 1
		WHEN bettype = 86 AND (betteam = N'a') AND (@Number %2 = 0)  THEN 1
		WHEN bettype = 87 AND (betteam = N'h') AND (@Number > betid) THEN 1
		WHEN bettype = 87 AND (betteam = N'a') AND (@Number < betid) THEN 1
		WHEN bettype = 89 AND (betteam = N'1:1') AND (@Number >= 38) AND (@Number %2 = 1) THEN 1 -- OVER / ODD
		WHEN bettype = 89 AND (betteam = N'1:2') AND (@Number >= 38) AND (@Number %2 = 0) THEN 1 -- OVER / EVEN
		WHEN bettype = 89 AND (betteam = N'2:1') AND (@Number <= 37) AND (@Number %2 = 1) THEN 1 -- UNDER / ODD
		WHEN bettype = 89 AND (betteam = N'2:2') AND (@Number <= 37) AND (@Number %2 = 0) THEN 1 -- UNDER / EVEN
		WHEN bettype = 90 AND (HDP1 = 1) AND (CEILING(@Number/5.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 2) AND (CEILING(@Number/15.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 3) AND (CEILING(@Number/25.0) = betteam) THEN 1 
		WHEN bettype = 90 AND (HDP1 = 4) AND (@Number%5 = case betteam when 5 then 0 else betteam end) THEN 1 
		ELSE -1 -- lose
		END,

	WinLost = CASE
		WHEN @modds = 1		THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (89,90) then odds-1 else odds end) end)
		WHEN @modds = -1	THEN 0
		END,

	aWinLost = CASE
		WHEN @modds = 1		THEN stake * (case when odds<0 then 1 else (case when bettype in (89,90) then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds = -1	THEN actual_stake * apositiontaking
		END,
	mWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype in (89,90) then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds = -1 	THEN actual_stake * mpositiontaking
		END,
	sWinLost = CASE
		WHEN @modds = 1 	THEN stake * (case when odds<0 then 1 else (case when bettype in (89,90) then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds = -1 	THEN actual_stake * spositiontaking
		END,

	PlayerComm = CASE
		WHEN @modds = 1 	THEN playerdiscount * stake
		WHEN @modds = -1 	THEN playerdiscount * stake
		END,
	Comm = CASE
		WHEN @modds = 1  	THEN discount * stake * (1-apositiontaking)
		WHEN @modds = -1  	THEN discount * stake * (1-apositiontaking)
		END,
	aComm = CASE
		WHEN @modds = 1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		WHEN @modds = -1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
		END,
	sComm = CASE
		WHEN @modds = 1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		WHEN @modds = -1 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
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
		(livehomescore + liveawayscore + 
			CASE WHEN bettype = 87 THEN 2 ELSE 1 END) = @DrawSeq AND			
		bettrans.matchid=@matchid AND
		bettrans.bettype IN (85, 86, 87, 89, 90) AND
		bettrans.liveindicator = 1 AND
		--status NOT IN (N'VOID', N'REJECT')
		bettrans.statusID NOT IN (101,102)
GO
		
		
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_s161_Live] TO [VNTeam]
GO