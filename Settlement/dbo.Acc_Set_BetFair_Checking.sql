ALTER PROCEDURE [dbo].[Acc_Set_BetFair_Checking]
	@matchid				int = 0,
	@IsMovebetfair			bit = 0 output,
	@IsExcludeBetfair		bit = 0 output,
	@IsSettleAbandonedMatch bit = 0 output,
	@IsRefundRunningBetfair	bit = 0 output
AS 

/*
Created: 20140106@Elodie
Task : Checking exists betfair tickets or not [Redmine:#9764]
DB: DBTXN/bodb02
Original: Acc_Set_BetDaq_Checking

Revisions: 

Note: For settlement SPs should hardcode the custid of betfair customer to avoid replication problem
	* List of Betfair Customers 
			custid	--- username	-	roleid
			2331	---	BF		    -	1
			1077687	---	BFOS		-	1

Param's Explanation:
• @matchid: matchid of match to checking
• @IsMovebetfair:
	= 0 don't move betfair tickets to other match
	= 1 move betfair tickets to other match
• @IsExcludeBetfair:
	= 0 hide the checkbox exclude betfair
	= 1 show the checkbox exclude betfair
• @IsSettleAbandonedMatch:
	= 0 hide the checkbox "Settle determined tickets"
	= 1 show the checkbox "Settle determined tickets"
• @IsRefundRunningBetfair:
	= 0 hide the checkbox "Refund running BetFair"
	= 1 show the checkbox "Refund running BetFair"

*/
BEGIN
	SET NOCOUNT ON
	SELECT	@IsMovebetfair = 0, 
			@IsExcludeBetfair = 0, 
			@IsSettleAbandonedMatch =0 ,
			@IsRefundRunningBetfair =0 

	IF EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE custid IN (2331, 1077687) 
						AND matchid = @matchid 
						AND ruben = 0
			   )
	BEGIN
		SELECT	@IsMovebetfair = 1, @IsExcludeBetfair = 1, @IsRefundRunningBetfair = 1  	
	END


	IF EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE custid IN (2331, 1077687) 
						AND matchid = @matchid 
						AND bettype IN (3,8)  --Over/Under 
						AND statusID NOT IN (101, 102)
						AND ruben = 0 
			   )
	BEGIN
		SELECT	@IsSettleAbandonedMatch = 1 
		IF EXISTS (
					SELECT 1 
					FROM bettrans WITH (NOLOCK) 
					WHERE custid IN (2331, 1077687) 
							AND matchid = @matchid 
							AND bettype = 3  --Over/Under 
							AND statusID NOT IN (101, 102)
							AND ruben = 1 
				   )	
		BEGIN
			SELECT	@IsSettleAbandonedMatch = 0
		END

	END
	
END

GO
GRANT EXECUTE ON [dbo].[Acc_Set_BetFair_Checking] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_BetFair_Checking] TO [vnteam] AS [dbo]