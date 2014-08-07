/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_Refund_BetFair]    Script Date: 08/07/2014 14:07:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
			and bettype not between 1301 and 1334 -- exclude sporting solution product
			and custid IN (2331, 1077687, 115770, 15523642) 
	
		IF @@ROWCOUNT < 10000 BREAK
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Refund_BetFair] TO [vnteam] AS [dbo]