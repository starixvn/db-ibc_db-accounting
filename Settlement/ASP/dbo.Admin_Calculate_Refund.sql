ALTER PROCEDURE [dbo].[Admin_Calculate_Refund]
	@matchid			int,
	@IsExcludeBetdaq	bit = 0,
	@IsExcludeBetfair	bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund All
	DB: DBTXN/BODB02	
	Revisions:
		- 20121022@Elodie: Exclude sporting solution product
		- 20131227@Kathy: Add more Betdaq's customer: BDUS016, BDUS01 [Redmine:#9765]
		- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)
*/
SET NOCOUNT ON 
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
		and statusID not in (101,102)	
		AND 1 = CASE WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0 
						WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687) THEN 0
				ELSE 1 END
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
END