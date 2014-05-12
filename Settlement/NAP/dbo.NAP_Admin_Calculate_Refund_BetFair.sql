ALTER PROCEDURE [NAP_Admin_Calculate_Refund_BetFair] 
	@matchid int
AS
/*	Created by: Kathy
	Date: 20140218
	Task: Refund Running BetFair
	DB: DBTXN/BODB02
	
	Revisions:
		- 20140512@Kathy: Exclude bettype 1H FGLG (127) [Redmine:#14718]
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
			AND bettype not IN (14, 127) --Exclude FGLG , 1H FGLG
			and bettype not between 1301 and 1334 -- exclude sporting solution product
			and custid IN (2331, 1077687, 115770) 
	
		IF @@ROWCOUNT < 10000 BREAK
	END
END


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_Refund_BetFair] TO [vnteam] AS [dbo]
GO


