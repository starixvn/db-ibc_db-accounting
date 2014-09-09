/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_s162_Refund]    Script Date: 09/09/2014 14:58:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_s162_Refund]
	@matchid int	
AS
/*
	Created by: Kathy
	Date: 20140224
	Task: Settlement (Refund)
	DB: DBO2.BODB02
	Original Admin_Calculate_s162_Refund
	Revisions:		
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33), sportting solution (from 1301 -> 1334)
*/
SET NOCOUNT ON

IF @@SERVERNAME not in ('DB042', 'DB043', 'DB044')
BEGIN
	UPDATE dbo.bettransG WITH(ROWLOCK, UPDLOCK)
	SET  
		WinLost = stake ,
		statuswinlost=0,
		aWinLost = 0,
		mWinLost = 0,
		sWinLost = 0,
		PlayerComm = 0,
		Comm = 0,
		aComm = 0,
		sComm = 0,
		[Status] = N'Refund',
		StatusID = 103,
		ruben=1
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102) -- void, reject
END

IF @@SERVERNAME not in ('DB042', 'DB043', 'DB044')
BEGIN
	UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
	SET  
		WinLost = actual_stake,
		statuswinlost=0,
		aWinLost = 0,
		mWinLost = 0,
		sWinLost = 0,
		PlayerComm = 0,
		Comm = 0,
		aComm = 0,
		sComm = 0,
		[Status] = N'Refund',
		StatusID = 103,
		ruben=1
	WHERE matchid=@matchid
		and statusID NOT IN (101,102)
		AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
		AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
END


GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_s162_Refund] TO [vnteam] AS [dbo]