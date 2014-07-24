USE [CheckResultDB]
GO

/****** Object:  StoredProcedure [dbo].[DBA_CheckPT3rd_Credit]    Script Date: 5/7/2014 10:50:14 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_CheckPT3rd_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS

BEGIN 
/*
Created: 20140313@Sophia
Task: Monthly check PT setting for credit customers - 3rd setting
DB: DBCHECK.CheckResultDB
Revisions:
	- 20140512@Sophia:  Exclude test account (currency = 20)
	- 20140722@Sophia:  Exclude test account (currency = 28, 29)
	- 20140723@Sophia: -Fix Rule 28 for Live
					   -Remove Greyhounds UK
					   -Remove deadball of NumberGame - Next High/Low 
	
Param's Explanation: 
	@RuleId = 0 : 'all'
	@RuleId IN (1->29)
	
NOTE: For Sporttypes
	161     - Number Game
	184     - Virtual Motorsports                         
	152     - Greyhounds
	153     - Harness
	186     - Virtual Tennis
	151     - Horse Racing
	185     - Virtual Cycling
	182     - Virtual Greyhounds
	180     - Virtual Soccer
	181     - Virtual Horse Racing
	183     - Virtual Speedway

*/

SET NOCOUNT ON 
		
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
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND (cs.spositiontaking < 0 OR cs.mpositiontaking < 0 OR cs.apositiontaking < 0) 
		
		
		--- Live 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	1 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
					CASE WHEN cs.slivepositiontaking < 0 THEN cs.slivepositiontaking 
						 WHEN cs.mlivepositiontaking < 0 THEN cs.mlivepositiontaking 
						 WHEN cs.alivepositiontaking < 0 THEN cs.alivepositiontaking
					ELSE 0
					END,
					0,
					1
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND (cs.slivepositiontaking < 0 OR cs.mlivepositiontaking < 0 OR cs.alivepositiontaking < 0)
		END

	
		----2. S4 > 0.9 OR M4 > 0.9 OR A4 > 0.9 

		IF @RuleId IN (0,2)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	2 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
					CASE WHEN cs.spositiontaking > 0.9 THEN cs.spositiontaking 
						 WHEN cs.mpositiontaking > 0.9 THEN cs.mpositiontaking 
						 WHEN cs.apositiontaking > 0.9 THEN cs.apositiontaking	
					ELSE 0.9	
					END,
					0.9,
					0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND (cs.spositiontaking > 0.9 OR cs.mpositiontaking > 0.9 OR cs.apositiontaking > 0.9) 

			----Live

			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	2 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
					CASE WHEN cs.slivepositiontaking > 0.9 THEN cs.slivepositiontaking 
						 WHEN cs.mlivepositiontaking > 0.9 THEN cs.mlivepositiontaking 
						 WHEN cs.alivepositiontaking > 0.9 THEN cs.alivepositiontaking	
					ELSE 0.9	
					END,
					0.9,
					1
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
			WHERE	ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND (cs.slivepositiontaking > 0.9 OR cs.mlivepositiontaking > 0.9 OR cs.alivepositiontaking > 0.9)
		END

		----3. S4 < M4 

		IF @RuleId IN (0,3)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	3 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.mpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.spositiontaking < cs.mpositiontaking 

			---Live

			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	3 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.slivepositiontaking, cs.mlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.slivepositiontaking < cs.mlivepositiontaking 
	
		END

		----4. S4 < A4

		IF @RuleId IN (0,4)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	4 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.spositiontaking < cs.apositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	4 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.slivepositiontaking, cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND cs.slivepositiontaking < cs.alivepositiontaking 
		END

		----5. S4 < N4 
 
		IF @RuleId IN (0,5)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	5 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON co.CustId=ci.CustId 
					AND co.SportType=cs.SportType
					AND co.BetType=cs.BetType
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend

				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.spositiontaking < co.minpositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	5 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.slivepositiontaking, co.minlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON cs.CustId = ci.CustId	
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON co.CustId=ci.CustId 
					AND co.SportType=cs.SportType
					AND co.BetType=cs.BetType
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND co.SportType = 161 
				AND co.BetType IN (85,86,87,89,90)
				AND cs.slivepositiontaking < co.minlivepositiontaking
		END


		----6. S4 < US3 

		IF @RuleId IN (0,6)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	6 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking , cs.autopositiontaking, 0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE	ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.spositiontaking < cs.autopositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	6 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.slivepositiontaking , cs.autolivepositiontaking, 1
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE	ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.slivepositiontaking < cs.autolivepositiontaking
		END

		----7. S4 < US1 

		IF @RuleId IN (0,7)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	7 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.autopositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.spositiontaking < cs.autopositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	7 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.slivepositiontaking, cs.autolivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.slivepositiontaking < cs.autolivepositiontaking
		END
	
		----8. S4 < S3 + M3 

		IF @RuleId IN (0,8)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	8 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking, 0
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	8 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.slivepositiontaking, cs.slivepositiontaking + cs.mlivepositiontaking, 1
			FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
						ON	cs.CustId = ci.CustId
				INNER JOIN	CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
						ON	scs.CustId = ci.srecommend
							AND scs.SportType = cs.SportType
							AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.slivepositiontaking < cs.slivepositiontaking + cs.mlivepositiontaking
		END

		----9. S4 < S1 + M1 + A1 

		IF @RuleId IN (0,9)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	9 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend		
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	9 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.slivepositiontaking, cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend		
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.slivepositiontaking < cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking
		END

		----10. N4 > S1 + M1 + A1 
 
		IF @RuleId IN (0,10)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	10 as RuleId, cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.minpositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd sco WITH (NOLOCK)
					ON	sco.CustId = ci.srecommend
					AND sco.SportType = cs.SportType
					AND sco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND sco.SportType = CASE WHEN @Sporttype = 0 then sco.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN sco.Sporttype = 152 AND sco.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN sco.SportType = 161 AND sco.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND sco.minpositiontaking > cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	10 as RuleId, cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.minlivepositiontaking, cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd sco WITH (NOLOCK)
					ON	sco.CustId = ci.srecommend
					AND sco.SportType = cs.SportType
					AND sco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND sco.SportType = 161 
				AND sco.BetType IN (85,86,87,89,90)
				AND sco.minlivepositiontaking > cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking
		END

	
		-----------------------------------------------------------------------
		----11. M4 < A4

		IF @RuleId IN (0,11)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	11 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.mpositiontaking < cs.apositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	11 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mlivepositiontaking, cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId	
			WHERE ci.roleid = 4
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND cs.mlivepositiontaking < cs.alivepositiontaking 
		END

		
		----12. M4 < M3 

		IF @RuleId IN (0,12)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	12 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.mpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.mpositiontaking < cs.mpositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	12 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mlivepositiontaking, cs.mlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.mlivepositiontaking < cs.mlivepositiontaking 
		END
	

		----13. M4 < N3 
 
		IF @RuleId IN (0,13)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	13 as RuleId, scs.BetType, scs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = co.SportType
					AND scs.BetType = co.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.mpositiontaking < co.minpositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	13 as RuleId, scs.BetType, scs.SportType, scs.CustId, ci.CustId, scs.mlivepositiontaking , co.minlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = co.SportType
					AND scs.BetType = co.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
				AND co.SportType = 161 
				AND co.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.mlivepositiontaking < co.minlivepositiontaking 
		END

		----14. M4 < UM2 

		IF @RuleId IN (0,14)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	14 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.mpositiontaking < cs.autompositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	14 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mlivepositiontaking, cs.autolivempositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.mlivepositiontaking < cs.autolivempositiontaking
		END

		----15. M4 < UM1 

		IF @RuleId IN (0,15)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	15 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.mpositiontaking < cs.autompositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	15 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mlivepositiontaking, cs.autolivempositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.mlivepositiontaking < cs.autolivempositiontaking
		END

		----16. M4 < M1 + A1 

		IF @RuleId IN (0,16)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	16 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	16 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mlivepositiontaking , cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.mlivepositiontaking < cs.mlivepositiontaking + cs.alivepositiontaking
		END

  
		----17. M3 < N3 
 
		IF @RuleId IN (0,17)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	17 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END				
				AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.mpositiontaking < co.minpositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	17 as RuleId, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mlivepositiontaking, co.minlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 3
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND co.SportType = 161 
				AND co.BetType IN (85,86,87,89,90)
				AND cs.mlivepositiontaking < co.minlivepositiontaking
		END

		--------------------------------------------------------------------------------------------
		----18. M3 < M2 + A2 

		IF @RuleId IN (0,18)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	18 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mpositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSetting3rd mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
									AND mcs.SportType = CASE WHEN @Sporttype = 0 then mcs.Sporttype  ELSE @Sporttype END
									AND (CASE WHEN mcs.Sporttype = 152 AND mcs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
									AND (CASE WHEN mcs.SportType = 161 AND mcs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend 
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1				
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking

			--Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	18 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mlivepositiontaking, cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mlivepositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSetting3rd mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
									AND mcs.SportType = 161 
									AND mcs.BetType IN (85,86,87,89,90)
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend 
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND mcs.mlivepositiontaking < cs.mlivepositiontaking + cs.alivepositiontaking
		END
	
		----19. M3 < M1 + A1 

		IF @RuleId IN (0,19)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	19 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mpositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSetting3rd mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
									AND mcs.SportType = CASE WHEN @Sporttype = 0 then mcs.Sporttype  ELSE @Sporttype END
									AND (CASE WHEN mcs.Sporttype = 152 AND mcs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
									AND (CASE WHEN mcs.SportType = 161 AND mcs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1		
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	19 as RuleId, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mlivepositiontaking, cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN ( SELECT mcs.CustId, mcs.SportType, mcs.BetType, mcs.mlivepositiontaking  
							 FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								INNER JOIN CheckCustDB.dbo.CustSetting3rd mcs WITH (NOLOCK)
									ON ci.CustId = mcs.CustId
									AND ci.RoleId = 3 
									AND ci.closed = 0 
									AND ci.Reject = 0 
									AND ci.Currency NOT IN (20,27,28)	
									AND ci.srecommend = @srecommend
									AND mcs.SportType = 161 
									AND mcs.BetType IN (85,86,87,89,90)
							) mcs
					ON	mcs.CustId = ci.mrecommend
					AND mcs.SportType = cs.SportType
					AND mcs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND mcs.mlivepositiontaking < cs.mlivepositiontaking + cs.alivepositiontaking
		END
 
   
		----20. N3 > M1 + A1 

		IF @RuleId IN (0,20)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	20 as RuleId, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.minpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (
							SELECT	mco.CustId, mco.SportType, mco.Bettype, mco.minpositiontaking 
							FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								 INNER JOIN CheckCustDB.dbo.CustOverride3rd mco WITH (NOLOCK)
									ON	mco.CustID = ci.CustId
										AND ci.RoleId = 3 
										AND ci.closed= 0 
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND mco.SportType = CASE WHEN @Sporttype = 0 then mco.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN mco.Sporttype = 152 AND mco.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN mco.SportType = 161 AND mco.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) mco
					ON	mco.CustId = ci.mrecommend
					AND mco.SportType = cs.SportType
					AND mco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND mco.minpositiontaking > cs.mpositiontaking + cs.apositiontaking

			----Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	20 as RuleId, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.minlivepositiontaking, cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (
							SELECT	mco.CustId, mco.SportType, mco.Bettype, mco.minlivepositiontaking 
							FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								 INNER JOIN CheckCustDB.dbo.CustOverride3rd mco WITH (NOLOCK)
									ON	mco.CustID = ci.CustId
										AND ci.RoleId = 3 
										AND ci.closed= 0 
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND mco.SportType = 161 
										AND mco.BetType IN (85,86,87,89,90)
							) mco
					ON	mco.CustId = ci.mrecommend
					AND mco.SportType = cs.SportType
					AND mco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND mco.minlivepositiontaking > cs.mlivepositiontaking + cs.alivepositiontaking
		END  
 

		----21. A4 < A2

		IF @RuleId IN (0,21)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLIve)
			SELECT	21 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.apositiontaking < cs.apositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLIve)
			SELECT	21 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.alivepositiontaking, cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.alivepositiontaking < cs.alivepositiontaking 
		END	
	

		----22. A4 < A1

		IF @RuleId IN (0,22)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	22 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND scs.SportType = CASE WHEN @Sporttype = 0 then scs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN scs.Sporttype = 152 AND scs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN scs.SportType = 161 AND scs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND scs.apositiontaking < cs.apositiontaking 
			
			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	22 as RuleId, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.alivepositiontaking, cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustSetting3rd scs WITH (NOLOCK)
					ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND scs.SportType = 161 
				AND scs.BetType IN (85,86,87,89,90)
				AND scs.alivepositiontaking < cs.alivepositiontaking 
		END	

		----23. A2 < N2
 
		IF @RuleId IN (0,23)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	23 as RuleId, cs.BetType, cs.SportType, ci.CustId, co.CustId, cs.apositiontaking, co.minpositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND cs.apositiontaking < co.minpositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	23 as RuleId, cs.BetType, cs.SportType, ci.CustId, co.CustId, cs.alivepositiontaking, co.minlivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
					ON	co.CustId = ci.CustId
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE ci.roleid = 2
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND co.SportType = 161 
				AND co.BetType IN (85,86,87,89,90)
				AND cs.alivepositiontaking < co.minlivepositiontaking
		END 
	 
		----24. N2 > A1
 
		IF @RuleId IN (0,24)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	24 as RuleId, cs.BetType, cs.SportType, co.CustId, ci.CustId, co.minpositiontaking, cs.apositiontaking, 0 
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (	SELECT co.CustId, co.SportType, co.BetType, co.minpositiontaking 
								FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
											ON co.CustId = ci.CustId
											AND ci.RoleId = 2
											AND ci.Closed = 0
											AND ci.Reject = 0
											AND ci.Currency NOT IN (20,27,28)	
											AND ci.srecommend = @srecommend	
											AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
											AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
											AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1 
							) co
					ON	co.CustId = ci.recommend
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE   ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND co.minpositiontaking > cs.apositiontaking 

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	24 as RuleId, cs.BetType, cs.SportType, co.CustId, ci.CustId, co.minlivepositiontaking, cs.alivepositiontaking, 1 
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (	SELECT co.CustId, co.SportType, co.BetType, co.minlivepositiontaking 
								FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
											ON co.CustId = ci.CustId
											AND ci.RoleId = 2
											AND ci.Closed = 0
											AND ci.Reject = 0
											AND ci.Currency NOT IN (20,27,28)	
											AND ci.srecommend = @srecommend	 
											AND co.SportType = 161 
											AND co.BetType IN (85,86,87,89,90)
							) co
					ON	co.CustId = ci.recommend
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE   ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND co.minlivepositiontaking > cs.alivepositiontaking 
		END
 
		---------------------------------------------------
		---- 25. L4 < S1 + M1 + A1 
		IF @RuleId IN (0,25)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	25 as RuleId, cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.maxpositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd sco WITH (NOLOCK)
					ON	sco.CustId = ci.srecommend
					AND sco.SportType = cs.SportType
					AND sco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND sco.SportType = CASE WHEN @Sporttype = 0 then sco.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN sco.Sporttype = 152 AND sco.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN sco.SportType = 161 AND sco.Bettype = 87 THEN 0 ELSE 1 END) = 1
				AND sco.maxpositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking

			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	25 as RuleId, cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.maxlivepositiontaking, cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN CheckCustDB.dbo.CustOverride3rd sco WITH (NOLOCK)
					ON	sco.CustId = ci.srecommend
					AND sco.SportType = cs.SportType
					AND sco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND sco.SportType = 161 
				AND sco.BetType IN (85,86,87,89,90)
				AND sco.maxlivepositiontaking < cs.slivepositiontaking + cs.mlivepositiontaking + cs.alivepositiontaking
		END
		 
		---- 26. L3 < M1 +A1
		IF @RuleId IN (0,26)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	26 as RuleId, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.maxpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (
							SELECT	mco.CustId, mco.SportType, mco.Bettype, mco.maxpositiontaking 
							FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								 INNER JOIN CheckCustDB.dbo.CustOverride3rd mco WITH (NOLOCK)
									ON	mco.CustID = ci.CustId
										AND ci.RoleId = 3 
										AND ci.closed= 0 
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND mco.SportType = CASE WHEN @Sporttype = 0 then mco.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN mco.Sporttype = 152 AND mco.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN mco.SportType = 161 AND mco.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) mco
					ON	mco.CustId = ci.mrecommend
					AND mco.SportType = cs.SportType
					AND mco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1				
				AND mco.maxpositiontaking < cs.mpositiontaking + cs.apositiontaking

			----Live 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	26 as RuleId, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.maxlivepositiontaking, cs.mlivepositiontaking + cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (
							SELECT	mco.CustId, mco.SportType, mco.Bettype, mco.maxlivepositiontaking 
							FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
								 INNER JOIN CheckCustDB.dbo.CustOverride3rd mco WITH (NOLOCK)
									ON	mco.CustID = ci.CustId
										AND ci.RoleId = 3 
										AND ci.closed= 0 
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND mco.SportType = 161 
										AND mco.BetType IN (85,86,87,89,90)
							) mco
					ON	mco.CustId = ci.mrecommend
					AND mco.SportType = cs.SportType
					AND mco.BetType = cs.BetType
			WHERE ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend	
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND mco.maxlivepositiontaking < cs.mlivepositiontaking + cs.alivepositiontaking
		END  
		 
		---- 27. L2 < A1 
		IF @RuleId IN (0,27)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	27 as RuleId, cs.BetType, cs.SportType, co.CustId, ci.CustId, co.maxpositiontaking, cs.apositiontaking, 0
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (	SELECT co.CustId, co.SportType, co.BetType, co.maxpositiontaking 
								FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
											ON co.CustId = ci.CustId
											AND ci.RoleId = 2
											AND ci.Closed = 0
											AND ci.Reject = 0
											AND ci.Currency NOT IN (20,27,28)	
											AND ci.srecommend = @srecommend	 
											AND co.SportType = CASE WHEN @Sporttype = 0 then co.Sporttype  ELSE @Sporttype END
											AND (CASE WHEN co.Sporttype = 152 AND co.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
											AND (CASE WHEN co.SportType = 161 AND co.Bettype = 87 THEN 0 ELSE 1 END) = 1	
							) co
					ON	co.CustId = ci.recommend
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE   ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1	 
				AND co.maxpositiontaking < cs.apositiontaking 
				 
			---Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	27 as RuleId, cs.BetType, cs.SportType, co.CustId, ci.CustId, co.maxlivepositiontaking, cs.alivepositiontaking, 1
			FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
					ON	cs.CustId = ci.CustId
				INNER JOIN (	SELECT co.CustId, co.SportType, co.BetType, co.maxlivepositiontaking 
								FROM	CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustOverride3rd co WITH (NOLOCK)
											ON co.CustId = ci.CustId
											AND ci.RoleId = 2
											AND ci.Closed = 0
											AND ci.Reject = 0
											AND ci.Currency NOT IN (20,27,28)	
											AND ci.srecommend = @srecommend	 
											AND co.SportType = 161 
											AND co.BetType IN (85,86,87,89,90)
							) co
					ON	co.CustId = ci.recommend
					AND co.SportType = cs.SportType
					AND co.BetType = cs.BetType
			WHERE   ci.roleid = 1
				AND ci.closed = 0 
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend			
				AND cs.SportType = CASE WHEN @Sporttype = 0 THEN cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND co.maxlivepositiontaking < cs.alivepositiontaking 


		END
  

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
			FROM CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.spositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) AS scs
						ON	scs.sporttype = cs.sporttype
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking, cs.autopositiontaking, cs.isautopositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend										
										AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) AS mcs
						ON	mcs.sporttype = cs.sporttype
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend			
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1

				AND (cs.isautopositiontaking=1 OR mcs.isautopositiontaking=1)
				AND cs.spositiontaking < CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
												THEN (	CASE	WHEN cs.isautopositiontaking = 1 
																THEN cs.autopositiontaking 
																ELSE mcs.autopositiontaking 
														END)
												ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking
										 END 
			
			----Live

			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT 28 AS RuleId, cs.BetType, cs.SportType 
				,CASE	WHEN scs.slivepositiontaking - cs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivepositiontaking = 1 THEN cs.autolivepositiontaking	ELSE mcs.autolivepositiontaking END)			
						THEN (	CASE	WHEN cs.isautolivepositiontaking = 1 
										THEN cs.CustId 
										ELSE mcs.CustId 
								END)
						ELSE scs.CustId
				 END 
				,cs.CustId				
				,CASE	WHEN scs.slivepositiontaking - cs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivepositiontaking = 1 THEN cs.autolivepositiontaking	ELSE mcs.autolivepositiontaking END)			
						THEN (	CASE	WHEN cs.isautolivepositiontaking = 1 
										THEN cs.autolivepositiontaking 
										ELSE mcs.autolivepositiontaking 
								END)
						ELSE scs.slivepositiontaking - cs.mlivepositiontaking - cs.alivepositiontaking
				 END 
				,cs.slivepositiontaking
				,1
			FROM CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.slivepositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = 161 
										AND cs.BetType IN (85,86,87,89,90)
							) AS scs
						ON	scs.sporttype = cs.sporttype
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mlivepositiontaking, cs.autolivepositiontaking, cs.isautolivepositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = 161 
										AND cs.BetType IN (85,86,87,89,90)
							) AS mcs
						ON	mcs.sporttype = cs.sporttype
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend			
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND (cs.isautolivepositiontaking=1 OR mcs.isautolivepositiontaking=1)
				AND cs.slivepositiontaking < CASE	WHEN scs.slivepositiontaking - cs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivepositiontaking = 1 THEN cs.autolivepositiontaking	ELSE mcs.autolivepositiontaking END)			
												THEN (	CASE	WHEN cs.isautolivepositiontaking = 1 
																THEN cs.autolivepositiontaking 
																ELSE mcs.autolivepositiontaking 
														END)
												ELSE scs.slivepositiontaking - cs.mlivepositiontaking - cs.alivepositiontaking
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
			FROM CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) AS scs
						ON	scs.sporttype = cs.sporttype
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mpositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) AS mcs
						ON	mcs.sporttype = cs.sporttype
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.autompositiontaking, isautompositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 2
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
										AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
										AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
							) AS acs
						ON	acs.sporttype = cs.sporttype
							AND acs.bettype = cs.bettype
							AND acs.CustId = ci.recommend
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND (CASE WHEN cs.Sporttype = 152 AND cs.Bettype IN (41,42) THEN 0 ELSE 1 END) = 1
				AND (CASE WHEN cs.SportType = 161 AND cs.Bettype = 87 THEN 0 ELSE 1 END) = 1
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

			------Live
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT 29 AS RuleId, cs.BetType, cs.SportType 
				,CASE WHEN scs.mlivepositiontaking > mcs.mlivepositiontaking 
					  THEN	CASE WHEN mcs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
								 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
											THEN cs.CustId
											ELSE acs.CustId 
											END
									   )
								 ELSE mcs.CustId
							END
					ELSE	
							CASE WHEN scs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
								 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
											THEN cs.CustId
											ELSE acs.CustId 
										END
										)
								 ELSE scs.CustId
							END
					END
				,cs.CustId
				,CASE WHEN scs.mlivepositiontaking > mcs.mlivepositiontaking 
					  THEN	CASE WHEN mcs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
								 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
											THEN cs.autolivempositiontaking
											ELSE acs.autolivempositiontaking 
									   END
									   )
								 ELSE mcs.mlivepositiontaking - cs.alivepositiontaking
							END
					ELSE	
							CASE WHEN scs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
								 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
											THEN cs.autolivempositiontaking
											ELSE acs.autolivempositiontaking 
										END
										)
								 ELSE scs.mlivepositiontaking - cs.alivepositiontaking
							END
					END
				,cs.mlivepositiontaking
				,1
			FROM CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
				INNER JOIN CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
						ON ci.CustId = cs.CustId
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mlivepositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 4
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = 161 
										AND cs.BetType IN (85,86,87,89,90)
							) AS scs
						ON	scs.sporttype = cs.sporttype
							AND scs.bettype = cs.bettype
							AND scs.CustId = ci.srecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.mlivepositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 3
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = 161 
										AND cs.BetType IN (85,86,87,89,90)
							) AS mcs
						ON	mcs.sporttype = cs.sporttype
							AND mcs.bettype = cs.bettype
							AND mcs.CustId = ci.mrecommend
				INNER JOIN (
								SELECT cs.CustId, cs.SportType, cs.BetType, cs.autolivempositiontaking, isautolivempositiontaking
								FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
									INNER JOIN CheckCustDB.dbo.CustSetting3rd cs WITH (NOLOCK)
									ON cs.CustId = ci.CustId
										AND ci.RoleId = 2
										AND ci.Closed = 0
										AND ci.Reject = 0
										AND ci.Currency NOT IN (20,27,28)	
										AND ci.srecommend = @srecommend
										AND cs.SportType = 161 
										AND cs.BetType IN (85,86,87,89,90)
							) AS acs
						ON	acs.sporttype = cs.sporttype
							AND acs.bettype = cs.bettype
							AND acs.CustId = ci.recommend
			WHERE ci.RoleId = 1
				AND ci.Closed = 0
				AND ci.Reject = 0
				AND ci.Currency NOT IN (20,27,28)	
				AND ci.srecommend = @srecommend
				AND cs.SportType = CASE WHEN @Sporttype = 0 then cs.Sporttype  ELSE @Sporttype END
				AND cs.SportType = 161 
				AND cs.BetType IN (85,86,87,89,90)
				AND ( acs.isautolivempositiontaking = 1	OR cs.isautolivempositiontaking = 1 )
				AND cs.mlivepositiontaking < CASE WHEN scs.mlivepositiontaking > mcs.mlivepositiontaking 
											  THEN CASE  WHEN mcs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
														 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
																	THEN cs.autolivempositiontaking
																	ELSE acs.autolivempositiontaking 
															   END
															   )
														 ELSE mcs.mlivepositiontaking - cs.alivepositiontaking
														 END
												ELSE	
														CASE WHEN scs.mlivepositiontaking - cs.alivepositiontaking > (CASE WHEN cs.isautolivempositiontaking = 1 THEN cs.autolivempositiontaking ELSE acs.autolivempositiontaking END) 
															 THEN (CASE WHEN cs.isautolivempositiontaking = 1 
																		THEN cs.autolivempositiontaking
																		ELSE acs.autolivempositiontaking 
																	END
																	)
															 ELSE scs.mlivepositiontaking - cs.alivepositiontaking
															 END
												END



	END 

 
END 


GO


