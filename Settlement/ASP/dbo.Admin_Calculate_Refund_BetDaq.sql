ALTER PROCEDURE [dbo].[Admin_Calculate_Refund_BetDaq] 
	@matchid int
AS
/*	Created by: Jamie
	Date: 2012-02-16
	Task: Refund Running BetDaq
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20121022@Elodie: Exclude sporting solution product
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
			AND bettype <> 14 --Exclude FGLG 
			and bettype not between 1301 and 1334 -- exclude sporting solution product
			and( custid IN (50057, 879241, 103873, 78761,1077687) 
				OR  recommend IN (1688156)
			)
	
		IF @@ROWCOUNT < 10000 BREAK
	END
END

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_Refund_BetDaq] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_Refund_BetDaq] TO [vnteam]