ALTER PROCEDURE [dbo].[NAP_SpecialDelete_VoidBetIdList_CheckingProcess]
	@IsExistParlay 		BIT
	, @IsExistOutright 	BIT
	, @IsExistMG		BIT
	, @IsExistMatch		BIT
	, @IsExistNG		BIT
	, @IsReleased		BIT	= 0
	, @AvaiableProcess	BIT = 0 OUTPUT
	, @ErrCode			INT = 0 OUTPUT
	, @ErrMsg			NVARCHAR(200) = '' OUTPUT
AS 
/* Created by: Bobby  
 Task:  VOID BY BET ID (Running & Settled tickets)  
 DB: DBTXN/bodb02  
 Original:   
   
 Revisions:  
  
 Param's Explanation:   
 
 Dependences:
	1. TABLE #tblMatch (matchid INT)
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @avaiableProcess = 0
		, @ErrCode			= 0
		, @ErrMsg			= ''
		
	IF(@IsReleased = 0)
	BEGIN
		
		IF @isExistParlay  = 1
		BEGIN
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')  
			BEGIN  
				SELECT	@ErrCode = 100  
						,@ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'  
				
				RETURN  
			END  
			ELSE
			BEGIN
				UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
					SET VValue = '1'  
				WHERE	VName = 'isCalculatingParlay' 
						AND VValue = '0'  
						
				SET @avaiableProcess = 1
			END
		END
		
		IF @isExistOutright = 1
		BEGIN
			IF EXISTS (SELECT TOP 1 1 FROM dbo.TempVariableNumber WITH(NOLOCK)
						WHERE KeyID = 2 AND KeyValue IN (SELECT matchid FROM #tblMatch)
					)
			BEGIN
				IF @isExistParlay = 1
					UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
						SET VValue = '0'  
					WHERE	VName = 'isCalculatingParlay' 
							AND VValue = '1'  
					
				SELECT @ErrCode = 101
					,@ErrMsg = 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
				
				SET @avaiableProcess = 0
				RETURN
			END
			ELSE
			BEGIN
			
				BEGIN TRY	
					
					INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) 
					SELECT 2, matchid
					FROM	#tblMatch
					
					SET @avaiableProcess = 1
					
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = ERROR_NUMBER()
						,@ErrMsg = ERROR_MESSAGE()
							
				END CATCH
				
				IF @ErrCode > 0
				BEGIN
					IF @isExistParlay = 1
						UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
							SET VValue = '0'  
						WHERE	VName = 'isCalculatingParlay' 
								AND VValue = '1'  
					
					SELECT @ErrCode = 100
						,@ErrMsg	= 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
					
					SET @avaiableProcess = 0
					RETURN
				END
				
			END
		END 
		
		IF @isExistMG = 1
		BEGIN
			IF EXISTS (SELECT TOP 1 1 FROM dbo.TempVariableNumber WITH(NOLOCK)
						WHERE KeyID = 3 AND KeyValue IN (SELECT matchid FROM #tblMatch)
					)
			BEGIN
				IF @isExistParlay = 1
					UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
						SET VValue = '0'  
					WHERE	VName = 'isCalculatingParlay' 
							AND VValue = '1'  
				
				IF @isExistOutright = 1
					DELETE 
					FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
					WHERE	KeyID = 2 
							AND KeyValue IN (SELECT matchid FROM #tblMatch)
							
				SELECT @ErrCode = 101
					,@ErrMsg = 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
				
				SET @avaiableProcess = 0
				
				RETURN
			END
			ELSE
			BEGIN
				BEGIN TRY	
					
					INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) 
					SELECT 3, matchid
					FROM	#tblMatch
					
					SET @avaiableProcess = 1
					
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = ERROR_NUMBER()
						,@ErrMsg = ERROR_MESSAGE()
							
				END CATCH
				
				IF @ErrCode > 0
				BEGIN
					IF @isExistParlay = 1
						UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
							SET VValue = '0'  
						WHERE	VName = 'isCalculatingParlay' 
								AND VValue = '1'  
				
					IF @isExistOutright = 1
						DELETE 
						FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
						WHERE	KeyID = 2 
								AND KeyValue IN (SELECT matchid FROM #tblMatch)
					
					SELECT @ErrCode = 100
						,@ErrMsg	= 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
					
					SET @avaiableProcess = 0
					
					RETURN
				END
				
			END
		END 
		
		IF @isExistMatch = 1 OR @isExistNG = 1
		BEGIN
			IF EXISTS (SELECT TOP 1 1 FROM dbo.TempVariableNumber WITH(NOLOCK)
						WHERE KeyID = 1 AND KeyValue IN (SELECT matchid FROM #tblMatch)
					)
			BEGIN
				IF @isExistParlay = 1
					UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
						SET VValue = '0'  
					WHERE	VName = 'isCalculatingParlay' 
							AND VValue = '1'  
					
				IF @isExistOutright = 1
					DELETE 
					FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
					WHERE	KeyID = 2 
							AND KeyValue IN (SELECT matchid FROM #tblMatch)
							
				IF @isExistMG = 1
					DELETE 
					FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
					WHERE	KeyID = 3 
							AND KeyValue IN (SELECT matchid FROM #tblMatch)
							
				SELECT @ErrCode = 101
					,@ErrMsg = 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
				
				SET @avaiableProcess = 0
				
				RETURN
			END
			ELSE
			BEGIN
				BEGIN TRY	
					
					INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) 
					SELECT 1, matchid
					FROM	#tblMatch
					
					SET @avaiableProcess = 1
					
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = ERROR_NUMBER()
						,@ErrMsg = ERROR_MESSAGE()
							
				END CATCH
				
				IF @ErrCode > 0
				BEGIN
					IF @isExistParlay = 1
						UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
							SET VValue = '0'  
						WHERE	VName = 'isCalculatingParlay' 
								AND VValue = '1'  
					
					IF @isExistOutright = 1
						DELETE 
						FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
						WHERE	KeyID = 2 
								AND KeyValue IN (SELECT matchid FROM #tblMatch)
								
					IF @isExistMG = 1
						DELETE 
						FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
						WHERE	KeyID = 3 
								AND KeyValue IN (SELECT matchid FROM #tblMatch)
					
					SELECT @ErrCode = 100
						,@ErrMsg	= 'This match is being calculated or some tickets of this match are being voided, please wait a few seconds until the on-going process is completed and try again.'
					
					SET @avaiableProcess = 0
					
					RETURN
				END
				
			END
		END 
		
		IF @isExistNG = 1
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM	SystemSettings WITH (NOLOCK)
				WHERE	VValue = 1 
						AND VName = 'isCalculatingNGManual'
				)
			BEGIN
				IF @isExistParlay = 1
					UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
						SET VValue = '0'  
					WHERE	VName = 'isCalculatingParlay' 
							AND VValue = '1'  
					
				IF @isExistOutright = 1
					DELETE 
					FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
					WHERE	KeyID = 2 
							AND KeyValue IN (SELECT matchid FROM #tblMatch)
							
				IF @isExistMG = 1
					DELETE 
					FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
					WHERE	KeyID = 3 
							AND KeyValue IN (SELECT matchid FROM #tblMatch)
				
				DELETE 
				FROM	dbo.TempVariableNumber WITH(ROWLOCK, UPDLOCK)
				WHERE	KeyID = 1 
						AND KeyValue IN (SELECT matchid FROM #tblMatch)
							
				SELECT	@ErrCode = 104
						,@ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being voided, please wait a few seconds until the on-going process has finished and try again.'
				
				SET @avaiableProcess = 0
				
				RETURN
			END
			ELSE
			BEGIN
				UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
				SET VValue = '1'
				WHERE VName = 'isCalculatingNGManual'
				
				SET @avaiableProcess = 1
			END
		END
	END
	ELSE IF (@IsReleased = 1)
	BEGIN
		IF @isExistParlay = 1
			UPDATE	dbo.systemSettings WITH (ROWLOCK, UPDLOCK)  
			SET VValue = '0'  
			WHERE VName = 'isCalculatingParlay' 
				AND VValue = '1'  
				
		IF @isExistNG = 1
			UPDATE dbo.systemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = '0'
			WHERE VName = 'isCalculatingNGManual'
				
		IF @isExistMatch = 1
			OR @isExistOutright = 1
			OR @isExistMG = 1
			OR @isExistNG = 1
		BEGIN
			DELETE 
			FROM dbo.TempVariableNumber
			WHERE	KeyValue IN (SELECT matchid FROM #tblMatch)
				AND KeyId IN (1,2,3)
					
		END
	END
	
	RETURN
	
END
GO
