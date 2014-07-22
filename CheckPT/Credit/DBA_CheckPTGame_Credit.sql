USE [CheckResultDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CheckPTGame_Credit]    Script Date: 4/14/2014 2:24:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CheckPTGame_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
Created: 20140313@Sophia
Task: Check PT setting for credit customers - Game setting
DB: DBCHECK.CheckResultDB
Revisions:
	 
Param's Explanation: 
	@RuleId = 0 : 'all'

*/

BEGIN 
IF @sporttype = 162 OR @sporttype = 0 
BEGIN 
	---- 1. S1 < 0 OR M1 < 0 OR A1 < 0

		IF @RuleId IN (0,1)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	1 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
					CASE WHEN cs.spositiontaking < 0 THEN cs.spositiontaking 
						 WHEN cs.mpositiontaking < 0 THEN cs.mpositiontaking 
						 WHEN cs.apositiontaking < 0 THEN cs.apositiontaking
					ELSE 0
					END,
					0, 
					0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (cs.spositiontaking < 0 OR cs.mpositiontaking < 0 OR cs.apositiontaking < 0)
		
		END

	
		----2. S4 > 0.93 OR M4 > 0.93 OR A4 > 0.93 

		IF @RuleId IN (0,2)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	2 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
					CASE WHEN cs.spositiontaking > 0.93 THEN cs.spositiontaking 
						 WHEN cs.mpositiontaking > 0.93 THEN cs.mpositiontaking 
						 WHEN cs.apositiontaking > 0.93 THEN cs.apositiontaking	
					ELSE 0.93	
					END,
					0.93,
					0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (cs.spositiontaking > 0.93 OR cs.mpositiontaking > 0.93 OR cs.apositiontaking > 0.93)

		
		END

		----3. S4 < M4 

		IF @RuleId IN (0,3)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	3 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.mpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.spositiontaking < cs.mpositiontaking 

	
		END

		----4. S4 < A4

		IF @RuleId IN (0,4)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	4 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.spositiontaking < cs.apositiontaking 


		END

		----5. S4 < N4 
 
		IF @RuleId IN (0,5)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	5 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
				INNER JOIN CheckCustDB.dbo.CustOverrideGame co WITH (NOLOCK)
					ON co.CustId=ci.CustId 
					AND co.SportType=cs.SportType
					AND co.BetType=cs.BetType
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.spositiontaking < co.minpositiontaking


		END


		----6. S4 < US3 

		IF @RuleId IN (0,6)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	6 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking , cs.autopositiontaking, 0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE	ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.spositiontaking < cs.autopositiontaking


		END

		----7. S4 < US1 

		IF @RuleId IN (0,7)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	7 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.autopositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.spositiontaking < cs.autopositiontaking


			
		END
	
		----8. S4 < S3 + M3 

		IF @RuleId IN (0,8)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	8 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking, 0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking


		
		END

		----9. S4 < S1 + M1 + A1 

		IF @RuleId IN (0,9)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	9 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend		
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking


			
		END

		----10. N4 > S1 + M1 + A1 
 
		IF @RuleId IN (0,10)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	10 as RuleId, cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.minpositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverrideGame sco WITH (NOLOCK)
					ON	sco.CustId = ci.srecommend
					AND sco.SportType = cs.SportType
					AND sco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND sco.minpositiontaking > cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking

			
		END

	
		-----------------------------------------------------------------------
		----11. M4 < A4

		IF @RuleId IN (0,11)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	11 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.mpositiontaking < cs.apositiontaking 

		END

		
		----12. M4 < M3 

		IF @RuleId IN (0,12)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	12 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.mpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.mpositiontaking < cs.mpositiontaking 

			
		END
	

		----13. M4 < N3 
 
		IF @RuleId IN (0,13)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	13 as RuleId, scs.BetType, scs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustOverrideGame co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = co.SportType
					AND scs.BetType = co.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
				AND scs.mpositiontaking < co.minpositiontaking 


		END

		----14. M4 < UM2 

		IF @RuleId IN (0,14)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	14 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.mpositiontaking < cs.autompositiontaking

			
		END

		----15. M4 < UM1 

		IF @RuleId IN (0,15)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	15 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.mpositiontaking < cs.autompositiontaking

			
		END

		----16. M4 < M1 + A1 

		IF @RuleId IN (0,16)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	16 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking
			
		END

  
		----17. M3 < N3 
 
		IF @RuleId IN (0,17)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	17 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverrideGame co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.mpositiontaking < co.minpositiontaking


			
		END

		--------------------------------------------------------------------------------------------
		----18. M3 < M2 + A2 

		IF @RuleId IN (0,18)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	18 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mpositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSettingGame mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.SyncLiveCasino = 1
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend 
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking


		
		END
	
		----19. M3 < M1 + A1 

		IF @RuleId IN (0,19)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	19 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mpositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSettingGame mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.SyncLiveCasino = 1
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking


		END
 
   
		----20. N3 > M1 + A1 

		IF @RuleId IN (0,20)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	20 as RuleId, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.minpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (
							SELECT	mco.CustId, mco.SportType, mco.Bettype, mco.minpositiontaking 
							FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								 INNER JOIN CheckCustDB.dbo.CustOverrideGame mco WITH (NOLOCK)
									ON	mco.CustID = ci.CustId
										AND ci.RoleId = 3 
										AND ci.closed= 0 
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) mco
					ON	mco.CustId = ci.mrecommend
					AND mco.SportType = cs.SportType
					AND mco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND mco.minpositiontaking > cs.mpositiontaking + cs.apositiontaking

		END  
 

		----21. A4 < A2

		IF @RuleId IN (0,21)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLIve)
			SELECT	21 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.apositiontaking < cs.apositiontaking 


		END	
	

		----22. A4 < A1

		IF @RuleId IN (0,22)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	22 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSettingGame scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND scs.apositiontaking < cs.apositiontaking 

			
		END	

		----23. A2 < N2
 
		IF @RuleId IN (0,23)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	23 as RuleId, cs.BetType, cs.SportType, ci.CustId, co.CustId, cs.apositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverrideGame co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				--AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.apositiontaking < co.minpositiontaking


			
		END 
	  
		----24. N2 > A1
 
		IF @RuleId IN (0,24)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	24 as RuleId, cs.BetType, cs.SportType, co.CustId, ci.CustId, co.minpositiontaking, cs.apositiontaking, 0 
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (	SELECT co.CustId, co.SportType, co.BetType, co.minpositiontaking 
								FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustOverrideGame co WITH (NOLOCK)
											ON co.CustId = ci.CustId
											AND ci.RoleId = 2
											AND ci.Closed = 0
											AND ci.Reject = 0
											AND ci.SyncLiveCasino = 1
											AND ci.Currency NOT IN (20,27,28)	
											AND ci.srecommend = @srecommend	 
							) co
					ON	co.CustId = ci.recommend
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE   ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND co.minpositiontaking > cs.apositiontaking 


			
		END
 		---------------------------------------------------
		----Note: Do not check rule 25, 26, 27 at CustSettingGame table
		---------------------------------------------------
		---- 28. MIN(S4-M1-A1, (IS1?US1,US3)) > S1
		IF @RuleId IN (0,28)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT 28 AS RuleId, cs.BetType, cs.SportType 
				,CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
						THEN (	CASE	WHEN cs.isautopositiontaking = 1 
										THEN cs.CustId 
										ELSE mcs.CustId 
								END)
						ELSE scs.CustId
				 END 
				,cs.CustId				
				,CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
						THEN (	CASE	WHEN cs.isautopositiontaking = 1 
										THEN cs.autopositiontaking 
										ELSE mcs.autopositiontaking 
								END)
						ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking
				 END 
				,cs.spositiontaking
				,0
			FROM CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.spositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) AS scs
						ON	scs.SportType = cs.SportType
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking, cs.autopositiontaking, cs.isautopositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) AS mcs
						ON	mcs.SportType = cs.SportType
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend			
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END
				AND (cs.isautopositiontaking=1 OR mcs.isautopositiontaking=1)
				AND cs.spositiontaking < CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
												THEN (	CASE	WHEN cs.isautopositiontaking = 1 
																THEN cs.autopositiontaking 
																ELSE mcs.autopositiontaking 
														END)
												ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking
										 END 
		 

			END 
 

		---- 29. MIN (M4-A1, M3-A1,(IM1?UM1,UM2)) > M1 
		IF @RuleId IN (0,29)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT 29 AS RuleId, cs.BetType, cs.SportType 
				,CASE WHEN scs.mpositiontaking > mcs.mpositiontaking 
					  THEN	CASE WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.CustId
											ELSE acs.CustId 
											END
									   )
								 ELSE mcs.CustId
							END
					ELSE	
							CASE WHEN scs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.CustId
											ELSE acs.CustId 
										END
										)
								 ELSE scs.CustId
							END
					END
				,cs.CustId
				,CASE WHEN scs.mpositiontaking > mcs.mpositiontaking 
					  THEN	CASE WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.autompositiontaking
											ELSE acs.autompositiontaking 
									   END
									   )
								 ELSE mcs.mpositiontaking - cs.apositiontaking
							END
					ELSE	
							CASE WHEN scs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.autompositiontaking
											ELSE acs.autompositiontaking 
										END
										)
								 ELSE scs.mpositiontaking - cs.apositiontaking
							END
					END
				,cs.mpositiontaking
				,0
			FROM CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) AS scs
						ON	scs.SportType = cs.SportType
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) AS mcs
						ON	mcs.SportType = cs.SportType
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.autompositiontaking, isautompositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 2
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.SyncLiveCasino = 1
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
							) AS acs
						ON	acs.SportType = cs.SportType
							AND acs.bettype = cs.bettype
							AND acs.CustId = ci.recommend
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.SyncLiveCasino = 1
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END
				AND ( acs.isautompositiontaking = 1	OR cs.isautompositiontaking = 1 )
				AND cs.mpositiontaking < CASE WHEN scs.mpositiontaking > mcs.mpositiontaking 
											  THEN CASE  WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
														 THEN (CASE WHEN cs.isautompositiontaking = 1 
																	THEN cs.autompositiontaking
																	ELSE acs.autompositiontaking 
															   END
															   )
														 ELSE mcs.mpositiontaking - cs.apositiontaking
														 END
												ELSE	
														CASE WHEN scs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
															 THEN (CASE WHEN cs.isautompositiontaking = 1 
																		THEN cs.autompositiontaking
																		ELSE acs.autompositiontaking 
																	END
																	)
															 ELSE scs.mpositiontaking - cs.apositiontaking
															 END
												END
												

	END 
		
END
END 