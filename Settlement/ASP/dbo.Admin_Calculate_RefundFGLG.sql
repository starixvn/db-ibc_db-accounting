ALTER PROCEDURE [dbo].[Admin_Calculate_RefundFGLG]
	@matchid	int,
	@LGOnly		bit,
	@matchdate	datetime
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund HT 
	DB: DBTrans.BODB02

	Revisions: 
		- 20110822@viet: Remove ruben=1 from the condition, add it into UPDATE part instead
		- 20111101@Tom: Change condition "statusID <> 103" to "statusID not in (103,101,102)" when refund Mix Parlay.
		- 20130410@Lukas: Add this SP to external settlement mode
				
*/
SET NOCOUNT ON

IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB215')
BEGIN
	DECLARE @sqlCommand NVARCHAR(MAX)
	
	SET @sqlCommand = 'EXEC [dbo].[Admin_Calculate_RefundFGLG_External] @matchid = ' + CONVERT(NVARCHAR(10),@matchid)
						+ ', @LGOnly = ' + CONVERT(NVARCHAR(10),@LGOnly)
						+ ', @matchdate = ''' + CONVERT(NVARCHAR(20),@matchdate,110) + ''''
	INSERT INTO Acc_Externalsettlement(SPName, SQLCommand, CreatedDate, StatusID, MatchID, Bettype, Status, BetCount)
					VALUES('Admin_Calculate_RefundFGLG',@sqlCommand,GETDATE(), 0, @matchid, 14,'waiting',1)
					
	RETURN
END

WHILE 1=1
BEGIN
	UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		status = 'Refund',
		statusID = 103,
		winlost=actual_stake,
		awinlost=0,
		mwinlost=0,
		swinlost=0,
		playercomm=0,
		comm=0,
		acomm=0,
		scomm=0,
		ruben = 1 
	where
		matchid=@matchid
		--AND [status] not in ('Void', 'Reject')
		AND statusID not in (103,101,102)
		AND bettype = 14
		--AND ruben = 1 
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end
    
    IF @@ROWCOUNT < 10000 BREAK
END

-------------Start: Refund FGLG for bettransm-------------

--WHILE 1=1
BEGIN
    --UPDATE TOP (10000) dbo.bettransm with (ROWLOCK, UPDLOCK)
	UPDATE dbo.bettransm with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		[status]='Refund',
		statusID = 103,
		statuswinlost=0,	
		ruben=1 
	WHERE 
		bettype = 14 
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		
	
--	IF @@ROWCOUNT < 10000 BREAK

    UPDATE dbo.betParlayDetail with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		statusID = 103,
		statuswinlost=0
	WHERE 
		bettype = 14 
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		

END
-------------End: Refund FGLG for bettransm-------------





GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundFGLG] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundFGLG] TO [vnteam]