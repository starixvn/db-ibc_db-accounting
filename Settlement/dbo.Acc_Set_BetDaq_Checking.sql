ALTER PROC [Acc_Set_BetDaq_Checking]
	@matchid				int = 0,
	@IsMovebetdaq			bit = 0 output,
	@IsExcludeBetdaq		bit =0 output,
	@IsSettleAbandonedMatch bit = 0 output,
	@IsRefundRunningBetDaq	bit = 0 output
AS 

/*
Created: 20090911@KhoaTran
Task : Checking exists betdatd tickets or not
DB: DBTXN/bodb02
Original: 

Revisions: 
	- Khoa@20100303: - Always show option ExcludeBetDaq if betdaq tickets have status ruben = 0
	- Henry@20101001: Using f_GetBetDaqCustomer to query betdaq customer
	- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
	- 20120215@Jamie: Add param @IsSettleAbandonedMatch to indicate "Settle determined tickets" shown or not
	- 20120313@Jamie: Show checkbox when not existing Full time Over/Under BETDAQ settled 
	- 20131227@Kathy: Add more Betdaq's customer: BDUS016, BDUS01 
	- 20140106@Elodie: Modify the custid of betdaq customer list [Redmine:#9764]
	- 20140313@Kathy: Execute settlement for abandoned/postponed matches (bettype: 13,26,27) [Redmine:#12049]

Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
	* List of BetDaq Customers 
			custid	--- username	-	roleid
			50057	---	BQUS888		-	1
			879241	---	BQUSMLB		-	1
			103873	---	BQUSNBA		-	1
			78761	---	ITibc101	-	1
			1688156	---	MTEST0101	-	2
			851668  --- BDUS01      -   1
			878902  --- BDUS016     -   1

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
	SELECT	@IsMovebetdaq = 0, 
			@IsExcludeBetdaq = 0, 
			@IsSettleAbandonedMatch =0 ,
			@IsRefundRunningBetDaq =0 

	IF EXISTS (
				SELECT 1 
				FROM bettrans WITH (NOLOCK) 
				WHERE 
						(	custid IN (50057, 879241, 103873, 78761, 851668, 878902) 
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
						(	custid IN (50057, 879241, 103873, 78761, 851668, 878902)
							OR recommend = 1688156	)
						AND matchid = @matchid 
						AND bettype IN (3,8,13,26,27)  --Over/Under, Clean Sheet, Both/One/Neither team to score, To Win To Nil 
						AND statusID NOT IN (101, 102)
						AND ruben = 0 
			   )
	BEGIN
		SELECT	@IsSettleAbandonedMatch = 1 
		IF EXISTS (
					SELECT 1 
					FROM bettrans WITH (NOLOCK) 
					WHERE 
							(	custid IN (50057, 879241, 103873, 78761, 851668, 878902)
								OR recommend = 1688156	)
							AND matchid = @matchid 
							AND bettype in(3,13,26,27)  --Over/Under, Clean Sheet, Both/One/Neither team to score, To Win To Nil
							AND statusID NOT IN (101, 102)
							AND ruben = 1 
				   )	
		BEGIN
			SELECT	@IsSettleAbandonedMatch = 0
		END

	END
	
END



GO
GRANT EXECUTE ON [dbo].[Acc_Set_BetDaq_Checking] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_BetDaq_Checking] TO [vnteam] AS [dbo]