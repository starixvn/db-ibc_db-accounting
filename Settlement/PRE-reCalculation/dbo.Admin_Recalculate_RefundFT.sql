

ALTER PROCEDURE [dbo].[Admin_Recalculate_RefundFT] 
	@matchid int,
	@IsExcludeBetdaq bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund FT 
	DB: DBTRANS.BODB02
	
	Revisions:
		- 20100827@Jamie: Exclude 1st Money Line 
		-- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
		-- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
		-- 20110817@Lukas: Exclude refund FG/LG bettype
		- 20110912@Tom: Add new bettypes 30
				apply new bet type 1st correct score on Sport Books		
					
	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
SET NOCOUNT ON

IF @IsExcludeBetdaq = 0
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
			--AND  [status] not in (N'Void', N'Reject')
			AND statusID not in (103,101,102)
			AND bettype NOT IN (7, 8, 15, 12, 21, 30, 14) 			
		IF @@ROWCOUNT < 10000 BREAK	
	END
END
ELSE
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
			AND statusID not in (103,101,102)
			AND bettype NOT IN (7, 8, 15, 12, 21, 30, 14) 
			and custid not in (50057, 879241, 103873, 78761,1077687) 
			--AND custid not in (Select CustID from  [f_GetBetDaqCustomer] (1))
			AND recommend not in (1688156)
			--AND recommend not in (Select CustID from  [f_GetBetDaqCustomer] (2))			
		IF @@ROWCOUNT < 10000 BREAK
	END
END

