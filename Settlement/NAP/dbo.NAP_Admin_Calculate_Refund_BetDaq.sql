/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_Refund_BetDaq]    Script Date: 09/10/2014 09:52:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Admin_Calculate_Refund_BetDaq    Script Date: 31/07/2014 12:58:51 PM ******/

ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Refund_BetDaq] 
	@matchid int
AS
/*	Created by: Kathy
	Date: 20140218
	Task: Refund Running BetDaq
	DB: DBTXN/BODB02
	
	Revisions:
		- 20140512@Kathy: Exclude bettype 1H FGLG (127) [Redmine:#14718]
		- 20140909@Kathy: Exclude virtual racing (bettype 1237, 1238), outright (bettype 10, 31, 32, 33), keno (1501 -> 1599)
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
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			and( custid IN (50057, 879241, 103873, 78761, 851668, 878902) 
				OR  recommend IN (1688156)
			)
	
		IF @@ROWCOUNT < 10000 BREAK
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Refund_BetDaq] TO [vnteam] AS [dbo]