ALTER PROCEDURE [dbo].[Task_ResetWinning_3rdParty]
(
	@winlostdate DATETIME
)
AS
/*
	Created: 20120729@Lukas
	Task: Auto reset racing amount due to Partners. Applied from 1st Aug, 2012 onwards 
	DB: DBTXN/BODB02
	
	Revisions:
		- 20120821@Sophia: Auto reset Poker amount due to Partners
		- 20130618@Johnson: Add NSW racing's pools from AUST
	Parameters Explanation:
		 @winlostdate >= '2012-08-01' : Apply For Racing Products
		 @winlostdate >= '2012-09-01' : Apply For Poker Products
		 
*/
BEGIN

	SET NOCOUNT ON 
	
	DECLARE	@creator		INT,
			@custID			INT,		-- 3rd Party CustID 
			@Due2Partner	MONEY,		-- Amount Due to Partners 
			@transDesc		VARCHAR(300)			 

	
	SELECT	@creator = 5838421	-- dbaAdmin 

--*************************** Racing Products ****************************--
	IF EXISTS (	SELECT TOP 1 1 
					FROM	Bettrans WITH (NOLOCK) 
					WHERE	winlostdate = @winlostdate
							AND bettype BETWEEN 31 AND 33
							AND statusID NOT IN (101,102,103,121)
							AND ruben = 1 
				  )
	BEGIN

		SELECT	@custID	 = 7723121	-- VNM-Racing Partners MYR
		
			
		IF EXISTS (	SELECT 1 
					FROM	bettrans WITH(NOLOCK) 
					WHERE	winlostdate = @winlostdate 
							AND custid = @custID  --- VNM-Racing Partners MYR 
							AND creator = @creator )
		BEGIN
			DELETE FROM bettrans WITH(ROWLOCK,UPDLOCK)
			WHERE	winlostdate = @winlostdate 
					AND custid = @custID  --- VNM-Racing Partners MYR 
					AND creator = @creator
		END
			
		DECLARE @IBCRacingWinlost	MONEY,
				@Racingwinlost		MONEY
				
		DECLARE @tmpIBCFee TABLE(partnerID int,IBCFee bit)
			
		DECLARE @CommSetting TABLE
		(	MatchID			int,
			IBCFee			bit,
			ToteCommWin		smallmoney,
			ToteCommPlace	smallmoney,
			ToteCommWP		smallmoney,
			ToteFee			smallmoney	
		)
		
		INSERT INTO @tmpIBCFee (partnerID, IBCFee)
			SELECT 1,1 --RACE-PHU
		UNION ALL
			SELECT 2,0 --RACE-ATRUK
		UNION ALL
			SELECT 3,0 --RACE-ATRIRL
		UNION ALL
			SELECT 4,0 --RACE-RUK
		UNION ALL
			SELECT 5,1 --RACE-TABCORP
		UNION ALL
			SELECT 6,1 --RACE-TABCORPNSW
		UNION ALL
			SELECT 101,1 --GREY-DTOTEUK
		UNION ALL
			SELECT 102,1 --GREY-DTOTEIRL
		UNION ALL
			SELECT 103,1 --GREY-TABCORP
		UNION ALL
			SELECT 104,1 --GREY-TABCORPNSW
		UNION ALL
			SELECT 201,1 --HAR-TABCORP
		UNION ALL
			SELECT 202,1 --HAR-TABCORPNSW
			
		INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
		SELECT	DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee 
		FROM outright o WITH (NOLOCK)
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID and p.programDate = o.programDate
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
		WHERE	o.eventdate = @winlostdate 	
		
		--Get IBC racing winlost (net)
		SELECT	@IBCRacingWinlost = ROUND(
				-(sum((case when bettype = 33 then bm.WLIBC else -(b.winlost -b.actual_stake)*isnull(b.oddsspread,0) end)*b.actualrate) 
				- sum(case when cs.IBCFee = 0 then 0 else (case when b.bettype = 33 then bm.TOPhum when bettype in (31,32) then b.actual_stake*(1 - b.tpositiontaking - isnull(b.oddsspread,0) ) else 0 end)*b.actualrate*cs.ToteFee end) --FeeDue2 
				+ sum((case bettype when 31 then b.actual_stake*cs.ToteCommWin*(1 - b.tpositiontaking - isnull(oddsspread,0))
									when 32 then b.actual_stake*cs.ToteCommPlace*(1 - b.tpositiontaking - isnull(oddsspread,0))
									when 33 then bm.TOPhum*cs.ToteCommWP 
									else 0 end)*b.actualrate) --commIncomeIBC
				- sum(b.scomm*b.actualrate)),2)

				
		FROM	bettrans b with (nolock)
				INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid  
				 left join (
					select	refno,
							sum(case when bettype = 32 and liveawayscore = 0 then 0 else stake*isnull(oddsspread,0) end) TOIBC,
							-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,
							sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore <>0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum
					from	bettransm with (nolock)
					group by refno
				 )bm on b.transid = bm.refno 
		WHERE	b.ruben =1 
				and b.bettype in (31,32,33)
				and b.matchid >0
				and b.winlostdate = @winlostdate			
				and b.statusID NOT IN (101,102,103,121)		
		
		
		-- Get racing winlost (gross)
		SELECT @Racingwinlost = SUM((winlost-actual_stake + awinlost + mwinlost + swinlost + scomm)*actualrate)
		FROM bettrans WITH(NOLOCK)
		WHERE winlostdate = @winlostdate
			AND bettype BETWEEN 31 AND 33
			AND statusID NOT IN (101,102,103,121)
			AND ruben = 1
			AND matchid > 0
			
		SET @Due2Partner = -Round(@Racingwinlost - @IBCRacingWinlost,2)	
		SET @transDesc = 'Automation Racing Due to Partners - date ' + CONVERT(VARCHAR(2),DATEPART(DAY,@winlostdate))
		
		IF @Due2Partner = 0  RETURN 
		EXEC Task_ResetWinning_3rdParty_Add
			@winlostdate = @winlostdate,
			@custid = @custID,  --- VNM-Racing Partners MYR 
			@amount = @Due2Partner,
			@transdesc = @transDesc,
			@creator = @creator,  --- dbaAdmin
			@IP = ''
	END
--*************************** End of Racing Products ****************************--	   

--*************************** Poker Products ************************************--

	IF @winlostdate < '2012-09-01'
	RETURN
		
	IF EXISTS (	SELECT TOP 1 1 
					FROM	Bettrans WITH (NOLOCK) 
					WHERE	winlostdate = @winlostdate
							AND bettype = 1000
							AND statusID NOT IN (101,102,103,121)
							AND ruben = 1 
				  )
	BEGIN
					
		SELECT	@custID	 = 7901668	-- VNM-P2P Partners MYR
				
		IF EXISTS (	SELECT 1 
					FROM	bettrans WITH(NOLOCK) 
					WHERE	winlostdate = @winlostdate 
							AND custid = @custID  --- VNM-P2P Partners MYR
							AND creator = @creator )
		BEGIN
			DELETE FROM bettrans WITH(ROWLOCK,UPDLOCK)
			WHERE	winlostdate = @winlostdate 
					AND custid = @custID  --- VNM-P2P Partners MYR
					AND creator = @creator
		END
			
		DECLARE @IBCPokerWinlost	MONEY,
				@Pokerwinlost		MONEY
	
		--Get IBC Poker winlost (net)
		SELECT	@IBCPokerWinlost =ISNULL(SUM(-(odds-scomm)*actualrate),0)
		FROM	bettrans b WITH(NOLOCK)
		WHERE	b.ruben =1 
				and b.bettype = 1000
				and b.matchid = 1000
				and b.winlostdate = @winlostdate			
				and b.statusID NOT IN (101,102,103,121)		
		
		
		-- Get Poker winlost (gross)
		SELECT @Pokerwinlost = ISNULL(SUM((winlost-actual_stake+scomm)*actualrate),0)
		FROM bettrans WITH(NOLOCK)
		WHERE ruben = 1			
			AND bettype = 1000
			AND matchid = 1000
			AND winlostdate = @winlostdate
			AND statusID NOT IN (101,102,103,121)

			
		SET @Due2Partner = -Round(@Pokerwinlost - @IBCPokerWinlost,2)	
		SET @transDesc = 'Automation Poker Due to Partners - date ' + CONVERT(VARCHAR(2),DATEPART(DAY,@winlostdate))
		
		IF @Due2Partner = 0  RETURN 
		EXEC Task_ResetWinning_3rdParty_Add
			@winlostdate = @winlostdate,
			@custid = @custID,  --VNM-P2P Partners MYR
			@amount = @Due2Partner,
			@transdesc = @transDesc,
			@creator = @creator,  --- dbaAdmin
			@IP = ''
	END
--*************************** End of Poker Products ****************************--	   


     
END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_3rdParty] TO [vnteam] AS [dbo]