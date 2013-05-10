ALTER PROCEDURE [dbo].[Admin_Calculate_Refund]
@matchid			int,
@IsExcludeBetdaq	bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund All
	DB: DB02.BODB02	
	Revisions:
		- 20121022@Elodie: Exclude sporting solution product
*/
SET NOCOUNT ON 

IF @IsExcludeBetdaq = 0
BEGIN
	update bettrans
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
		AND statusID not in (101,102)
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END
ELSE
BEGIN
	update bettrans
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
		and statusID not in (101,102)	
		and custid not in (50057, 879241, 103873, 78761) 
		and recommend not in (1688156)
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
END

