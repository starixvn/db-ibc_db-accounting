

ALTER PROCEDURE [dbo].[Admin_Recalculate_RefundFGLG]
	@matchid	int,
	@LGOnly		bit,
	@matchdate	datetime
AS
/*	
	Created by: 20111116@Lukas
	Task: Refund HT 
	DB: DB052.BODB_REVIEW
	Original: Admin_Calculate_RefundFGLG

	Revisions: 20110822@viet: Remove ruben=1 from the condition, add it into UPDATE part instead
				20111101@Tom: Change condition "statusID <> 103" to "statusID not in (103,101,102)" when refund Mix Parlay.
*/
BEGIN
	SET NOCOUNT ON

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

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettransm with (ROWLOCK, UPDLOCK)
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
		
		IF @@ROWCOUNT < 10000 BREAK
	END
	-------------End: Refund FGLG for bettransm-------------

END

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Recalculate_RefundFGLG] TO [VNTeam]
GO 