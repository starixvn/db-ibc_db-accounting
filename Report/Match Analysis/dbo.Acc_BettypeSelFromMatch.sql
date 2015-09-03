ALTER PROCEDURE dbo.[Acc_BettypeSelFromMatch]
	@eventdate datetime,
	@matchid int,	
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME	
AS

/*
	Created: Dan
	Date: 2012/04/05
	Task: Get list of bettype for a match from bettrans for SpecialMatch report
	DB: DBACC/BODB02

	Revisions:
		- 20120920@Sophia: Support only Sportsbook
		- 20121123@Elodie: Add 34 new bettypes of Tennis (1301 -> 1334)
		- 20120215@Elodie: Change linked server DB06 to DBARC
		- 20150529@Jim: add Metric Gaming and apply sport-bettype matrix
		- 20150728@Jim: apply Bettrade (Feature #38815)
	Parameters Explanations:			
*/
DECLARE @SportBettype TABLE(ProductID INT,Bettype INT,EventType INT,SubProduct VARCHAR(200))
INSERT INTO @SportBettype
EXEC dbo.Acc_SportBettypeMatrix_Sel @mode=5

DELETE 	@SportBettype WHERE bettype IN (901,902,903)

IF (@eventdate>@MoveBetsDay)
BEGIN
	-- get from bettrans
	SELECT distinct bettype
	FROM dbo.bettrans b WITH (NOLOCK) 
 	WHERE 	
			matchid = @matchid
			--support only sportsbook 
			AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334)
			AND	b.bettype NOT IN (9,29,10) 			
			--AND status NOT IN ('VOID', 'REJECT','REFUND') 	
			AND b.statusID IN (111,112,113)
			AND ruben = 1
			AND Currency <> 20		
END
ELSE IF (@eventdate>=@BalanceUpDay)
BEGIN
	-- get from bettrans14	
	SELECT distinct bettype
	FROM dbo.bettrans14 b WITH (NOLOCK) 
 	WHERE 	
			matchid = @matchid
			--support only sportsbook 
			AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334)
			AND	b.bettype NOT IN (9,29,10) 			
			--AND status NOT IN ('VOID', 'REJECT','REFUND') 	
			AND b.statusID IN (111,112,113)
			AND ruben = 1
			AND Currency <> 20		
	
END
ELSE 
BEGIN
	-- get from bettrans_BK 
	SELECT distinct bettype
	FROM DBARC.bodb_archive.dbo.bettrans_bk b WITH (NOLOCK) 
 	WHERE 	winlostdate = @eventdate
			AND matchid = @matchid
			--support only sportsbook 
			AND (b.bettype < 31 OR b.Bettype BETWEEN 121 AND 999 or b.bettype BETWEEN 1301 and 1334) 
			AND	b.bettype NOT IN (9,29,10) 						
			AND status IN ('DRAW', 'WON','LOSE') 
			--AND b.statusID IN (111,112,113)			
			AND ruben = 1	
			AND Currency <> 20
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettypeSelFromMatch] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettypeSelFromMatch] TO [vnteam]