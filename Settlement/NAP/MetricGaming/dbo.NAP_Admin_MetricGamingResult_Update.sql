USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_MetricGamingResult_Update]    Script Date: 07/16/2015 16:38:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_MetricGamingResult_Update]
	@ResultID				INT
	,@Action				VARCHAR(100)	= 'CAL'
	,@Result				XML
	,@IsSettleDetermined	BIT				= 0
	,@AdminId				INT
 AS
	/*
		Created: Johnson
		Date: 2015-07-02
		Task: update event result for Metric Gaming
		DB: DBPRO/bodb02
		
		Revisions:
		
		Parameter's Explanation:
		* @Result = <Result>
						<Row GameResult="7" OtherInfo="6:10"/>
						<Row GameResult="8" OtherInfo="6:20"/>
					</Result>: Every Single Minute
		  @Result = <Result>
						<Row GameResult="15"/>
					</Result>: NONE
		  @Result = <Result>
						<Row GameResult="9" OtherInfo="62"/>
					</Result>: Time of Posession
					
		* @SuspendedTime: For bettype 806 (first goal) only.It has value when result is No Goal
				- 11: match is suspended in 0-19 min
				- 12: match is suspended in 20-45+ min
				- 13: match is suspended in 2nd half
	*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @tmpResult TABLE (
			GameResult	TINYINT,
			OtherInfo	VARCHAR(50)
		)	
	
	DECLARE @GameResult	VARCHAR(100) = ''
			,@OtherInfo	VARCHAR(100) = ''
	
	INSERT INTO @tmpResult (
			GameResult
			,OtherInfo
		)
	SELECT	t.c.value('@GameResult','TINYINT')		AS GameResult
			,t.c.value('@OtherInfo', 'VARCHAR(50)') AS OtherInfo
	FROM	@Result.nodes('Result/Row') t( c )
	
	SELECT	@GameResult = @GameResult + CAST(GameResult AS VARCHAR(10)) + ','
			,@OtherInfo = @OtherInfo + ISNULL(OtherInfo,'') + ','
	FROM	@tmpResult
		
	SELECT	@GameResult = LEFT(@GameResult,LEN(@GameResult) -1)	
			,@OtherInfo = LEFT(@OtherInfo,LEN(@OtherInfo) -1)			
						
	IF @Action = 'CAL'
	BEGIN			 
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 4,
			ResultStatusID = 5,
			LastModifyBy = @AdminID,
			LastModifyDate = GETDATE(),
			GameResult = ISNULL(@GameResult,''),
			OtherInfo = ISNULL(@OtherInfo,'')
		WHERE ResultID = @ResultID	
	END
	ELSE IF @Action = 'REFUND'
	BEGIN
		/*** Update GameResult and OtherInfo if this is Refund with Settle Determined Tickets (bettype 806)
			- Status='Refund' && GameResult='No Goal' => OherInfo = Match Suspended Time
			- Status='Refund' && GameResult=' Have Goal' => OtherInfo = Goal Time
		*** Clear GameResult and OtherInfo if this is Refund without Settle Determined Tickets
		*/
		IF @IsSettleDetermined = 0
		BEGIN
			SELECT	@GameResult = ''
					,@OtherInfo = ''
		END
		
		UPDATE	dbo.ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET		SettlementStatusID = 1
				,ResultStatusID = 5
				,GameResult = @GameResult
				,OtherInfo = @OtherInfo
				,LastModifyBy = @AdminId
				,LastModifyDate = GETDATE()
		WHERE	ResultID = @ResultID		
	END	
	ELSE IF @Action = 'UNDO'
	BEGIN
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 0,
			ResultStatusID = 5,
			LastModifyBy = @AdminID,
			LastModifyDate = GETDATE(),
			GameResult = '',
			OtherInfo = ''
		WHERE ResultID = @ResultID	
	END
END


GO
GRANT EXECUTE ON [dbo].[NAP_Admin_MetricGamingResult_Update] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_MetricGamingResult_Update] TO [vnteam] AS [dbo]