ALTER PROCEDURE [Admin_Calculate_RefundFGLG] @matchid	int,
	@action varchar(10) = 'CAL',
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
		- 20140120@Lukas: insert settled command into LAS queue [Redmine:#8785]
		- 20140421@Kathy: Add 1H FGLG bettypes (127) [Redmine:#14718]
				
*/
BEGIN
	SET NOCOUNT ON

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054','DB231')
	BEGIN
		DECLARE @sqlCommand NVARCHAR(MAX)
	
		SET @sqlCommand = 'EXEC [dbo].[Admin_Calculate_RefundFGLG_External] @matchid = ' + CONVERT(NVARCHAR(10),@matchid)
							+ ', @action = ''' + CONVERT(NVARCHAR(10),@action) + ''''
							+ ', @LGOnly = ' + CONVERT(NVARCHAR(10),@LGOnly)
							+ ', @matchdate = ''' + CONVERT(NVARCHAR(20),@matchdate,110) + ''''
		INSERT INTO Acc_Externalsettlement(SPName, SQLCommand, CreatedDate, StatusID, MatchID, Bettype, Status, BetCount)
						VALUES('Admin_Calculate_RefundFGLG',@sqlCommand,GETDATE(), 0, @matchid, 14,'waiting',1)
					
		--- LAS settlement 
		IF @@SERVERNAME IN ('DB052','DB054','DB231', 'DB232')  AND EXISTS (SELECT * FROM sys.databases WHERE name = 'LASDB')
		BEGIN		

			DECLARE @LASCommand NVARCHAR(1000),
					@createdDate DATETIME

			SELECT	 @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundFGLG] @matchid = ' + CONVERT(NVARCHAR(10),@matchid) 
									+ ', @action = ''' + CONVERT(NVARCHAR(10),@action) + ''''
									+ ', @LGOnly = ' + CONVERT(NVARCHAR(10),@LGOnly)
									+ ', @matchdate = ''' + CONVERT(NVARCHAR(20),@matchdate,110) + ''''
					,@createdDate = GETDATE()

			EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand]	 @SPName		= 'Admin_Calculate_RefundFGLG'
																,@SQLCommand	= @LASCommand
																,@CreatedDate	= @createdDate
																,@StatusID		= 0 -- waiting
																,@MatchID		= @matchid
																,@Bettype		= 0 -- hardcode
																,@Status		= 'waiting'
																,@BetCount		= 0		
		END
		RETURN 
	END

	DECLARE @bettype int

	select @bettype = CASE WHEN @action = 'CAL-HT' then 127
						   when @action = 'CAL-FT' then 14
						   ELSE 0
					  end 

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
			AND ((@bettype = 0 AND bettype IN (14,127)) 
					OR (bettype = @bettype))
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
			((@bettype = 0 and bettype in (14, 127)) OR (bettype = @bettype))
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
			((@bettype = 0 and bettype IN (14, 127)) OR (bettype = @bettype)) 
			AND matchid=@matchid
			AND statusID not in (103,101,102)
			AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		

	END
	-------------End: Refund FGLG for bettransm-------------
END


GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundFGLG] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundFGLG] TO [vnteam]