/****** Object:  StoredProcedure [dbo].[NAP_Admin_Match_Update]    Script Date: 09/03/2014 15:40:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Match_Update]
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
		- 20140618@Kathy: Remove PenaltyShootout string, correct betstatus in case match has been refunded [Redmine:#17142]  
		- 20140825@Kathy: Only update HT part of goalrecord when calculating HT
						   
		
*/
BEGIN
	select '1'
	SET @BetStatus = ISNULL(@BetStatus, N'')
	
	IF @Command = 'NAP_Admin_Settlement_1-UNDO'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'running', finalhomescore = NULL, finalawayscore = NULL, hthomescore = NULL, htawayscore = NULL
			,betstatus = N''
			,GoalRecord = ''
			,changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid = @MatchID-- and eventstatus = 'completed'
	END
	IF @Command = 'NAP_Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore = @FTHome, finalawayscore = @FTAway,
			hthomescore = @HTHome, htawayscore = @HTAway,
			betstatus = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			goalrecord = CASE WHEN @goalrecord IS NULL OR @goalrecord = '' THEN goalrecord 
							  WHEN @action = 'CAL-HT' AND ISNULL(GoalRecord,'') <> '' THEN REPLACE(GoalRecord,LEFT(GoalRecord,CHARINDEX(';',GoalRecord)),(LEFT(@goalrecord,CHARINDEX(';',@goalrecord)))) -- only update HT part
							  ELSE @goalrecord END,
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
		SELECT @betstatus = CASE WHEN charindex('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,'') -- PS:Y; or PS:N;
								 ELSE ISNULL(betstatus,'')
							END
		FROM match with(NOLOCK)
		WHERE matchid = @matchid

		UPDATE match WITH(ROWLOCK,UPDLOCK) 
		SET eventstatus='Completed', ruben=1, finalhomescore=0, finalawayscore=0, hthomescore=0, htawayscore=0 
			,betstatus = 'Refund;' + CASE  WHEN CHARINDEX('Refund;',@betstatus) > 0 THEN REPLACE(@betstatus,'Refund;','')
										WHEN CHARINDEX('Refund FT;',@betstatus) > 0 THEN REPLACE(@betstatus,'Refund FT;','')
										WHEN CHARINDEX('Refund HT;',@betstatus)>0 THEN REPLACE(@betstatus,'Refund HT;','')
										ELSE @betstatus
									END
			,GoalRecord =''
			,changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID
	END
	IF @Command = 'NAP_Admin_Settlement_RefundFT'
	BEGIN
		SELECT @betstatus = CASE WHEN charindex('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,'') -- PS:Y; or PS:N;
								 ELSE ISNULL(betstatus, '')
							END
		FROM match with(NOLOCK)
		WHERE matchid = @matchid

		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore=0, finalawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', @betstatus) > 0 
									THEN @betstatus 
							 ELSE 'Refund FT;' + CASE WHEN CHARINDEX('Refund HT;',@betstatus) > 0 
															THEN REPLACE(@betstatus, 'Refund HT;', '') 
													  ELSE REPLACE(@betstatus, 'Refund FT;', '')
												 END
						END,
			eventstatus = 'Completed', changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore=0, htawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 
									THEN betstatus 
							 ELSE 'Refund HT;' + CASE WHEN CHARINDEX('Refund FT;',betstatus) > 0 
															THEN REPLACE(ISNULL(betstatus,''), 'Refund FT;', '') 
													  ELSE REPLACE(ISNULL(betstatus,''), 'Refund HT;', '')
												 END
						END,
			changetime = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'NAP_Admin_Settlement_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK)
		SET	betstatus = case when right(@BetStatus,1) = ';' THEN @betstatus
							 ELSE @betstatus + ';'
						END
			,GoalRecord = CASE WHEN @goalrecord IS NULL OR @goalrecord = '' THEN goalrecord 
							   WHEN @action = 'CAL-HT' AND ISNULL(GoalRecord,'') <> '' THEN REPLACE(GoalRecord,LEFT(GoalRecord,CHARINDEX(';',GoalRecord)),(LEFT(@goalrecord,CHARINDEX(';',@goalrecord)))) -- only update HT part
							   ELSE @goalrecord 
						  END
			--,goalrecord = @GoalRecord
			,changetime = GETDATE()
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
	IF @Command = 'NAP_Admin_Settlement_135'
	BEGIN
		UPDATE dbo.match with(ROWLOCK, UPDLOCK)
		SET betstatus = CASE WHEN CHARINDEX('PS:',betstatus) > 0 THEN STUFF(betstatus, CHARINDEX('PS:',betstatus),5,@betstatus) -- PS:Y/N;
							 ELSE RTRIM(ISNULL(betstatus,''))  + @betstatus
						END
			,changetime = GETDATE()
			,settletime = GETDATE()
		WHERE matchid = @matchid
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
GRANT EXECUTE ON [dbo].[NAP_Admin_Match_Update] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Match_Update] TO [vnteam] AS [dbo]