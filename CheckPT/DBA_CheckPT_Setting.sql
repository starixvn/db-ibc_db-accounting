ALTER PROCEDURE [dbo].[DBA_CheckPT_Setting]
	 @srecommend INT 
	,@SportType  SMALLINT
	,@RuleId	 TINYINT = 0
AS
BEGIN 
/*
Created: 20140313@Sophia
Task: Monthly check PT setting for credit customers - sportsbook setting
DB:  DBAGE.bodb02
Revisions:

Param's Explanation:  
	@RuleId = 0 : 'all'

*/

SET NOCOUNT ON 

---- 1. S1 < 0 OR M1 < 0 OR A1 < 0

IF @RuleId IN (0,1)
BEGIN
	INSERT  INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B) 
	SELECT	1 as RuleId, dbo.F_CheckPTRule (1) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
			CASE WHEN cs.spositiontaking < 0 THEN cs.spositiontaking 
				 WHEN cs.mpositiontaking < 0 THEN cs.mpositiontaking  
				 WHEN cs.apositiontaking < 0 THEN cs.apositiontaking
			ELSE 0
			END,
			0
	FROM	dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN	dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
	WHERE	ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND (cs.spositiontaking < 0 OR cs.mpositiontaking < 0 OR cs.apositiontaking < 0)
END
	
----2. S4 > 0.9 OR M4 > 0.9 OR A4 > 0.9  

IF @RuleId IN (0,2)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	2 as RuleId, dbo.F_CheckPTRule (2) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId,
			CASE WHEN cs.spositiontaking > 0.9 THEN cs.spositiontaking 
				 WHEN cs.mpositiontaking > 0.9 THEN cs.mpositiontaking  
				 WHEN cs.apositiontaking > 0.9 THEN cs.apositiontaking	
			ELSE 0.9	
			END,
			0.9
	FROM	dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN	dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
	WHERE	ci.roleid = 4
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND (cs.spositiontaking > 0.9 OR cs.mpositiontaking > 0.9 OR cs.apositiontaking > 0.9)
END

----3. S4 < M4 

IF @RuleId IN (0,3)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	3 as RuleId, dbo.F_CheckPTRule (3) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.mpositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON cs.CustId = ci.CustId	
	WHERE ci.roleid = 4
		AND ci.srecommend = @srecommend	
		AND cs.SportType = @SportType
		AND cs.spositiontaking < cs.mpositiontaking 
	
END

----4. S4 < A4

IF @RuleId IN (0,4)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	4 as RuleId, dbo.F_CheckPTRule (4) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId	
	WHERE ci.roleid = 4
		AND ci.srecommend = @srecommend	
		AND cs.SportType = @SportType
		AND cs.spositiontaking < cs.apositiontaking  
END

----5. S4 < N4 

IF @RuleId IN (0,5)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	5 as RuleId, dbo.F_CheckPTRule (5) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.spositiontaking, co.minpositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON cs.CustId = ci.CustId	
		INNER JOIN dbo.CustOverride co WITH (NOLOCK)
			ON co.CustId=ci.CustId 
			AND co.SportType=cs.SportType
			AND co.BetType=cs.BetType
	WHERE ci.roleid = 4
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND cs.spositiontaking < co.minpositiontaking
END


----6. S4 < US3 

IF @RuleId IN (0,6)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	6 as RuleId, dbo.F_CheckPTRule (6) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking , cs.autopositiontaking 
	FROM	dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN	dbo.CustSetting cs WITH (NOLOCK)
				ON	cs.CustId = ci.CustId
		INNER JOIN	dbo.CustSetting scs WITH (NOLOCK)
				ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
	WHERE	ci.roleid = 3
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.spositiontaking < cs.autopositiontaking
END

----7. S4 < US1 

IF @RuleId IN (0,7)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	7 as RuleId, dbo.F_CheckPTRule (7) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.autopositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.spositiontaking < cs.autopositiontaking
END
	
----8. S4 < S3 + M3 

IF @RuleId IN (0,8)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	8 as RuleId, dbo.F_CheckPTRule (8) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking
	FROM	dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN	dbo.CustSetting cs WITH (NOLOCK)
				ON	cs.CustId = ci.CustId
		INNER JOIN	dbo.CustSetting scs WITH (NOLOCK)
				ON	scs.CustId = ci.srecommend
					AND scs.SportType = cs.SportType
					AND scs.BetType = cs.BetType
	WHERE ci.roleid = 3
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking
END

----9. S4 < S1 + M1 + A1 

IF @RuleId IN (0,9)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	9 as RuleId, dbo.F_CheckPTRule (9) as RuleName,  cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend		
		AND cs.SportType = @SportType
		AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking
END

----10. N4 > S1 + M1 + A1 

IF @RuleId IN (0,10)
	BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	10 as RuleId, dbo.F_CheckPTRule (10) as RuleName,  cs.BetType, cs.SportType, sco.CustId, ci.CustId, sco.minpositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustOverride sco WITH (NOLOCK)
			ON	sco.CustId = ci.srecommend
			AND sco.SportType = cs.SportType
			AND sco.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND sco.minpositiontaking > cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking
END

	
-----------------------------------------------------------------------
----11. M4 < A4

IF @RuleId IN (0,11)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	11 as RuleId, dbo.F_CheckPTRule (11) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId	
	WHERE ci.roleid = 4
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND cs.mpositiontaking < cs.apositiontaking 
END

		
----12. M4 < M3 

IF @RuleId IN (0,12)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	12 as RuleId, dbo.F_CheckPTRule (12) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.mpositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 3
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.mpositiontaking < cs.mpositiontaking 
END
	

----13. M4 < N3 

IF @RuleId IN (0,13)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	13 as RuleId, dbo.F_CheckPTRule (13) as RuleName, scs.BetType, scs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , co.minpositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustOverride co WITH (NOLOCK)
			ON	co.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = co.SportType
			AND scs.BetType = co.BetType
	WHERE ci.roleid = 3
		AND ci.srecommend = @srecommend
		AND co.SportType = @SportType
		AND scs.mpositiontaking < co.minpositiontaking 
END

----14. M4 < UM2 

IF @RuleId IN (0,14)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	14 as RuleId,  dbo.F_CheckPTRule (14) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 2
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.mpositiontaking < cs.autompositiontaking
END

----15. M4 < UM1 

IF @RuleId IN (0,15)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	15 as RuleId, dbo.F_CheckPTRule (15) as RuleName,  cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking, cs.autompositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.mpositiontaking < cs.autompositiontaking
END

----16. M4 < M1 + A1 

IF @RuleId IN (0,16)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	16 as RuleId, dbo.F_CheckPTRule (16) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.mpositiontaking , cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking
END

   
----17. M3 < N3 

IF @RuleId IN (0,17)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	17 as RuleId, dbo.F_CheckPTRule (17) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, cs.mpositiontaking, co.minpositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustOverride co WITH (NOLOCK)
			ON	co.CustId = ci.CustId
			AND co.SportType = cs.SportType
			AND co.BetType = cs.BetType
	WHERE ci.roleid = 3
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND cs.mpositiontaking < co.minpositiontaking
END

--------------------------------------------------------------------------------------------
----18. M3 < M2 + A2 

IF @RuleId IN (0,18)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	18 as RuleId,  dbo.F_CheckPTRule (18) as RuleName, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting mcs WITH (NOLOCK)
			ON	mcs.CustId = ci.mrecommend
			AND mcs.SportType = cs.SportType
			AND mcs.BetType = cs.BetType
	WHERE ci.roleid = 2
		AND ci.srecommend = @srecommend 
		AND cs.SportType = @SportType
		AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking
END
	
----19. M3 < M1 + A1 

IF @RuleId IN (0,19)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	19 as RuleId, dbo.F_CheckPTRule (19) as RuleName, cs.BetType, cs.SportType, mcs.CustId, ci.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting mcs WITH (NOLOCK)
			ON	mcs.CustId = ci.mrecommend
			AND mcs.SportType = cs.SportType
			AND mcs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend			
		AND cs.SportType = @SportType
		AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking
END
   

----20. N3 > M1 + A1 

IF @RuleId IN (0,20)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	20 as RuleId, dbo.F_CheckPTRule (20) as RuleName, cs.BetType, cs.SportType, mco.CustId, ci.CustId, mco.minpositiontaking, cs.mpositiontaking + cs.apositiontaking
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustOverride mco WITH (NOLOCK)
			ON	mco.CustId = ci.mrecommend
			AND mco.SportType = cs.SportType
			AND mco.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend	
		AND cs.SportType = @SportType
		AND mco.minpositiontaking > cs.mpositiontaking + cs.apositiontaking
END    


----21. A4 < A2

IF @RuleId IN (0,21)
BEGIN 
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	21 as RuleId, dbo.F_CheckPTRule (21) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 2
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.apositiontaking < cs.apositiontaking 
END	
	

----22. A4 < A1

IF @RuleId IN (0,22)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	22 as RuleId, dbo.F_CheckPTRule (22) as RuleName, cs.BetType, cs.SportType, scs.CustId, ci.CustId, scs.apositiontaking, cs.apositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustSetting scs WITH (NOLOCK)
			ON	scs.CustId = ci.srecommend
			AND scs.SportType = cs.SportType
			AND scs.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND scs.apositiontaking < cs.apositiontaking 
END	

----23. N2 > A2

IF @RuleId IN (0,23)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	23 as RuleId, dbo.F_CheckPTRule (23) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, co.minpositiontaking, cs.apositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustOverride co WITH (NOLOCK)
			ON	co.CustId = ci.CustId
			AND co.SportType = cs.SportType
			AND co.BetType = cs.BetType
	WHERE ci.roleid = 2
		AND ci.srecommend = @srecommend
		AND cs.SportType = @SportType
		AND co.minpositiontaking > cs.apositiontaking 
END


----24. N2 > A1

IF @RuleId IN (0,24)
BEGIN
	INSERT INTO CheckPTRule (RuleId, RuleName, BetType, SportType, CustId_A, CustId_B, A, B)
	SELECT	24 as RuleId, dbo.F_CheckPTRule (24) as RuleName, cs.BetType, cs.SportType, ci.CustId, ci.CustId, co.minpositiontaking, cs.apositiontaking 
	FROM dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN dbo.CustSetting cs WITH (NOLOCK)
			ON	cs.CustId = ci.CustId
		INNER JOIN dbo.CustOverride co WITH (NOLOCK)
			ON	co.CustId = ci.recommend
			AND co.SportType = cs.SportType
			AND co.BetType = cs.BetType
	WHERE ci.roleid = 1
		AND ci.srecommend = @srecommend			
		AND cs.SportType = @SportType
		AND co.minpositiontaking > cs.apositiontaking 
END

-----------------------------------



END
GO