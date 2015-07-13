 ALTER PROCEDURE [dbo].[NAP_Admin_MetricGamingResult_Update]
	@ResultID	INT,
	@Action		VARCHAR(100)= 'CAL',
	@Result		VARCHAR(4000)='',
	@Creator	INT
 AS
	/*
		Created: Johnson
		Date: 2015-07-02
		Task: update event result for Metric Gaming
		DB: DBPRO/bodb02
		
		Revisions:
		
		Parameter's Explanation:
			- @Result = <Result>
							<Row GameResult='7' Time='6:10'></Row>
							<Row GameResult='8' Time='6:20'></Row>
						</Result>
			-@Result = <Result>
							<Row GameResult=''15''></Row>									
						</Result>: NONE
		
	*/
BEGIN
	SET NOCOUNT ON 
	
	IF @Action = 'Refund'
	BEGIN
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 1,
			ResultStatusID = 5,
			LastModifyBy = @Creator,
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
			LastModifyBy = @Creator,
			LastModifyDate = GETDATE(),
			GameResult = '',
			OtherInfo = ''
		WHERE ResultID = @ResultID	
	END
	IF @Action = 'Cal'
	BEGIN
		DECLARE @tmpResult TABLE (
			GameResult TINYINT,
			Time VARCHAR(50)
		)		
		
		DECLARE @DocHandler INT,
				@GameResult	VARCHAR(100) = '',
				@OtherInfo	VARCHAR(100) = ''
		
		-- For read xml     
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Result		
		
		INSERT INTO @tmpResult 
		SELECT Data.GameResult,
			Data.Time
		FROM OPENXML (@DocHandler, '/Result/Row',1)
		WITH(
			GameResult INT,
			Time		VARCHAR(50)
		) as Data
		
		EXEC sp_xml_removedocument @DocHandler
		-- end read xml
		
		SELECT @GameResult = @GameResult + CAST(GameResult AS VARCHAR(10)) + ',',
			@OtherInfo = @OtherInfo + ISNULL(Time,'') + ','
		FROM @tmpResult
		
		SELECT @OtherInfo = LEFT(@OtherInfo,len(@OtherInfo) -1),
				@GameResult = LEFT(@GameResult,len(@GameResult) -1)	
		 
		UPDATE ResultDetail3rd WITH(UPDLOCK,ROWLOCK)
		SET SettlementStatusID = 4,
			ResultStatusID = 5,
			LastModifyBy = @Creator,
			LastModifyDate = GETDATE(),
			GameResult = ISNULL(@GameResult,''),
			OtherInfo = ISNULL(@OtherInfo,'')
		WHERE ResultID = @ResultID	
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_Admin_MetricGamingResult_Update] TO [bodbAdminNet]