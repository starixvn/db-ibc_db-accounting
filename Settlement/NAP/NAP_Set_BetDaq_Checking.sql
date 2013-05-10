ALTER PROCEDURE [dbo].[NAP_Set_BetDaq_Checking]
	@matchid				int = 0
AS 

/*
Created: 20120924@dAN
Task : Checking exists betdatd tickets or not
DB: DBTRANS.bodb02
Original: [Acc_Set_BetDaq_Checking]

Revisions: 


Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
	* List of BetDaq Customers 
			custid	--- username	-	roleid
			1077687	---	BFOS		-	1
			50057	---	BQUS888		-	1
			879241	---	BQUSMLB		-	1
			103873	---	BQUSNBA		-	1
			78761	---	ITibc101	-	1
			1688156	---	MTEST0101	-	2

Param's Explanation:
• @matchid: matchid of match to checking
• @IsMovebetdaq:
	= 0 don't move betdaq tickets to other match
	= 1 move betdaq tickets to other match
• @IsExcludeBetdaq:
	= 0 hide the checkbox exclude betdaq
	= 1 show the checkbox exclude betdaq
• @IsSettleAbandonedMatch:
	= 0 hide the checkbox "Settle determined tickets"
	= 1 show the checkbox "Settle determined tickets"

• @IsRefundRunningBetDaq:
	= 0 hide the checkbox "Refund running BetDaq"
	= 1 show the checkbox "Refund running BetDaq"

*/
BEGIN
	SET NOCOUNT ON
	DECLARE 
		@IsMovebetdaq			bit ,
		@IsExcludeBetdaq		bit,
		@IsSettleAbandonedMatch bit,
		@IsRefundRunningBetDaq	bit
		
	SELECT	@IsMovebetdaq = 0, 
			@IsExcludeBetdaq = 0, 
			@IsSettleAbandonedMatch =0 ,
			@IsRefundRunningBetDaq =0 

	IF EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
						(	custid IN (50057, 879241, 103873, 78761, 1077687) 
								OR recommend = 1688156	)
						AND matchid = @matchid 
						AND ruben = 0
			   )
	BEGIN
		SELECT	@isMoveBetDaq = 1, @isExcludeBetDaq = 1, @IsRefundRunningBetDaq = 1  	
	END


	IF EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
						(	custid IN (50057, 879241, 103873, 78761, 1077687) 
							OR recommend = 1688156	)
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
					WHERE 
							(	custid IN (50057, 879241, 103873, 78761, 1077687) 
								OR recommend = 1688156	)
							AND matchid = @matchid 
							AND bettype = 3  --Over/Under 
							AND statusID NOT IN (101, 102)
							AND ruben = 1 
				   )	
		BEGIN
			SELECT	@IsSettleAbandonedMatch = 0
		END

	END
	SELECT @IsMovebetdaq IsMovebetdaq,
		@IsExcludeBetdaq IsExcludeBetdaq,
		@IsSettleAbandonedMatch IsSettleAbandonedMatch,
		@IsRefundRunningBetDaq	IsRefundRunningBetDaq
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_Set_BetDaq_Checking] TO [bodbadminnet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_BetDaq_Checking] TO [vnteam]
GO