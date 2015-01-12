ALTER PROCEDURE [dbo].[Acc_CustSetting3rd_11]
	@srecommend INT	
	,@Sporttype INT
	,@Bettype INT = 0
	,@MinBet MONEY
	,@MaxBet MONEY
	,@MaxPerMatch MONEY
	,@MaxPerBall MONEY = 0
	,@ExistedMember BIT
AS
BEGIN

	SET NOCOUNT ON
	
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('Dep_Custsetting3rd','custinfo','Dep_CustSetting') AND type = 'U') <> 3
		RETURN

	--Create temp table containing all accounts belong to super, exclude fincance account
	CREATE TABLE #tblCust (custid INT, roleid INT)
	
	INSERT INTO #tblCust (custid,roleid)
	SELECT custid,roleid
	FROM custinfo WITH(NOLOCK)	
	WHERE srecommend = @srecommend
			AND mrecommend NOT IN (SELECT custid FROM custinfo WITH(NOLOCK)
									WHERE srecommend = @srecommend AND username LIKE '%Acc%' AND roleid=3)

	IF @Sporttype IN (1,2,3,5,8,10,11,99,154) --Sportbook
	BEGIN
		UPDATE Custinfo WITH(UPDLOCK,ROWLOCK)
		SET @MaxPerMatch = CASE	WHEN @Sporttype = 1		THEN maxpermatch 
								WHEN @Sporttype = 2		THEN maxpermatch2 
								WHEN @Sporttype = 3		THEN maxpermatch3
								WHEN @Sporttype = 5		THEN maxpermatch5
								WHEN @Sporttype = 8		THEN maxpermatch8
								WHEN @Sporttype = 10	THEN maxpermatch10
								WHEN @Sporttype = 11	THEN maxpermatch11
								WHEN @Sporttype = 99	THEN maxpermatch99
								WHEN @Sporttype = 99 AND @Bettype = 9 THEN MaxPerMatch99MP
								WHEN @Sporttype = 154	THEN maxpermatch154						
								END
		WHERE custid IN (SELECT custid FROM #tblCust) 
			AND 1 = CASE WHEN @ExistedMember = 0 AND roleid = 1 THEN 0 ELSE 1 END

		UPDATE cs WITH(UPDLOCK,ROWLOCK)
		SET    cs.minbet = @MinBet, cs.maxbet = @maxbet
		FROM dbo.Dep_CustSetting cs
			INNER JOIN #tblCust c ON c.custid = cs.custid
		WHERE cs.Sporttype = @Sporttype
			AND cs.bettype = CASE WHEN @Bettype = 0 THEN cs.bettype ELSE @Bettype END
			AND 1 = CASE WHEN @ExistedMember = 0 AND roleid = 1 THEN 0 ELSE 1 END
	END

	IF @Sporttype = 161 OR @Sporttype BETWEEN 180 AND 186 OR @Sporttype BETWEEN 151 AND 152 --NumberGame, Virtual sport, Racing
	BEGIN		
		UPDATE Custinfo WITH(UPDLOCK,ROWLOCK)
		SET @MaxPerMatch = CASE	--Virtual Sport
								WHEN @Sporttype = 180	THEN maxpermatch180
								WHEN @Sporttype = 181	THEN maxpermatch181
								WHEN @Sporttype = 182	THEN maxpermatch182
								WHEN @Sporttype = 183	THEN maxpermatch183
								WHEN @Sporttype = 184	THEN maxpermatch184
								WHEN @Sporttype = 185	THEN maxpermatch185
								WHEN @Sporttype = 186	THEN maxpermatch186
						
								--Racing
								WHEN @Sporttype = 151 AND @Bettype = 31 THEN MaxPerMatch151
								WHEN @Sporttype = 151 AND @Bettype = 41 THEN MaxPerMatch151_OT
								WHEN @Sporttype = 151 AND @Bettype = 51 THEN MaxPerMatch151_AU
								WHEN @Sporttype = 152 AND @Bettype = 41 THEN MaxPerMatch152_UK
								WHEN @Sporttype = 152 AND @Bettype = 51 THEN MaxPerMatch152_AU
								WHEN @Sporttype = 153 AND @Bettype = 51 THEN MaxPerMatch153_AU

								--NumberGame
								WHEN @Sporttype = 161 THEN maxpermatch161
								END,
			@MaxPerBall = CASE WHEN @Sporttype = 161 THEN MaxPerBall161 ELSE @MaxPerBall END
		WHERE custid IN (SELECT custid FROM #tblCust) 
			AND 1 = CASE WHEN @ExistedMember = 0 AND roleid = 1 THEN 0 ELSE 1 END

		UPDATE cs  WITH(UPDLOCK,ROWLOCK)
		SET    cs.minbet = @MinBet, cs.maxbet = @maxbet
		FROM dbo.Dep_CustSetting3rd cs 
			INNER JOIN #tblCust c ON c.custid = cs.custid
		WHERE cs.Sporttype = @Sporttype
			AND 1 = CASE	WHEN @Bettype = 0 THEN 1 
							WHEN @Bettype = 31 AND cs.bettype IN (31,32) THEN 1 
							WHEN @Bettype = 41 AND cs.bettype IN (41,42) THEN 1 
							WHEN @Bettype = 51 AND cs.bettype IN (51,52) THEN 1 END
			AND 1 = CASE WHEN @ExistedMember = 0 AND roleid = 1 THEN 0 ELSE 1 END
	END 

	IF @Sporttype = 202 --Keno
	BEGIN
		UPDATE cg WITH(UPDLOCK,ROWLOCK)
		SET	MinBet=@MinBet, 
			MaxBet=@Maxbet, 
			MaxPerGameType= @MaxPerMatch,
			IsDisabled=0	
		FROM CustGameType cg 
			INNER JOIN #tblCust c ON c.custid = cg.custid
		WHERE cg.GameTypeID = @Bettype - 1500
			AND 1 = CASE WHEN @ExistedMember = 0 AND roleid = 1 THEN 0 ELSE 1 END
	END
END





