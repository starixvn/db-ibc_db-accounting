ALTER PROCEDURE [dbo].[Admin_Calculate_RefundFT] 
	@matchid int,
	@IsExcludeBetdaq bit = 0,
	@IsExcludeBetfair	bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund FT 
	DB: DBTXN/BODB02
	
	Revisions:
		-- 20100827@Jamie: Exclude 1st Money Line 
		-- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
		-- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
		-- 20110817@Lukas: Exclude refund FG/LG bettype
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books		
		-- 20111202@Sophia: Add new bettype 124, 125 for 1x2 HDP				
		-- 20121022@Elodie: Exclude sporting solution product
		-- 20131227@Kathy: Add more Betdaq's customer: BDUS016, BDUS01 [Redmine:#9765]
		-- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)

	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
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
		AND statusID not in (103,101,102)
		AND bettype NOT IN (7, 8, 15, 12, 21, 30, 14, 125) 
		and bettype not between 1301 and 1334 -- exclude sporting solution product		
		AND 1 = CASE WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0 
						WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770) THEN 0
				ELSE 1 END
	IF @@ROWCOUNT < 10000 BREAK
END

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundFT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundFT] TO [vnteam] AS [dbo]