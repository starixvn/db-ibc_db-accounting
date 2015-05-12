ALTER PROCEDURE [dbo].[NAP_Task_BetRadar_SyncPS]
@MatchID	INT
AS 
/*
	Created: 20150511@Jamie 
	Task: Sync PS of Betradar2
	DB: DBPRO/bodb02
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE  @betstatus				NVARCHAR(50)=''
			,@SettlementStatus135	TINYINT 
			,@HomeValue				VARCHAR(50) 
			,@ResultStatusID		TINYINT
			,@SettlementStatusID	TINYINT 
	SELECT	@betstatus = ISNULL(betstatus,'')
	FROM	Match WITH (NOLOCK)
	WHERE	MatchID = @MatchID 
			AND eventstatus ='completed'
			AND Sporttype = 1 

	IF @@ROWCOUNT = 0 RETURN 

	IF @betstatus NOT LIKE '%PS:%' 
	BEGIN
		IF EXISTS(SELECT TOP 1 1 FROM ResultDetail WITH (NOLOCK) WHERE MatchID = @MatchID AND ResourceID='135' AND HomeValue IN('Y','N'))
		BEGIN
			DELETE FROM ResultDetail WITH (ROWLOCK)
			WHERE	MatchID = @MatchID AND ResourceID='135'
		END

		RETURN 
	END

	SELECT	@SettlementStatus135 = ISNULL(SettlementStatus135,0)
	FROM	match_remark WITH (NOLOCK)
	WHERE	MatchID = @MatchID

	SELECT	@HomeValue = CASE WHEN @betstatus LIKE '%PS:N%' THEN 'N'
							  WHEN @betstatus LIKE '%PS:Y%' THEN 'Y'
							  ELSE ''
							  END

	SELECT	@ResultStatusID = CASE WHEN @SettlementStatus135 IN (2,4) THEN 2 --Auto 
								   WHEN @SettlementStatus135 = 3 THEN 5 --Manual 
								   ELSE 0
								   END 
	SELECT	@SettlementStatusID = 4 


	MERGE	ResultDetail AS TARGET
	USING(
			SELECT
				 @MatchID		AS MatchID 
				,'135'			AS ResourceID
				,@HomeValue		AS HomeValue 
				,NULL			AS AwayValue
				,NULL			AS OtherInfo 
				,@ResultStatusID		AS ResultStatusID
				,@SettlementStatusID	AS SettlementStatusID
				,111			AS CreateBy --Default system account 
				,GETDATE()		AS CreateDate
				,111			AS LastModifyBy
				,GETDATE()		AS LastModifyDate
	) AS SOURCE ON (SOURCE.MatchID = TARGET.MatchID AND TARGET.ResourceID='135')
	WHEN MATCHED THEN		 
		UPDATE SET
			TARGET.HomeValue			= SOURCE.HomeValue
			,TARGET.AwayValue			= SOURCE.AwayValue  
			,TARGET.OtherInfo			= SOURCE.OtherInfo 
			,TARGET.ResultStatusID		= SOURCE.ResultStatusID
			,TARGET.SettlementStatusID	= SOURCE.SettlementStatusID
			,TARGET.LastModifyBy		= SOURCE.LastModifyBy
			,TARGET.LastModifyDate		= SOURCE.LastModifyDate 
	WHEN	NOT MATCHED BY TARGET THEN 
			INSERT(
				 MatchID
				,ResourceID
				,HomeValue
				,AwayValue
				,OtherInfo 
				,ResultStatusID
				,SettlementStatusID
				,CreateBy
				,CreateDate
				,LastModifyBy
				,LastModifyDate
			)
			VALUES(
				 SOURCE.MatchID
				,SOURCE.ResourceID
				,SOURCE.HomeValue
				,SOURCE.AwayValue 
				,SOURCE.OtherInfo 
				,SOURCE.ResultStatusID
				,SOURCE.SettlementStatusID
				,SOURCE.CreateBy
				,SOURCE.CreateDate
				,SOURCE.LastModifyBy
				,SOURCE.LastModifyDate
			);		

END

	