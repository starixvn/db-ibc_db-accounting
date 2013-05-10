ALTER PROCEDURE [dbo].[Acc_SelHRComm_Company]

AS
/*	Created by: Phuong Nguyen
	Date: 2008-12-04
	DB: DB05.BODB02
	Task: Horse Racing meeting list
	      Get information from League table with sporttype 151 
	
	Revisions:
		- 20090321@PhuongDao: Add more info - programID 
			+ Get league name from remoting ref instead of database. 
	
*/

SET NOCOUNT ON
SELECT	leagueid AS meetingid,
		ProgramID,
		maxstake AS commwin,
		maxstakeou as commplace,	
		minstake AS commtype
	
FROM league WITH (NOLOCK)
WHERE sporttype = 151
GO
GRANT EXECUTE ON [dbo].[Acc_SelHRComm_Company] TO [bodbAdminNet]