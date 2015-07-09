 

  /*
	Created by: Jamie
	UPDATE Commission 1% for Members and Listed Supers
 */
 
 
--1. Correct Commission for Members and Normal SUpers

DECLARE @tmpSuperNonCom TABLE (ID INT IDENTITY, CustID INT)

INSERT INTO @tmpSuperNonCom (CustID)
		  SELECT 	5591104
UNION ALL SELECT 	5718827
UNION ALL SELECT 	5718831
UNION ALL SELECT 	5718836
UNION ALL SELECT 	5718840
UNION ALL SELECT 	5718851
UNION ALL SELECT 	5773544
UNION ALL SELECT 	5800564
UNION ALL SELECT 	5800577
UNION ALL SELECT 	5812159
UNION ALL SELECT 	5812172
UNION ALL SELECT 	5812196
UNION ALL SELECT 	5812218
UNION ALL SELECT 	5812228
UNION ALL SELECT 	5824370
UNION ALL SELECT 	5824374
UNION ALL SELECT 	5824459
UNION ALL SELECT 	5824460
UNION ALL SELECT 	5824466
UNION ALL SELECT 	5824473
UNION ALL SELECT 	5824484
UNION ALL SELECT 	5831527
UNION ALL SELECT 	5835927
UNION ALL SELECT 	5839381
UNION ALL SELECT 	5871571
UNION ALL SELECT 	5871590
UNION ALL SELECT 	5881765
UNION ALL SELECT 	5881771
UNION ALL SELECT 	5900375
UNION ALL SELECT 	5915537
UNION ALL SELECT 	5931469
UNION ALL SELECT 	5933382
UNION ALL SELECT 	5933395
UNION ALL SELECT 	5940542
UNION ALL SELECT 	5940553
UNION ALL SELECT 	5940557
UNION ALL SELECT 	5940565
UNION ALL SELECT 	5940574
UNION ALL SELECT 	5973275
UNION ALL SELECT 	5973408

--SELECT count(1)
--FROM @tmpSuperNonCom

DECLARE @SRecommend INT,
		@i INT
SELECT @i = 1

SELECT	@SRecommend = custid
FROM	@tmpSuperNonCom
WHERE	ID = @i

WHILE @i <= 40 --change later 
BEGIN

	EXEC [Acc_ExecRep_09] @Srecommend = @SRecommend
	
	SET @i = @i + 1

	SELECT @SRecommend = custid 
	FROM @tmpSuperNonCom
	WHERE id = @i
	
	WAITFOR DELAY '00:00:01'
END


	/* ---- Script for Step 1 
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
		@srecommend INT
	AS
	BEGIN 

		IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustInfo')) RETURN


		IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustSetting3rd')) RETURN

		UPDATE CustSetting3rd WITH (UPDLOCK, ROWLOCK)
		SET	sdiscount = 0.01,
			adiscount = 0,
			discount = 0
		WHERE custid = @Srecommend 
			AND sporttype BETWEEN 151 AND 153 
			AND bettype BETWEEN 31 AND 52

		WHILE (1 = 1)
		BEGIN					
			--update member
			UPDATE TOP (20000) cs3 WITH(ROWLOCK,UPDLOCK)
			SET sdiscount = 0.01,
				adiscount = 0,
				discount = 0,
				playerdiscount =0 
			FROM custsetting3rd cs3 
				INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
			WHERE c.srecommend = @SRecommend 
				AND roleid = 1 
				AND sporttype BETWEEN 151 AND 153 
				AND bettype BETWEEN 31 and 52
				AND (sdiscount <> 0.01)
			
			IF @@ROWCOUNT < 20000 BREAK

		END
	END 
	*/


--2. Correct Commission for ONLY Members under Normal SUpers

DECLARE @tmpSuperNonCom TABLE (ID INT IDENTITY, CustID INT)

INSERT INTO @tmpSuperNonCom (CustID)
		  SELECT 	3675859
UNION ALL SELECT 	3161673

--
--SELECT count(1)
--FROM @tmpSuperNonCom

DECLARE @SRecommend INT,
		@i INT
SELECT @i = 1

SELECT	@SRecommend = custid
FROM	@tmpSuperNonCom
WHERE	ID = @i

WHILE @i <= 2 --change later 
BEGIN

	EXEC [Acc_ExecRep_09] @Srecommend = @SRecommend
	
	SET @i = @i + 1

	SELECT @SRecommend = custid 
	FROM @tmpSuperNonCom
	WHERE id = @i
	
	WAITFOR DELAY '00:00:01'
END

	/* ---- Script for Step 2 

	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
		@srecommend INT
	AS

	IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustInfo')) RETURN


	IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustSetting3rd')) RETURN

	WHILE (1 = 1)
	BEGIN					
		--update member
		UPDATE TOP (20000) cs3 WITH(ROWLOCK,UPDLOCK)
		SET sdiscount = 0.01,
			adiscount = 0
		FROM custsetting3rd cs3 
			INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
		WHERE c.srecommend = @SRecommend 
			AND roleid = 1 
			AND sporttype BETWEEN 151 AND 153 
			AND bettype BETWEEN 31 and 52
			AND (sdiscount <> 0.01 )
		
		IF @@ROWCOUNT < 20000 BREAK

	END

	*/

--3. Correct commission for DIRECT MASTER 

DECLARE @tmpMaster TABLE (ID INT IDENTITY, CustID INT)

INSERT INTO @tmpMaster (CustID)
SELECT 	5875579  --check total Masters 

DECLARE @mRecommend INT,
		@i INT
SELECT @i = 1

SELECT	@mRecommend = custid
FROM	@tmpMaster
WHERE	ID = @i

WHILE @i <= 1 --change later 
BEGIN

	EXEC [Acc_ExecRep_09] @mRecommend = @mRecommend
	
	SET @i = @i + 1

	SELECT @mRecommend = custid 
	FROM @tmpMaster
	WHERE id = @i
	
	WAITFOR DELAY '00:00:01'
END


		/* ----Script for Step 3
		ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
			@mRecommend INT
		AS
		BEGIN

			IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustInfo')) RETURN


			IF NOT EXISTS (SELECT 1 FROM dbo.sysobjects WHERE name in ('CustSetting3rd')) RETURN

			-- update master
			UPDATE custsetting3rd WITH(ROWLOCK,UPDLOCK)
			SET adiscount = 0.01
			WHERE custID = @mRecommend 
				AND sporttype BETWEEN 151 AND 153 
				AND bettype BETWEEN 31 and 52

			WHILE (1 = 1)
			BEGIN					
				--update member
				UPDATE TOP (20000) cs3 WITH(ROWLOCK,UPDLOCK)
				SET sdiscount = 0.01,
					adiscount = 0.01
				FROM custsetting3rd cs3 
					INNER JOIN custinfo c WITH(NOLOCK) ON cs3.custid = c.custid
				WHERE	c.mrecommend = @mRecommend 
						AND roleid = 1 
						AND sporttype BETWEEN 151 AND 153 
						AND bettype BETWEEN 31 and 52
					AND ( sdiscount <> 0.01 OR adiscount <> 0.01)
				
				IF @@ROWCOUNT < 20000 BREAK

			END
		END
		*/
