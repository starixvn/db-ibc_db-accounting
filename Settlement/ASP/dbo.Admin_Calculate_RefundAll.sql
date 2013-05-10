ALTER PROCEDURE [dbo].[Admin_Calculate_RefundAll]
@matchid			int,
@IsExcludeBetdaq	bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund All
	DB: DBTRANS.BODB02	
	Revisions:
	-- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
	-- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
	-- 20110817@Lukas: Exclude refund FG/LG bettype
	-- 20121022@Elodie: Exclude sporting solution product
	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
SET NOCOUNT ON 

IF @IsExcludeBetdaq = 0
BEGIN
	WHILE 1=1
	BEGIN
	   UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	   set 
			[status]=N'Refund',
			statusID = 103,
			winlost=actual_stake,
			awinlost=0,
			mwinlost=0,
			swinlost=0,
			
			playercomm=0,
			comm=0,
			acomm=0,
			scomm=0,
			
			ruben=1,
			statuswinlost=0
		where
			matchid=@matchid
			--and [status] not in ('Void', 'Reject')
			AND statusID not in (103,101,102)
			AND bettype <> 14
			and bettype not between 1301 and 1334 -- exclude sporting solution product
		IF @@ROWCOUNT < 10000 BREAK
	END
END
ELSE
BEGIN
	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)	
		set 
			[status]=N'Refund',
			statusID = 103,
			winlost=actual_stake,
			awinlost=0,
			mwinlost=0,
			swinlost=0,
			
			playercomm=0,
			comm=0,
			acomm=0,
			scomm=0,
			
			ruben=1,
			statuswinlost=0
		where
			matchid=@matchid
			--and [status] not in ('Void', 'Reject')
			and statusID not in (103,101,102)	
			and custid not in (50057, 879241, 103873, 78761,1077687) 
			--and custid not in (Select CustID from  [f_GetBetDaqCustomer] (1))
			and recommend not in (1688156)
			--and recommend not in (Select CustID from  [f_GetBetDaqCustomer] (2))
			AND bettype <> 14
			and bettype not between 1301 and 1334 -- exclude sporting solution product
		 IF @@ROWCOUNT < 10000 BREAK
	END	
END

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundAll] TO [vnteam]