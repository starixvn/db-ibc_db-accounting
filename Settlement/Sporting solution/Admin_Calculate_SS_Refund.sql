ALTER PROCEDURE [dbo].[Admin_Calculate_SS_Refund]
	@matchid int,
	@oddsid	int,
	@action	varchar(10) = 'Refund' -- Refund / RefundBO  (Refund By Oddsid)		
AS
BEGIN
/*
	Created by: Victor
	Date:[20120928]
	Task: Settlement (Refund)
	DB: DBTrans.BODB02
	
	@action:
		Refund: Refund By matchid
		RefundBO: Refund By Oddsid
	*/
	SET NOCOUNT ON


	IF @@SERVERNAME not in ('DB04', 'DB042', 'DB043', 'DB044')
	BEGIN
		IF @action = 'Refund'
		BEGIN
				UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
				SET  
					WinLost = actual_stake,
					statuswinlost = 0,
					aWinLost = 0,
					mWinLost = 0,
					sWinLost = 0,
					PlayerComm = 0,
					Comm = 0,
					aComm = 0,
					sComm = 0,
					[Status] = N'Refund',
					StatusID = 103,
					ruben = 1
				WHERE matchid = @matchid
					and statusID NOT IN (101,102)
					and bettype > 1300
		END
		IF @action = 'RefundBO'
		BEGIN
				UPDATE dbo.bettrans WITH (ROWLOCK, UPDLOCK)
				SET  
					WinLost = actual_stake,
					statuswinlost = 0,
					aWinLost = 0,
					mWinLost = 0,
					sWinLost = 0,
					PlayerComm = 0,
					Comm = 0,
					aComm = 0,
					sComm = 0,
					[Status] = N'Refund',
					StatusID = 103,
					ruben = 1
				WHERE matchid = @matchid
					and statusID NOT IN (101,102)
					and Oddsid = @Oddsid
		END	
	END
END