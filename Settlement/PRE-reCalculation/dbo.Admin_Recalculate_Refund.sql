 
ALTER PROCEDURE [dbo].[Admin_Recalculate_Refund]
@matchid			int,
@IsExcludeBetdaq	bit = 0
AS
/*	Created by: 20111116@Lukas
	Task: Refund All
	DB: DB052.BODB_REVIEW

	Revisions:
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
	
END

