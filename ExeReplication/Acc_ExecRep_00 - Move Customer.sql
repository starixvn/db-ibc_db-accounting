ALTER PROCEDURE [dbo].[Acc_ExecRep_00]
	@custid INT = 0,
	@recommend INT = 0,
	@recommend_old INT = 0,
	@mrecommend INT,
	@mrecommend_old INT = 0,
	@srecommend INT,
	@srecommend_old INT,
	@roleid TINYINT,
	@ErrCode INT OUTPUT,
	@ErrMsg VARCHAR(500) OUTPUT
AS
/*
Created: 20091222@Kiwi
Task : Move accounts
DB: DBTXN/bodb02
Original: Acc_CustomerUpdMoveMaster, Acc_CustomerUpdMoveAgent, Acc_CustomerUpdMoveMember

Revisions:
	- 20100114@Kiwi: Put in "AND srecommend = @srecommend_old" when we update sum_winloss table
	- 20131108@Elodie: Splitting bodb02 into CustDB (Roll back updates on custinfo, customer table in main SP)  
   
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    
• @ErrMsg: Error description.
*/

--IF @@ServerName <> 'DB02'
--	WAITFOR DELAY '00:00:30.000'

--Retrieve data to check existed tables (custinfo, customer, bettrans, bettrans14, sum_winloss) before moving
DECLARE --@IsExistCust TINYINT,
		@IsExistBettrans BIT,
		@IsExistBettrans14 BIT,
		@IsExistSum_Winloss BIT,
		@IsExistCustinfo BIT

--SELECT @IsExistCust = COUNT(*) FROM dbo.sysobjects
--WHERE	name IN ('custinfo','customer')
--		AND xtype = 'U'
--HAVING COUNT(*) = 2

SELECT @IsExistCustinfo = COUNT(*) FROM dbo.sysobjects WHERE name = 'custinfo'
SELECT @IsExistBettrans = COUNT(*) FROM dbo.sysobjects WHERE name = 'bettrans'
SELECT @IsExistBettrans14 = COUNT(*) FROM dbo.sysobjects WHERE name = 'bettrans14'
SELECT @IsExistSum_Winloss = COUNT(*) FROM dbo.sysobjects WHERE name = 'sum_winloss'


DECLARE @cnt INT
DECLARE @CustInfo TABLE (CustID INT PRIMARY KEY)

IF (@roleid = 3 and @IsExistCustinfo = 1) --Perform to move master agent
BEGIN
	
	INSERT INTO @CustInfo
	SELECT custid FROM CustDB.dbo.custinfo (NOLOCK)
	WHERE mrecommend = @mrecommend
	
	--bettrans table
	IF (@IsExistBettrans = 1)
	BEGIN
		WHILE (1=1)
		BEGIN	
			UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
			SET srecommend = @srecommend 
			WHERE custid IN (SELECT CustID FROM @CustInfo)  
				AND srecommend = @srecommend_old  	
	    	
			IF  @@ROWCOUNT < 1000
				BREAK       
		END
	
		IF (@@ERROR <> 0)
		BEGIN			
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
			END
			*/
			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old 
				WHERE mrecommend = @mrecommend AND srecommend = @srecommend	

				IF @@ROWCOUNT < 1000
					BREAK
			END		

			SELECT @ErrMsg = 'Error master ' + CAST(@mrecommend AS VARCHAR) + ': update unsuccessfully (bettrans).',
				@ErrCode = 110					 
			RETURN
		END
	END

	------------------------------
	--bettrans14 table
	IF (@IsExistBettrans14 = 1)
	BEGIN
		WHILE (1=1)
		BEGIN
			UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
			SET srecommend = @srecommend 
			WHERE custid IN (SELECT CustID FROM @CustInfo) 
				AND srecommend = @srecommend_old

			IF  @@ROWCOUNT < 1000
				BREAK
		END
		
		IF (@@ERROR <> 0)
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
			END
			*/
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old 
				WHERE mrecommend = @mrecommend AND srecommend = @srecommend
					
				IF @@ROWCOUNT < 1000
					BREAK
			END	

			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old 
				WHERE mrecommend = @mrecommend AND srecommend = @srecommend 	

				IF @@ROWCOUNT < 1000
					BREAK
			END	

			SELECT @ErrMsg = 'Error super master ' + CAST(@mrecommend AS VARCHAR) + ': update unsuccessfully (bettrans14).',
				@ErrCode = 111					 
			RETURN
		END
	END

	--sum_winloss table
	IF (@IsExistSum_Winloss = 1)
	BEGIN
		UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
		WHERE	custid IN (SELECT CustID FROM @CustInfo)
				AND srecommend = @srecommend_old
		
		IF (@@ERROR <> 0) 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
				WHERE mrecommend = @mrecommend
			END
			*/
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old 
				WHERE mrecommend = @mrecommend AND srecommend = @srecommend 	

				IF @@ROWCOUNT < 1000
					BREAK
			END	

			WHILE (1=1 AND @IsExistBettrans14 = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old 
				WHERE mrecommend = @mrecommend AND srecommend = @srecommend

				IF @@ROWCOUNT < 1000
					BREAK
			END	
			
			UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
			WHERE mrecommend = @mrecommend
			
			SELECT @ErrMsg = 'Error master ' + CAST(@mrecommend AS VARCHAR) + ': update unsuccessfully (sum_winloss).',
				@ErrCode = 112					 
			RETURN
		END
	END
END
ELSE IF (@roleid = 2 and @IsExistCustinfo = 1) --Perform to move agent
BEGIN
	
	INSERT INTO @CustInfo
	SELECT custid FROM CustDB.dbo.custinfo (NOLOCK)
	WHERE recommend = @recommend	
	
	--bettrans table
	IF (@IsExistBettrans = 1)
	BEGIN
		WHILE (1=1)
		BEGIN
			UPDATE TOP (1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK) 
			SET srecommend = @srecommend, mrecommend = @mrecommend 
			WHERE custid IN(SELECT CustID FROM @CustInfo)
				AND srecommend = @srecommend_old 
				AND mrecommend = @mrecommend_old
				
			IF  @@ROWCOUNT< 1000
				BREAK		       
		END
		IF @@ERROR <> 0 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
			END
			*/			
			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
					AND mrecommend = @mrecommend
				
				IF @@ROWCOUNT < 1000
						BREAK		
			END
			SELECT @ErrMsg = 'Error agent ' + CAST(@recommend AS VARCHAR) + ': update unsuccessfully (bettrans).',
					@ErrCode = 112					 
			RETURN
		END
	END
	IF (@IsExistBettrans14 = 1)
	BEGIN
		WHILE (1=1)
		BEGIN
		--bettrans14 table
			UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
			SET srecommend = @srecommend, mrecommend = @mrecommend 
			WHERE custid IN(SELECT CustID FROM @CustInfo)
					AND srecommend = @srecommend_old 
					AND mrecommend = @mrecommend_old
				
			IF  @@ROWCOUNT< 1000
				BREAK

		END

		IF @@ERROR <> 0 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
			END
			*/
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
					AND mrecommend = @mrecommend
				
				IF @@ROWCOUNT < 1000
					BREAK
			END
			
			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
					AND mrecommend = @mrecommend
				
				IF @@ROWCOUNT < 1000
					BREAK
			END			
			
			SELECT @ErrMsg = 'Error agent ' + CAST(@recommend AS VARCHAR) + ': update unsuccessfully (bettrans14).',
				@ErrCode = 113					 	
			RETURN
		END
	END
	
	--sum_winloss table
	IF (@IsExistSum_Winloss = 1)
	BEGIN
		UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend, mrecommend = @mrecommend 
		WHERE	custid IN(SELECT CustID FROM @CustInfo)
				AND srecommend = @srecommend_old 
				AND mrecommend = @mrecommend_old
		IF @@ERROR <> 0 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
			END
			*/
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)
					AND mrecommend = @mrecommend
				
				IF @@ROWCOUNT < 1000
					BREAK
			END	
			
			WHILE (1=1 AND @IsExistBettrans14 = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
				WHERE custid IN(SELECT CustID FROM @CustInfo)	
					AND mrecommend = @mrecommend
					
				IF @@ROWCOUNT < 1000
					BREAK
			END
			
			UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
			WHERE custid IN(SELECT CustID FROM @CustInfo)
			
			SELECT @ErrMsg = 'Error agent ' + CAST(@recommend AS VARCHAR) + ': update unsuccessfully (sum_winloss).',
				@ErrCode = 114					 

			RETURN
		END
	END

END
ELSE  --@ROLEID = 1: Perform to move member
BEGIN
	IF (@IsExistBettrans = 1)
	BEGIN
		--bettrans table
		WHILE (1=1)
		BEGIN
			UPDATE TOP (1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK) 
			SET srecommend = @srecommend, mrecommend = @mrecommend, recommend = @recommend
			WHERE	custid = @custid
					AND recommend = @recommend_old
				
				IF  @@ROWCOUNT < 1000
					BREAK
		END
		IF @@ERROR <> 0 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
			END
			*/
			
			--rollback bettrans
			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid AND recommend = @recommend
				IF @@ROWCOUNT < 1000
						BREAK		
			END

			SELECT @ErrMsg = 'Error member ' + CAST (@custid AS VARCHAR) + ': update unsuccessfully (bettrans).',
				@ErrCode = 112		
			RETURN
		END
	END
	--bettrans14 table
	IF (@IsExistBettrans14 = 1)
	BEGIN
		WHILE (1=1)
		BEGIN
			UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
			SET srecommend = @srecommend, mrecommend = @mrecommend, recommend = @recommend
			WHERE	custid = @custid 
					AND recommend = @recommend_old

			IF  @@ROWCOUNT< 1000
				BREAK
		END
		IF @@ERROR <> 0 
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
			END
			*/
			--rollback bettrans
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid AND recommend = @recommend
				
				IF @@ROWCOUNT < 1000
						BREAK		
			END

			--rollback bettrans14
			WHILE (1=1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid AND recommend = @recommend

				IF @@ROWCOUNT < 1000
					BREAK
			END			

			SELECT @ErrMsg = 'Error member ' + CAST (@custid AS VARCHAR) + ': update unsuccessfully (bettrans14).',
				@ErrCode = 113	
			RETURN
		END
	END
	IF (@IsExistSum_Winloss = 1)
	BEGIN
		--sum_winloss table
		UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) 
		SET srecommend = @srecommend, mrecommend = @mrecommend, recommend = @recommend
		WHERE	custid = @custid 
				AND recommend = @recommend_old
		IF @@ERROR <> 0 
		BEGIN			
			--ROLLBACK TRANSACTION MANUALLY
			-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  			
			/*
			IF (@IsExistCust = 2)
			BEGIN 
				UPDATE customer WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
				
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid
			END
			*/
			
			--rollback bettrans
			WHILE (1=1 AND @IsExistBettrans = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid AND recommend = @recommend
				IF @@ROWCOUNT < 1000
						BREAK		
			END

			--rollback bettrans14
			WHILE (1=1 AND @IsExistBettrans14 = 1)
			BEGIN
				UPDATE TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK) 
				SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
				WHERE custid = @custid AND recommend = @recommend

				IF @@ROWCOUNT < 1000
					BREAK
			END			

			--rollback sum_winloss
			UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) 
			SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
			WHERE custid = @custid

			SELECT @ErrMsg = 'Error member ' + CAST (@custid AS VARCHAR) + ': update unsuccessfully (sum_winloss).',
				@ErrCode = 114		
			RETURN
		END
	END
END


GO
GRANT EXECUTE ON [dbo].[Acc_ExecRep_00] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_00] TO [vnteam] AS [dbo]