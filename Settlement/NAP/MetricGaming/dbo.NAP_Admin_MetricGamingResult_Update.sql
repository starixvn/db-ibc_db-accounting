 ALTER PROCEDURE [dbo].[NAP_Admin_MetricGamingResult_Update]
	@ResultID	INT,
	@Action		VARCHAR(100)= 'CAL',
	@Result		XML,
	@AdminID	INT
 AS
	/*
		Created: Johnson
		Date: 2015-07-02
		Task: update event result for Metric Gaming
		DB: DBPRO/bodb02
		
		Revisions:
		
		Parameter's Explanation:
			- @Result = <Result>
							<Row GameResult='7' OtherInfo='6:10'></Row>
							<Row GameResult='8' OtherInfo='6:20'></Row>
						</Result>: Every Single Minute
			-@Result = <Result>
							<Row GameResult='15' OtherInfo=''></Row>									
						</Result>: NONE
			-@Result = <Result>
							<Row GameResult='9' OtherInfo='62'></Row>
						</Result>: Time of Posession
		
	*/
BEGIN
	SET NOCOUNT ON 
	
	IF @Action = 'Refund'
	BEGIN
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 1,
			ResultStatusID = 5,
			LastModifyBy = @AdminID,
			LastModifyDate = GETDATE(),
			GameResult = '',
			OtherInfo = ''
		WHERE ResultID = @ResultID		
	END	
	IF @Action = 'Undo'
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
	IF @Action = 'Cal'
	BEGIN
		DECLARE @tmpResult TABLE (
			GameResult TINYINT,
			OtherInfo VARCHAR(50)
		)		
		
		DECLARE @DocHandler INT,
				@GameResult	VARCHAR(100) = '',
				@OtherInfo	VARCHAR(100) = ''
		
		INSERT INTO @tmpResult 
		SELECT t.c.value('@GameResult','int')
			t.c.value('@OtherInfo','varchar(50)') AS Value
		FROM @Result.nodes('Result/Row')  t(c)	
		
		SELECT @GameResult = @GameResult + CAST(GameResult AS VARCHAR(10)) + ',',
			@OtherInfo = @OtherInfo + ISNULL(Time,'') + ','
		FROM @tmpResult
		
		SELECT @OtherInfo = LEFT(@OtherInfo,len(@OtherInfo) -1),
				@GameResult = LEFT(@GameResult,len(@GameResult) -1)	
		 
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 4,
			ResultStatusID = 5,
			LastModifyBy = @AdminID,
			LastModifyDate = GETDATE(),
			GameResult = ISNULL(@GameResult,''),
			OtherInfo = ISNULL(@OtherInfo,'')
		WHERE ResultID = @ResultID	
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_MetricGamingResult_Update] TO [bodbAdminNet]