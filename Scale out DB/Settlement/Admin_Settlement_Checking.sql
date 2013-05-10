



ALTER PROCEDURE [dbo].[Admin_Settlement_Checking_xtest]
(
	@matchid	INT,  
	@action		VARCHAR(10)		= 'CAL',  
	@type		VARCHAR(10)		= 'SIN', --- SIN, MIX, FLG, LVC, NUM
	@ErrCode	INT				= 0 OUTPUT,  
	@ErrMsg		NVARCHAR(200)	= '' OUTPUT,  
	@betcount	INT				= 0 OUTPUT 
)
AS
/*
	Created: 
	Task: check some condition before do settlement
	DB: DBTP, DBTrans, Licensees' DBs
 
	Revisions:
	
	
	Param's Explanation:
		- @matchid: The ID of match want to settlement
		- @action: indicate action performed
			 + CAL: Calc all
			 + CAL-HT: Calc HT bet only
			 + CAL-FT: Calc FT bet only
		- @ErrCode: if @ErrCode>0 Invalid of GoalRecord and TotalGoal
		- @ErrMsg: The message will be show if @ErrCode>0
		- @type: 
			+ SIN : single tickets ( call Admin_settlement_1)
			+ MIX : mix parlay tickets ( call Admin_Settlement_Parlay)
			+ FLG : FGLG tickets ( call Admin_Settlement_FGLG)
			+ OTH : other sports (Live Casino, Number Game)
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT	@ErrCode = 0,
			@ErrMsg = ''
			
	DECLARE @matchcode NVARCHAR(50),
			@NextAllowSettleTime DATETIME,
			@DelayTime INT

	/*
		1. check concurrency settle a match
		2. check peak hour when call Admin_Settlement_1
		3. check system busy (move bet & is calculating) when call Admin_Settlement_Parlay
		4. check system is calculating number game when call Admin_Settlement_s161_Manual
		5. check replicated tickets
		6. count tickets
	*/
	IF @@SERVERNAME NOT IN ('DBTP','DWDBG1S') 		
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WITH(NOLOCK) WHERE KeyID = 1 AND KeyValue = @matchid)
		BEGIN
			SELECT  @ErrCode = 100,
					@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END
	END

	IF @@SERVERNAME IN ('DBTRANS', 'DB206')
	BEGIN
		/* check peak-hour */
		IF @action IN ('CAL','CAL-HT','CAL-FT','UNDO') AND @type = 'SIN'
		BEGIN	
			SELECT @matchcode = matchcode 
			FROM match WITH(NOLOCK)
			WHERE matchid = @matchid
		
			IF DATENAME(WEEKDAY, GETDATE()) IN ('Saturday','Sunday') AND DATEPART(HOUR, GETDATE()) BETWEEN 7 AND 14  AND @matchcode NOT LIKE '%hedge%'
			BEGIN
				SELECT @NextAllowSettleTime = VValue FROM SystemSettings WITH(NOLOCK) WHERE VName = 'NextAllowSettleTime' 

				SELECT @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
										ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END

				IF @DelayTime > 0
				BEGIN
					SELECT	@ErrCode = 101,
							@ErrMsg = 'We prevent the frequent calculations during peak hour at weekend, please hold on and try again in ' + cast(@DelayTime as varchar(3)) + ' seconds. Thanks!'
					RETURN
				END			
			END
		END
		IF (@action IN ('CAL','REFUND-FT','REFUND-HT','REFUND') AND @type = 'MIX')  ---- check when calculate Parlay
			OR 
			(@action = 'UNDO' AND @type = 'SIN') ----- when unsettled check for nested undo parlay
		BEGIN
			--- check is move bet
			IF EXISTS(SELECT 1 FROM DB06.bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isMovingBet')
			BEGIN
				SELECT @ErrCode = 102
				SELECT @ErrMsg = 'System is not ready to calculate Mix Parlay for this match. Please try again later.'
				RETURN
			END
			
			---- check is calculating parlay
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
			BEGIN
				SELECT @ErrCode = 103
				SELECT @ErrMsg = 'Another parlay settlement is in progress, please wait a few seconds until the ongoing process has finished and try again.'
				RETURN
			END
		END
		IF @action = 'CAL' AND @type = 'NUM'
		BEGIN
			IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
			BEGIN
				SELECT @ErrCode = 104
				SELECT @ErrMsg = 'Another number game re-calculation is in progress, please wait a few seconds until the ongoing process has finished and try again.'
				RETURN
			END
		END
	END	
	
	
	/* Check replication */
	DECLARE @temp AS TABLE(db VARCHAR(10), betCNT INT, runningCNT INT, waitingCNT INT)
	DECLARE @min1 INT, @min2 INT, @max1 INT, @max2 INT, @maxWaiting INT
	
	IF @@SERVERNAME IN ('DBTRANS','DB206')
	BEGIN
		IF (@action = 'CAL-HT' AND @type = 'SIN')
		BEGIN
			INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
			SELECT 'DBTrans', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
			UNION 
			SELECT 'DB052', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB052.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB053', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB053.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB054', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB054.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB06', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB06.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
		END
		ELSE IF (@action = 'CAL-FT' AND @type = 'SIN')
		BEGIN
			INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
			SELECT 'DBTrans', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
			UNION 
			SELECT 'DB052', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB052.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB053', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB053.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB054', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB054.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
			UNION
			SELECT 'DB06', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB06.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)	
		END
		ELSE IF (@action = 'CAL' AND @type = 'SIN')
		BEGIN
			INSERT INTO @temp (db, betCNT, runningCNT, waitingCNT)
			SELECT 'DBTrans', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM bettrans WITH(NOLOCK)
			WHERE matchid = @matchid
			UNION 
			SELECT 'DB052', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB052.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid
			UNION
			SELECT 'DB053', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB053.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid
			UNION
			SELECT 'DB054', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB054.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid
			UNION
			SELECT 'DB06', 
				COUNT(transid), 
				ISNULL(SUM(CASE statusid WHEN 0 THEN 1 ELSE 0 END),0),
				ISNULL(SUM(CASE statusid WHEN 1 THEN 1 ELSE 0 END),0)
			FROM DB06.bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE matchid = @matchid
		END
		SELECT	@min1= MIN(ISNULL(betCNT,0)), 
				@max1= MAX(ISNULL(betCNT,0)), 
				@min2= MIN(ISNULL(runningCNT,0)), 
				@max2= MAX(ISNULL(runningCNT,0)), 
				@maxWaiting = MAX(ISNULL(waitingCNT,0))
		FROM @temp		

		IF @max1 > @min1 OR @max2 > @min2 OR @maxWaiting > 0
		BEGIN
			SELECT	@ErrCode = 102, 
					@ErrMsg = 'System is not ready to calculate this match. Please try again later.'    
			RETURN                  
		END
	END
	/* end check replication */

	/* count tickets */
	IF @action IN ('CAL-HT','REFUND-HT') AND @type = 'SIN'
	BEGIN
		SELECT	@betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
	END
	IF @action IN ('CAL-FT','REFUND-FT') AND @type = 'SIN'
	BEGIN
		SELECT @betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid AND bettype NOT IN(7,8,12,15,21,30,125)
	END
	IF @action IN ('CAL','REFUND') AND @type = 'SIN'
	BEGIN
		SELECT @betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid
	END
	IF @action IN ('CAL','REFUND') AND @type = 'FLG'
	BEGIN
		SELECT @betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid AND bettype = 14 
			AND RIGHT(betteam,1) <> '2'
			
	END
	IF @action IN ('CAL','REFUND') AND @type IN ('NUM')
	BEGIN
		SELECT @betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid
			
	END
	IF @action = 'MOV' AND @type = 'DAQ'
	BEGIN
		SELECT @betcount = COUNT(transid)			
		FROM bettrans WITH(NOLOCK)
		WHERE matchid = @matchid
			AND custid IN ( 50057,	--BQUS888
							103873,	--BQUSNBA
							879241,	--BQUSMLB
							1077687,--BFOS
							78761	--ITibc101
							)
	END
	
	/* end calculate total ticket */
	
	
END





