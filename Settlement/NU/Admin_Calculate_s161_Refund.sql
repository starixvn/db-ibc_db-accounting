ALTER PROCEDURE [dbo].[Admin_Calculate_s161_Refund]
	@matchid int,
	@action varchar(10) = 'Refund-FT' -- Refund / Refund-FT
AS
/*
	Created by:[Joe]
	Date:[20101103]
	Task: Settlement (Refund)
	DB: DBO2.BODB02
	
	Revisions:
		20101124@viet: add refund FT
		- 20120426@Lukas: Get from production & exclude DB044
*/
SET NOCOUNT ON

IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN

	IF @action = 'Refund-FT'
	BEGIN
		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET

		WinLost = actual_stake,

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

		WHERE
			matchid=@matchid AND
			statusID IN (0,1) -- only refund all running/waiting's tickets
	END
	ELSE
	BEGIN
		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET

		WinLost = actual_stake,

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

		WHERE
			matchid=@matchid AND
 			--status NOT IN (N'VOID', N'REJECT')
			statusID NOT IN (101,102)
	END