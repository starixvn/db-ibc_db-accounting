ALTER PROCEDURE [NAP_Admin_Match_Update]
(
	@Command VARCHAR(100),
	@MatchID INT,
	@FTHome SMALLINT = NULL,
	@FTAway SMALLINT = NULL,
	@HTHome SMALLINT = NULL,
	@HTAway SMALLINT = NULL,
	@BetStatus NVARCHAR(50) = NULL,
	@GoalRecord VARCHAR(50) = NULL,
	@Action VARCHAR(10) = NULL,
	@FTDone BIT = 0,
	@HTDone BIT = 0,
	@RowCount INT = 0 OUTPUT,
	@Creator INT = 0
) 
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Update information into match table (when run settlement)
	DB: DB02.bodb02
	Original: Admin_Match_Update

	Revisions:
		- 20140423@Kathy: Modify betstatus value (Offer 1H FGLG) [Redmine:#14449]
		
*/
BEGIN
	SET @BetStatus = ISNULL(@BetStatus, N'')
	
	IF @Command = 'NAP_Admin_Settlement_1-UNDO'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'running', finalhomescore = NULL, finalawayscore = NULL, hthomescore = NULL, htawayscore = NULL, betstatus = N'', GoalRecord = ''
			, changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid = @MatchID-- and eventstatus = 'completed'
	END
	IF @Command = 'NAP_Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore = @FTHome, finalawayscore = @FTAway,
			hthomescore = @HTHome, htawayscore = @HTAway,
			betstatus = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			goalrecord = CASE WHEN @goalrecord IS NULL OR @goalrecord = '' THEN goalrecord ELSE @goalrecord END,
			eventstatus = CASE	WHEN @action = 'CAL' THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 THEN N'completed'
							ELSE eventstatus END,
			changetime = GETDATE(),
			settleTime = CASE 
							WHEN @action = 'CAL' THEN GETDATE()
							WHEN @action = 'CAL-FT' THEN GETDATE()
							ELSE settleTime END	
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_Refund_All'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) 
		SET eventstatus='Completed', ruben=1, finalhomescore=0, finalawayscore=0, hthomescore=0, htawayscore=0
			,betstatus = 'Refund' + CASE when CHARINDEX('FL:',ISNULL(betstatus,'')) = 0  THEN ''
										 when CHARINDEX('1FL:',ISNULL(betstatus,'')) = 0 AND CHARINDEX('FL:',ISNULL(betstatus,'')) <> 0 THEN ';' + SUBSTRING(betstatus,CHARINDEX('FL:', betstatus),LEN(betstatus))
										 ELSE ';' + SUBSTRING(betstatus,CHARINDEX('1FL', betstatus),LEN(betstatus))
									END 
			,GoalRecord =''
			,changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_RefundFT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore=0, finalawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 THEN betstatus ELSE 'Refund FT;' + replace(ISNULL(betstatus,''), 'Refund FT;', '') END ,
			eventstatus = 'Completed', changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore=0, htawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 THEN betstatus ELSE 'Refund HT;' + replace(ISNULL(betstatus,''), 'Refund HT;', '') END,
			changetime = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK)
		SET	betstatus = @BetStatus, goalrecord = @GoalRecord, changetime = GETDATE()
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_Refund_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET betstatus = @BetStatus, changetime = GETDATE() WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_Parlay'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET multiple=multiple, changetime = GETDATE() WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s161-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus = 'Refund',
			eventstatus = 'Completed', changetime = CURRENT_TIMESTAMP, settleTime = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s161-Refund_FT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'Completed',
			betstatus = 'Refund FT',
			changetime = CURRENT_TIMESTAMP

		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s161-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = '',
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus = 'Refund',
			eventstatus = 'Completed', changetime = CURRENT_TIMESTAMP, settleTime = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_s162-1102-CAL'
	BEGIN
		select @BetStatus = Resource_en from RefResource with (rowlock) 
		where refid ='RouNumProperty' and 
		resourceid in (select Finalhomescore from  match with (rowlock) where matchid = @MatchID)
		
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = @BetStatus,
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_SS-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_VS_181-CAL'
	BEGIN
		UPDATE dbo.VSRaceInfo WITH(ROWLOCK,UPDLOCK)
		SET					
			calculate = 1,
			eventstatus = 'Completed',
			betstatus = NULL ,
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID

		UPDATE [dbo].[VSOutright] WITH(ROWLOCK,UPDLOCK)
		SET					
			eventstatus = 'Completed',			
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_VS_181-Refund'
	BEGIN
		UPDATE dbo.VSRaceInfo WITH(ROWLOCK,UPDLOCK)
		SET	
			betstatus = 'Refund',			
			eventstatus = 'Completed',
			calculate = 1,
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID

		UPDATE [dbo].[VSOutright] WITH(ROWLOCK,UPDLOCK)
		SET					
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP
		WHERE EventID = @MatchID
	END	
END
GO

GRANT EXECUTE ON [NAP_Admin_Match_Update] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Match_Update] TO [vnteam] AS [dbo]
GO


