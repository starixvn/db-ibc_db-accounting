

ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_Refund_FGLG]
	@matchid int,
	@adminid int,
	@LGOnly bit,
	@IP varchar(15) = ''
AS
/*
	Created: 20111116@Lukas
	Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
	DB: DB052.BODB_REVIEW
	Original: Admin_Settlement_Refund_FGLG	

	Revisions:
		- 20090113: Include the Refund FGLG for bettransm
		- 20091012@Kiwi: Remove custBetCredit
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add back writelog to table Userlog
		- 20100424@Henry: Update column StatusID of Bettrans
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Jamie: Call nested SP "Admin_Calculate_RefundFGLG"
		- 20100720@Henry: Stop using SP Logfile to write log
		- 20110520@Jamie: Put with (NOLOCK) when getting the event date from Match 

	Param's Explanation:
	• @matchid: matchid of match to Refund HT

*/
BEGIN

	SET NOCOUNT ON

	DECLARE @matchdate DATETIME

	SELECT @matchdate = eventdate 
	FROM bodb02.dbo.match WITH(NOLOCK)
	WHERE matchid = @matchid

	EXEC dbo.Admin_Recalculate_RefundFGLG @matchid = @matchid, @LGOnly=@LGOnly, @matchdate=@matchdate

END


