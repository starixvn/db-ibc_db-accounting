ALTER PROCEDURE [dbo].[Task_Daily3rdProductWinlost]
@Winlostdate DATETIME 
AS 
/*	Created by: Jamie 
	Date: 2012-02-21
	Task: 3rd Product Daily Winlost (Casino & NumberGame) 
	DB: DBTRANS.BODB02

	Revisions: 
		-20120411@Johnson: Add daily winlost for P2P and Live casino
		-20120503@Sophia: Edit @WinlostRM for P2P
*/
BEGIN
	SET NOCOUNT ON 
	
	IF @Winlostdate < '2012-03-01' RETURN  -- Apply Daily Summary from 1st March, 2012 
	
	DECLARE	@WLDate VARCHAR(10)
	
	SELECT	@WLDate = CONVERT(VARCHAR(10),@winlostdate,120)

	DECLARE @WinlostRM MONEY
	DECLARE	@FromCustID INT,
			@FromUsername VARCHAR(30),
			@FromRecommend INT,
			@FromMRecommend INT,
			@FromSRecommend INT,

			@ToCustID INT,
			@ToUsername VARCHAR(30),
			@ToRecommend INT,
			@ToMRecommend INT,
			@ToSRecommend INT,
			@TransDesc VARCHAR(100),
			@Creator INT 

	SELECT	@Creator = 5838421 --dbaAdmin 
 
	-- Casino Summary Base RM 
	IF EXISTS (	SELECT	TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	bettype = 71 
						AND winlostdate=@winlostdate 
						AND statusID NOT IN (101,102,121)) --Reject, Void, Done
	BEGIN 
		IF EXISTS (	SELECT TOP 1 1 
					FROM	bettrans WITH (NOLOCK) 
					WHERE	custid IN (5716654,5716676) 
							AND bettype = 21003 
							AND winlostdate = @winlostdate 
							AND matchid =0
							AND creator = @Creator --dbaAdmin 
				 )
		BEGIN
			DELETE	FROM bettrans WITH (ROWLOCK)
			WHERE	custid IN (5716654,5716676) --CasWLRM01, CasWLRM02
					AND bettype = 21003 
					AND winlostdate = @winlostdate
					AND matchid = 0 
					AND creator = @Creator --dbaAdmin 
		END

		SELECT	@WinlostRM = -ROUND(ISNULL(sum((winlost - actual_stake + swinlost + mwinlost + awinlost + scomm)*actualrate),0),2)
		FROM	bettrans WITH (NOLOCK)
		WHERE	bettype = 71 
				AND winlostdate = @winlostdate
				AND statusID NOT IN (101,102,103,121) --Reject, Void, Refund, Done
				AND ruben = 1 

		--	Username: CasWLRM01   (SIBCRM - IBCRM - ARM)   
		--	Custid:   5716654   (3259509 - 44687   - 44692)

		--	Username: CasWLRM02   (3rdSuperRM - CasRM - CasRM02)   
		--	Custid:   5716676   (1150941 - 1310039 - 5716672)


		SELECT	@FromCustID = 5716654, --Casino Daily Win/Loss 
				@FromUsername ='CasWLRM01',
				@FromRecommend =44692,
				@FromMRecommend = 44687,
				@FromSRecommend =  3259509,

				@ToCustID = 5716676,
				@ToUsername='CasWLRM02',
				@ToRecommend =5716672,
				@ToMRecommend =1310039,
				@ToSRecommend= 1150941,
				@TransDesc = 'Casino Daily Winlost - ' + @WLDate

				EXEC dbo.Task_Daily3rdProductWinlost_Add 
				@Winlostdate = @Winlostdate,
				@WinlostRM = @WinlostRM,
				@FromCustID = @FromCustID,
				@FromUsername = @FromUsername,
				@FromRecommend = @FromRecommend,
				@FromMRecommend = @FromMRecommend,
				@FromSRecommend = @FromSRecommend,
				@ToCustID = @ToCustID,
				@ToUsername = @ToUsername,
				@ToRecommend = @ToRecommend,
				@ToMRecommend = @ToMRecommend,
				@ToSRecommend = @ToSRecommend,
				@TransDesc = @TransDesc,
				@Creator = @Creator 

	END 

	--NumberGame Summary Base RM 
	IF EXISTS (	SELECT TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	bettype BETWEEN 81 AND 120 
						AND winlostdate=@winlostdate 
						AND statusID NOT IN (101,102,121)) --Reject, Void, Done
	BEGIN
		IF EXISTS (	SELECT	TOP 1 1 
					FROM	bettrans WITH (NOLOCK) 
					WHERE	custid IN (5716660,5716690) 
							AND bettype = 21003 
							AND winlostdate = @winlostdate 
							AND matchid = 0 
							AND creator = @Creator --dbaAdmin 
					)
		BEGIN
			DELETE	FROM bettrans WITH (ROWLOCK)
			WHERE	custid IN (5716660,5716690) --NUWLRM01, NUWLRM02
					AND bettype = 21003
					AND winlostdate = @winlostdate
					AND matchid = 0 
					AND creator = @Creator --dbaAdmin 
		END
	
		SELECT	@WinlostRM = -ROUND(ISNULL(sum((winlost - actual_stake + swinlost + mwinlost + awinlost + scomm)*actualrate),0),2)
		FROM	bettrans WITH (NOLOCK)
		WHERE	bettype BETWEEN 81 AND 120 
				AND winlostdate = @winlostdate
				AND statusID NOT IN (101,102,103,121) --Reject, Void, Refund, Done
				AND ruben = 1 

		-- Username: NUWLRM01   (SIBCRM - IBCRM - ARM)   
		-- Custid:   5716660   (3259509 - 44687   - 44692)

		-- Username: NUWLRM02   (3rdSuperRM - NURM - NURM02)   
		-- Custid:   5716690   (1150941 - 3121905 - 5716685)

		SELECT	@FromCustID = 5716660, --Number Game Daily Win/Loss 
				@FromUsername ='NUWLRM01',
				@FromRecommend =44692,
				@FromMRecommend = 44687,
				@FromSRecommend =  3259509,

				@ToCustID = 5716690,
				@ToUsername='NUWLRM02',
				@ToRecommend =5716685,
				@ToMRecommend =3121905,
				@ToSRecommend= 1150941,
				@TransDesc = 'NumberGame Daily Winlost - ' + @WLDate

				EXEC dbo.Task_Daily3rdProductWinlost_Add 
				@Winlostdate = @Winlostdate,
				@WinlostRM = @WinlostRM,
				@FromCustID = @FromCustID,
				@FromUsername = @FromUsername,
				@FromRecommend = @FromRecommend,
				@FromMRecommend = @FromMRecommend,
				@FromSRecommend = @FromSRecommend,
				@ToCustID = @ToCustID,
				@ToUsername = @ToUsername,
				@ToRecommend = @ToRecommend,
				@ToMRecommend = @ToMRecommend,
				@ToSRecommend = @ToSRecommend,
				@TransDesc = @TransDesc,
				@Creator = @Creator 		 
		
	END 
	
	--Racing Summary Base RM 
	IF EXISTS (	SELECT TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	bettype BETWEEN 31 AND 33 
						AND winlostdate=@winlostdate 
						AND statusID NOT IN (101,102,121)) --Reject, Void, Done
	BEGIN
		IF EXISTS (	SELECT	TOP 1 1 
					FROM	bettrans WITH (NOLOCK) 
					WHERE	custid IN (5772211,5772200) 
							AND bettype = 21003 
							AND winlostdate = @winlostdate 
							AND matchid = 0 
							AND creator = @Creator --dbaAdmin 
					)
		BEGIN
			DELETE	FROM bettrans WITH (ROWLOCK)
			WHERE	custid IN (5772211,5772200) --HRWLRM01, HRWLRM02
					AND bettype = 21003
					AND winlostdate = @winlostdate
					AND matchid = 0 
					AND creator = @Creator --dbaAdmin 
		END

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
			SELECT 101,1 --GREY-DTOTEUK
		UNION ALL
			SELECT 102,1 --GREY-DTOTEIRL
		UNION ALL
			SELECT 103,1 --GREY-TABCORP
		UNION ALL
			SELECT 201,1 --HAR-TABCORP
			
		INSERT INTO @CommSetting (MatchID, IBCFee, ToteCommWin, ToteCommPlace, ToteCommWP, ToteFee)
		SELECT	DISTINCT o.orid as matchid, t.IBCFee, p.ToteCommWin, p.ToteCommPlace, (p.ToteCommWin + p.ToteCommPlace)/2 ToteCommWP, p.ToteFee 
		FROM outright o WITH (NOLOCK)
			INNER JOIN LeagueDetail p WITH (NOLOCK) ON o.leagueID = p.leagueID and p.programDate = o.programDate
			INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
			INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
		WHERE	o.eventdate = @winlostdate 

		SELECT	@WinlostRM = ROUND(
					(
						sum((case when bettype = 33 then bm.WLIBC else -(b.winlost -b.actual_stake)*isnull(b.oddsspread,0) end)*b.actualrate) -- PTWLIBC, 
						- sum(case when cs.IBCFee = 0 then 0 else
								(case when b.bettype = 33 then bm.TOPhum 
									when b.bettype in (31,32) then b.actual_stake*(1 -b.tpositiontaking - isnull(oddsspread,0)) else 0 end)*b.actualrate*cs.ToteFee end) -- FeeDue2 ,
						+ sum((case bettype when 31 then b.actual_stake*cs.ToteCommWin*(1 - b.tpositiontaking - isnull(oddsspread,0))
											when 32 then b.actual_stake*cs.ToteCommPlace*(1 - b.tpositiontaking - isnull(oddsspread,0))
											when 33 then bm.TOPhum*cs.ToteCommWP 
											else 0 end)*b.actualrate)-- commIncomeIBC
						- sum(b.scomm*b.actualrate)
					),2)  

			FROM	bettrans b with (nolock)
					INNER JOIN @CommSetting as cs ON b.matchid = cs.matchid  
					 left join (
						select	refno,
								-sum((winlost - stake)*isnull(oddsspread,0)) WLIBC,
								sum(case when bettype = 32 and liveawayscore = 0 then 0 when bettype = 31 or (bettype = 32 and liveawayscore<>0) then stake*(1 -tpositiontaking - isnull(oddsspread,0)) else 0 end) TOPhum
						from	bettransm with (nolock)
						group by refno
					 )bm on b.transid = bm.refno 
			WHERE	b.ruben =1 
					and b.bettype in (31,32,33)
					and b.matchid >0
					and b.winlostdate = @winlostdate
					--and b.status not in ('VOID','REJECT','DONE','REFUND')
					and b.statusID not in (101,102,103,121)
	
		-- Username: HRWLRM01   (SIBCRM - IBCRM - ARM)   
		-- Custid:   5772211   (3259509 - 44687   - 44692)
		--
		-- Username: HRWLRM02   (3rdSuperRM - HRRM - HRRM02)   
		-- Custid:   5772200   (1150941 - 1150945 - 5772193)

		SELECT	@FromCustID = 5772211, --Number Game Daily Win/Loss 
				@FromUsername ='HRWLRM01',
				@FromRecommend =44692,
				@FromMRecommend = 44687,
				@FromSRecommend =  3259509,

				@ToCustID = 5772200,
				@ToUsername='HRWLRM02',
				@ToRecommend =5772193,
				@ToMRecommend =1150945,
				@ToSRecommend= 1150941,
				@TransDesc = 'Racing Daily Winlost - ' + @WLDate

				EXEC dbo.Task_Daily3rdProductWinlost_Add 
				@Winlostdate = @Winlostdate,
				@WinlostRM = @WinlostRM,
				@FromCustID = @FromCustID,
				@FromUsername = @FromUsername,
				@FromRecommend = @FromRecommend,
				@FromMRecommend = @FromMRecommend,
				@FromSRecommend = @FromSRecommend,
				@ToCustID = @ToCustID,
				@ToUsername = @ToUsername,
				@ToRecommend = @ToRecommend,
				@ToMRecommend = @ToMRecommend,
				@ToSRecommend = @ToSRecommend,
				@TransDesc = @TransDesc,
				@Creator = @Creator 		 
	END 
	
	--P2P winlost base RM
	IF EXISTS (	SELECT TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	bettype = 1000 
						AND winlostdate=@winlostdate 
						AND statusID NOT IN (101,102,121)) --Reject, Void, Done
	BEGIN
		IF EXISTS (	SELECT	TOP 1 1 
					FROM	bettrans WITH (NOLOCK) 
					WHERE	custid IN (6207399,6207367)
							AND bettype = 21003 
							AND winlostdate = @winlostdate 
							AND matchid = 0 
							AND creator = @Creator --dbaAdmin 
					)
		BEGIN
			DELETE	FROM bettrans WITH (ROWLOCK)
			WHERE	custid IN (6207399,6207367) --P2PWLRM01, P2PWLRM02
					AND bettype = 21003
					AND winlostdate = @winlostdate
					AND matchid = 0 
					AND creator = @Creator --dbaAdmin 
		END 
		
		SELECT	@WinlostRM = ROUND(ISNULL(sum( (odds-scomm)*actualrate),0),2)
		FROM	bettrans WITH (NOLOCK)
		WHERE	bettype = 1000
				AND winlostdate = @winlostdate
				AND statusID NOT IN (101,102,103,121) --Reject, Void, Refund, Done
				AND ruben = 1
		
		-- Username: P2PWLRM01   (SIBCRM - IBCRM - ARM)   
		-- Custid:   6207399   (3259509 - 44687   - 44692)

		-- Username: P2PWLRM02   (3rdSuperRM - P2PRM - P2PRM02)   
		-- Custid:   6207367   (1150941 - 6207358 - 6207364)

		SELECT	@FromCustID = 6207399, --P2P Daily Win/Loss 
				@FromUsername ='P2PWLRM01',
				@FromRecommend =44692,
				@FromMRecommend = 44687,
				@FromSRecommend =  3259509,

				@ToCustID = 6207367,
				@ToUsername='P2PWLRM02',
				@ToRecommend =6207364,
				@ToMRecommend =6207358,
				@ToSRecommend= 1150941,
				@TransDesc = 'P2P Daily Winlost - ' + @WLDate

				EXEC dbo.Task_Daily3rdProductWinlost_Add 
				@Winlostdate = @Winlostdate,
				@WinlostRM = @WinlostRM,
				@FromCustID = @FromCustID,
				@FromUsername = @FromUsername,
				@FromRecommend = @FromRecommend,
				@FromMRecommend = @FromMRecommend,
				@FromSRecommend = @FromSRecommend,
				@ToCustID = @ToCustID,
				@ToUsername = @ToUsername,
				@ToRecommend = @ToRecommend,
				@ToMRecommend = @ToMRecommend,
				@ToSRecommend = @ToSRecommend,
				@TransDesc = @TransDesc,
				@Creator = @Creator 
	END
	
	--Live casino winlost base RM
	IF EXISTS (	SELECT TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	bettype = 1101 
						AND winlostdate=@winlostdate 
						AND statusID NOT IN (101,102,121)) --Reject, Void, Done
	BEGIN
		IF EXISTS (	SELECT	TOP 1 1 
					FROM	bettrans WITH (NOLOCK) 
					WHERE	custid IN (6207397,6207352)
							AND bettype = 21003 
							AND winlostdate = @winlostdate 
							AND matchid = 0 
							AND creator = @Creator --dbaAdmin 
					)
		BEGIN
			DELETE	FROM bettrans WITH (ROWLOCK)
			WHERE	custid IN (6207397,6207352) --LCasWLRM01, LCasWLRM02
					AND bettype = 21003
					AND winlostdate = @winlostdate
					AND matchid = 0 
					AND creator = @Creator --dbaAdmin 
		END 
		
		SELECT	@WinlostRM = -ROUND(ISNULL(sum((winlost - actual_stake + swinlost + mwinlost + awinlost + scomm)*actualrate),0),2)
		FROM	bettrans WITH (NOLOCK)
		WHERE	bettype = 1101
				AND winlostdate = @winlostdate
				AND statusID NOT IN (101,102,103,121) --Reject, Void, Refund, Done
				AND ruben = 1
		
		-- Username: LCasWLRM01   (SIBCRM - IBCRM - ARM)   
		-- Custid:   6207397   (3259509 - 44687   - 44692)

		-- Username: LCasWLRM02   (3rdSuperRM - LCasRM - LCasRM02)   
		-- Custid:   6207352   (1150941 - 5937888 - 6207350)

		SELECT	@FromCustID = 6207397, --Live casino Daily Win/Loss 
				@FromUsername ='LCasWLRM01',
				@FromRecommend =44692,
				@FromMRecommend = 44687,
				@FromSRecommend =  3259509,

				@ToCustID = 6207352,
				@ToUsername='LCasWLRM02',
				@ToRecommend =6207350,
				@ToMRecommend =5937888,
				@ToSRecommend= 1150941,
				@TransDesc = 'Live casino Daily Winlost - ' + @WLDate

				EXEC dbo.Task_Daily3rdProductWinlost_Add 
				@Winlostdate = @Winlostdate,
				@WinlostRM = @WinlostRM,
				@FromCustID = @FromCustID,
				@FromUsername = @FromUsername,
				@FromRecommend = @FromRecommend,
				@FromMRecommend = @FromMRecommend,
				@FromSRecommend = @FromSRecommend,
				@ToCustID = @ToCustID,
				@ToUsername = @ToUsername,
				@ToRecommend = @ToRecommend,
				@ToMRecommend = @ToMRecommend,
				@ToSRecommend = @ToSRecommend,
				@TransDesc = @TransDesc,
				@Creator = @Creator 
	END
	
	
END

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Daily3rdProductWinlost] TO [vnteam]