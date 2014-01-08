ALTER PROCEDURE [dbo].[Admin_Calculate_RefundHT]
	@matchid int,
	@IsExcludeBetdaq bit = 0,
	@IsExcludeBetfair	bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund HT 
	DB: DBTXN/BODB02
	Revisions:
		- 20100818@Henry:  Allow to refund 1st Half Money Line
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books	
		- 20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP		
		- 20120216@Jamie: Add one more param @IsExcludeBetdaq to indicate Refund Excluding BetDaq or not 
		- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)

	Param's Explanation:
		+ @IsExcludeBetdaq: 
			= 1 : Refund Excluding BetDaq
			= 0 : Refund HT including BetDaq 
		+ @IsExcludeBetfair: 
			= 1 : Refund Excluding Betfair
			= 0 : Refund HT including Betfair
				
*/
SET NOCOUNT ON

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
		AND statusID not in (103,101,102)
		AND bettype IN (7, 8, 15, 12,21,30, 125) 
		AND 1 = CASE WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0 
						WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687) THEN 0
				ELSE 1 END
			
	IF @@ROWCOUNT < 10000 BREAK
END

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundHT] TO [vnteam] AS [dbo]