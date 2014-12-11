/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_29]    Script Date: 08/27/2014 14:00:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Admin_Calculate_29    Script Date: 10/26/2012 10:37:04 AM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_29] @matchids VARCHAR(2000)
	,@matchdate SMALLDATETIME WITH RECOMPILE
AS
/*
	Created: Kathy
	Date: 20140213
	Task : Settle bettrans based on bettransm (for mix parlay)
	DB: DBTXN.bodb02
	Original: Admin_Calculate_29

	Revisions:
		
	Param's Explanation:
		+ @matchid: matchid of match to be settled
		+ @matchdate match date
*/
BEGIN
	IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN

	SET NOCOUNT ON

	DECLARE @commWinRate SMALLMONEY
		,@commLostRate SMALLMONEY
	-- GET list of concern Ticket  
	DECLARE @temp_bettrans TABLE (
		transid BIGINT
		,custid INT
		,refno BIGINT PRIMARY KEY CLUSTERED
		,apositiontaking SMALLMONEY
		,mpositiontaking SMALLMONEY
		,spositiontaking SMALLMONEY
		,playerdiscount DECIMAL(9, 8)
		,discount DECIMAL(9, 8)
		,adiscount DECIMAL(9, 8)
		,sdiscount DECIMAL(9, 8)
		,comstatus NVARCHAR(20)
		,UNIQUE (transid)
		);

	WITH refnos
	AS (
		SELECT DISTINCT refno
		FROM dbo.BetParlayDetail pd WITH (ROWLOCK)
		WHERE matchid IN (
				SELECT val
				FROM dbo.strSplit(@matchids, ',')
				)
		)
	INSERT INTO @temp_bettrans (
		transid
		,custid
		,refno
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,comstatus
		)
	SELECT transid
		,custid
		,b.refno
		,apositiontaking
		,mpositiontaking
		,spositiontaking
		,playerdiscount
		,discount
		,adiscount
		,sdiscount
		,comstatus
	FROM dbo.bettrans b WITH (ROWLOCK)
		INNER JOIN refnos t ON b.refno = t.refno
	WHERE b.matchid = 29 AND statusID NOT IN (101, 102) -- exclude void/reject
		AND betid = 0 -- main ticket of combination

	-- Get list of ParlayResult
	DECLARE @temp_parlayResult TABLE (
		refno BIGINT
		,serial INT
		,transid BIGINT
		,odds MONEY
		,modds MONEY
		,winlostdate SMALLDATETIME
		,stake MONEY
		,statusID TINYINT
		,winlost MONEY
		,awinlost MONEY
		,mwinlost MONEY
		,swinlost MONEY
		,playercomm MONEY
		,comm MONEY
		,acomm MONEY
		,scomm MONEY
		,NoRefund TINYINT
		,runningCnt TINYINT
		,IsUpdated BIT
		,-- to stored value indicate if this row been change
		UNIQUE (refno, serial)
		)

	INSERT INTO @temp_parlayResult (
		refno
		,serial
		,transid
		,winlostdate
		,stake
		,statusID
		,odds
		,modds
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		)
	SELECT pr.refno
		,pr.serial
		,pr.transid
		,winlostdate
		,stake
		,statusID
		,0
		,0
		,pr.winlost
		,0
		,0
		,0
		,0
		,0
		,0
		,0
	FROM dbo.BetParlayResult pr WITH (ROWLOCK)
		INNER JOIN @temp_bettrans t ON pr.refno = t.refno

	-- get list of max(eventdate) - using for set winlostdate of running ticket
	DECLARE @refno_maxeventdate TABLE (
		refno BIGINT PRIMARY KEY CLUSTERED
		,eventdate SMALLDATETIME
		)

	INSERT INTO @refno_maxeventdate
	SELECT pd.refno
		,MAX(ISNULL(pd.winlostdate, '01 JAN 2000'))
	FROM dbo.BetParlayDetail pd WITH (ROWLOCK)
		INNER JOIN @temp_bettrans t ON pd.refno = t.refno
	GROUP BY pd.refno

	------------------------------------------------------------  
	DECLARE @statusID TINYINT
		,@odds MONEY
	DECLARE @oldstatusID TINYINT
		,@oldwinlost MONEY
		,@winlost MONEY
		-- CALCULATE effective odds value
		;

	WITH EffectiveOdds
	AS (
		SELECT pd.refno
			,pd.serial
			,rm.eventdate
			,EXP(SUM(LOG(odds))) AS Odds
			,EXP(SUM(LOG(CASE statuswinlost
							WHEN 0 THEN 1 -- draw
							WHEN 1 THEN 1 + ((odds - 1) / 2) -- half won
							WHEN 2 THEN odds -- won
							WHEN 3 THEN 0.5 -- half lose
							WHEN 4 THEN 0.000000000001 -- lose
							ELSE 1 -- void/reject
							END))) AS mOdds
			,
			--SUM(case when pd.statusID = 101			THEN 0 ELSE 1 END) as NoReject, 
			SUM(CASE 
					WHEN pd.statusID IN (121, 103) THEN 0
					ELSE 1
					END) AS NoRefund
			,-- DONE, Refund
			SUM(CASE 
					WHEN statuswinlost = 4 THEN 1
					ELSE 0
					END) AS loseCnt
			,SUM(CASE 
					WHEN pd.statusID IN (0, 1) THEN 1
					ELSE 0
					END) AS runningCnt
		--MAX(pd.winlostdate) AS matchdate_max
		FROM dbo.BetParlayDetail pd WITH (ROWLOCK)
			INNER JOIN @temp_bettrans tb ON pd.refno = tb.refno
			INNER JOIN @refno_maxeventdate rm ON pd.refno = rm.refno
		GROUP BY pd.refno
			,pd.serial
			,rm.eventdate
		)
	-- calculate result for each sub-ticket
	UPDATE PR
	SET @oldstatusID = statusID
		,@oldwinlost = winlost
		,@statusID = statusID = CASE 
			WHEN loseCnt > 0 THEN 113 -- Lose
			WHEN m.runningCnt > 0 THEN 0 -- running
			WHEN m.NoRefund = 0 THEN 103 -- Refund
			WHEN m.modds < 1 THEN 113 -- Lose
			WHEN m.modds = 1 THEN 111 -- Draw
			WHEN m.modds > 1 THEN 112 -- Won
			ELSE - 1 -- error ??
			END
		,winlostdate = CASE @statusID
			WHEN 0 THEN m.eventdate -- running : set winlostdate = maxeventdate
			ELSE @matchdate -- settled : set winlostdate = input @matchdate
			END
		,Odds = m.Odds
		,@odds = mOdds = CASE 
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END
		,@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN '0' THEN 1
			WHEN '1' THEN 0
			ELSE 1
			END
		,@commLostRate = CASE comstatus
			WHEN '0' THEN 1
			WHEN '1' THEN 2
			ELSE 1
			END
		,@winlost = winlost = CASE 
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE PR.stake * @odds
			END
		,awinlost = CASE 
			WHEN @statusID = 113 AND loseCnt > 0 THEN PR.stake * apositiontaking
			WHEN @statusID IN (112, 113) THEN - PR.stake * apositiontaking * (@odds - 1)
			ELSE 0
			END
		,mwinlost = CASE 
			WHEN @statusID = 113 AND loseCnt > 0 THEN PR.stake * mpositiontaking
			WHEN @statusID IN (112, 113) THEN - PR.stake * mpositiontaking * (@odds - 1)
			ELSE 0
			END
		,swinlost = CASE 
			WHEN @statusID = 113 AND loseCnt > 0 THEN PR.stake * spositiontaking
			WHEN @statusID IN (112, 113) THEN - PR.stake * spositiontaking * (@odds - 1)
			ELSE 0
			END
		,playercomm = CASE @statusID
			WHEN 112 THEN @commWinRate * PR.stake * playerdiscount
			WHEN 113 THEN @commLostRate * PR.stake * playerdiscount
			ELSE 0
			END
		,comm = CASE @statusID
			WHEN 112 THEN @commWinRate * PR.stake * discount * (1 - apositiontaking)
			WHEN 113 THEN @commLostRate * PR.stake * discount * (1 - apositiontaking)
			ELSE 0
			END
		,acomm = CASE @statusID
			WHEN 112 THEN @commWinRate * PR.stake * adiscount * (1 - apositiontaking - mpositiontaking)
			WHEN 113 THEN @commLostRate * PR.stake * adiscount * (1 - apositiontaking - mpositiontaking)
			ELSE 0
			END
		,scomm = CASE @statusID
			WHEN 112 THEN @commWinRate * PR.stake * sdiscount * (1 - apositiontaking - mpositiontaking - spositiontaking)
			WHEN 113 THEN @commLostRate * PR.stake * sdiscount * (1 - apositiontaking - mpositiontaking - spositiontaking)
			ELSE 0
			END
		,NoRefund = m.NoRefund
		,runningCnt = m.runningCnt
		,IsUpdated = CASE 
			WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
			ELSE 0
			END
	FROM @temp_parlayResult PR
		INNER JOIN EffectiveOdds m ON PR.refno = m.refno AND PR.serial = m.serial
		INNER JOIN @temp_bettrans TB ON PR.refno = TB.refno

	-- update temp_ParlayResult back to betParlayResult
	UPDATE PR
	SET winlostdate = t.winlostdate
		,statusid = t.statusid
		,Odds = t.Odds
		,mOdds = t.mOdds
		,winlost = t.winlost
		,awinlost = t.awinlost
		,mwinlost = t.mwinlost
		,swinlost = t.swinlost
		,playercomm = t.playercomm
		,comm = t.comm
		,acomm = t.acomm
		,scomm = t.scomm
	FROM dbo.BetParlayResult PR
		INNER JOIN @temp_parlayResult T ON PR.refno = T.refno AND PR.serial = T.serial
	WHERE IsUpdated = 1

	IF @@SERVERNAME NOT IN ('DBTRANS', 'DB230','DB206') RETURN

	--	 below code is just for DBTRANS to process
	INSERT INTO dbo.BetParlayResultSummary (
		custid
		,refno
		,winlostdate
		,odds
		,modds
		,stake
		,runningStake
		,TicketCount
		,winlost
		,awinlost
		,mwinlost
		,swinlost
		,playercomm
		,comm
		,acomm
		,scomm
		)
	SELECT t.custid
		,pr.refno
		,pr.winlostdate
		,SUM(odds)
		,SUM(modds)
		,SUM(stake)
		,SUM(CASE statusID
				WHEN 0 THEN stake
				ELSE 0
				END)
		,COUNT(*)
		,SUM(winlost)
		,SUM(awinlost)
		,SUM(mwinlost)
		,SUM(swinlost)
		,SUM(playercomm)
		,SUM(comm)
		,SUM(acomm)
		,SUM(scomm)
	FROM dbo.BetParlayResult pr WITH (NOLOCK)
		INNER JOIN @temp_bettrans t ON pr.refno = t.refno
	GROUP BY t.custid
		,pr.refno
		,pr.winlostdate
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_29] TO [vnteam] AS [dbo]