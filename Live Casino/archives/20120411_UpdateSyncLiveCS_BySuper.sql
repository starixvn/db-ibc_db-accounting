/*
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
		@srecommend INT
	AS
	BEGIN	
		SET NOCOUNT ON
		
		IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'custinfo' AND TYPE = 'u')
			RETURN

		WHILE 1 = 1
		BEGIN

			UPDATE TOP (10000) custinfo WITH(ROWLOCK,UPDLOCK)
			SET syncLiveCasino = 1
			WHERE syncLiveCasino = 0 
				AND srecommend = @srecommend
			IF @@ROWCOUNT <> 10000
				BREAK
			WAITFOR DELAY '00:00:01'
		END

	END
*/

DECLARE @tmpSupers TABLE (ID INT IDENTITY, CustID INT)

INSERT INTO @tmpSupers (CustID)
		  SELECT 	365483	--	S5S	4	1
UNION ALL SELECT 	433306	--	S11S	4	1
UNION ALL SELECT 	409524	--	S31SD	4	1
UNION ALL SELECT 	960134	--	SVS	4	1
UNION ALL SELECT 	406808	--	TAS51S	4	1
UNION ALL SELECT 	405017	--	S56RM	4	2
UNION ALL SELECT 	405975	--	S79RM	4	2
UNION ALL SELECT 	398615	--	SCM	4	2
UNION ALL SELECT 	796555	--	SPHM	4	2
UNION ALL SELECT 	932456	--	STEM	4	2

SELECT count(1)
FROM @tmpSupers

DECLARE @SRecommend INT,
		@i INT
SELECT @i = 1

SELECT	@SRecommend = custid
FROM	@tmpSupers
WHERE	ID = @i

WHILE @i <= 10 --change later 
BEGIN

	EXEC [Acc_ExecRep_09] @Srecommend = @SRecommend
	
	SET @i = @i + 1

	SELECT @SRecommend = custid 
	FROM @tmpSupers
	WHERE id = @i
	
	WAITFOR DELAY '00:00:01'
END

