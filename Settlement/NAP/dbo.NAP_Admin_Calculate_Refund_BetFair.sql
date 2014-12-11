ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Refund_BetFair] 
	@matchid int
AS
/*	Created by: Kathy
	Date: 20140218
	Task: Refund Running BetFair
	DB: DBTXN/BODB02
	
	Revisions:
		- 20140512@Kathy: Exclude bettype 1H FGLG (127) [Redmine:#14718]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]		
		- 20140909@Kathy: Exclude virtual racing (bettype 1237, 1238), outright (bettype 10, 31, 32, 33), keno (1501 -> 1599)
		- 20141030@Jamie: Sportting Solution Tennis Settlement [Redmine:#23034]
		
*/
SET NOCOUNT ON

BEGIN
	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET
			[status] = N'Refund',
			statusID = 103,
			ruben = 1,
			winlost=actual_stake,
			awinlost=0,
			mwinlost=0,
			swinlost=0,
			playercomm=0,
			comm=0,
			acomm=0,
			scomm=0
		where
			matchid=@matchid
			--AND [status] not in (N'Void', N'Reject')
			AND statusID NOT IN (103,101,102)
			AND ruben = 0 
			AND bettype NOT IN (14, 127) --Exclude FGLG 
			AND bettype NOT BETWEEN 1301 AND 1399 -- exclude sporting solution product
			AND bettype NOT BETWEEN 153 AND 156   -- New bettype of Tennis
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			and custid IN (2331, 1077687, 115770, 15523642) 
	
		IF @@ROWCOUNT < 10000 BREAK
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Refund_BetFair] TO [vnteam] AS [dbo]