CREATE PROCEDURE [NAP_Admin_Calculate_s162_Refund]
	@matchid int	
AS
/*
	Created by: Kathy
	Date: 20140224
	Task: Settlement (Refund)
	DB: DBO2.BODB02
	Original Admin_Calculate_s162_Refund
	Revisions:		
		
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
END


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_s162_Refund] TO [vnteam] AS [dbo]
GO


