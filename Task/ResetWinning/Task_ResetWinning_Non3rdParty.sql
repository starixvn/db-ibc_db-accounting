SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_ResetWinning_Non3rdParty]
	@fromdate datetime,
	@todate   datetime,
	@mode     tinyint = 0,
	@creator  INT = 5838421,
	@ip       VARCHAR(20) = '',
	@ErrCode  INT = 0 output,
    @ErrMsg   VARCHAR(100) = '' output
AS
/*	
	Created: 20140619@Logan
	Task: Reset Winning - Reset Company Balance for a period
	DB: DBACC.BODB02
	
	Revision:
		- 20140619@Logan: Initial version - Redmine: 17345
		
	Param Explanation:
	    @mode:  0 _ view report
	            1 _ reset balance
	            
	    @ErrCode: 0 _ Success
	              1 _ Error
	              2 _ Already reset
*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @dummyBalance TABLE
	(   
	    winlostdate datetime,
	    seq         tinyint,
	    custid      int,
	    product     varchar(50)
    )
    
    declare @reset table
    (
        winlostdate datetime,
        product     varchar(50),
        winlost     money,
        reset       money,
        latestreset money,
        seq         tinyint
    )

    declare @wldate datetime = @todate,
            @seq    smallint = 0,
            @maxseq smallint = 0,
            @uus    tinyint  = 0
            
    SELECT @uus = c.currency
      FROM custInfo c WITH(NOLOCK)
INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
     WHERE c.custid = (SELECT custid
                         FROM bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
                        WHERE seq = 14
                      )

    select @maxseq = MAX(seq)
      from bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)

    while (@wldate >= @fromdate)
    begin
        while @seq <= @maxseq
        begin
            insert into @dummyBalance
            select @wldate,
	               seq,
	               custid,
	               product
	          from bodb_ACC.dbo.Acc_DWLList WITH(NOLOCK)
	         where seq = @seq

	        set @seq = @seq + 1
        end

        select @wldate = DATEADD(DAY, -1, @wldate),
               @seq = 0
    end

    select @maxseq = 0, @seq = 1

	DECLARE @Winning TABLE 
	(
	    winlostdate datetime,
		product     varchar(50),
		winlost     money
	)
	
	CREATE TABLE #bettranstmp
	(
	    winlostdate     datetime, 
	    custid          int,
	    bettype         int,
	    liveindicator   bit,
	    winlost         money
	)

	insert into #bettranstmp
	select b.winlostdate,
	       CASE
	         WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 THEN d.custid
	         ELSE -1
	       END AS custid,
	       b.bettype,
	       b.liveindicator,
	       SUM(ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                                  WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                                  ELSE actualrate
	                                                                                END), 0)) as winlost
	  from bettrans b WITH(READPAST, INDEX = IX_Report)
 LEFT JOIN bodb_ACC.dbo.Acc_DWLList d with(nolock) on b.custid = d.custid	  
	 WHERE 1 = 1
       AND winlostdate between @fromdate and @todate
	   AND ruben = 1
	   AND statusid NOT IN (101, 102, 103, 121)
	   AND ISNULL((ISNULL(winlost, 0) - ISNULL(actual_stake, 0) + ISNULL(awinlost, 0) +
	               ISNULL(mwinlost, 0) + ISNULL(swinlost, 0) + ISNULL(scomm, 0)) * (CASE
	                                                                                  WHEN ISNULL(d.custid, -1) <> -1 AND b.bettype IN (21001, 21002) THEN 1
	                                                                                  ELSE actualrate
	                                                                                END), 0) <> 0
       AND (@uus = 20 AND b.custid NOT IN (6911909, 6911911, 6911913, 6911914, 6911916,
                                           6911917, 6911918, 6911919, 6911920, 6913085,
                                           8158305, 14054918
                                          )
         OR @uus <> 20)
  GROUP BY b.winlostdate, CASE WHEN b.bettype IN (21001, 21002) AND ISNULL(d.custid, -1) <> - 1 then d.custid ELSE -1 END,
	 b.bettype, b.liveindicator

    CREATE NONCLUSTERED INDEX #IX_bettranstmp ON #bettranstmp(custid, winlostdate, bettype)

    DECLARE @RB_LineTotal money,
            @Poker_LineTotal money

	/*calculating racing net income*/
	--insert company's comm setting that is recieved from Phumelela into this temp table.
	DECLARE @tmpIBCFee TABLE
	(
	    partnerID int,
	    IBCFee    bit
    )

	DECLARE @CommSetting TABLE
	(
	    winlostdate   datetime,
	    MatchID		  int,
		IBCFee		  bit,
		ToteCommWin	  smallmoney,
		ToteCommPlace smallmoney,
		ToteCommWP	  smallmoney,
		ToteFee		  smallmoney	
	)

	INSERT INTO @tmpIBCFee(partnerID, IBCFee)
    SELECT 1, 1 --RACE-PHU
	 UNION ALL
	SELECT 2, 0 --RACE-ATRUK
	 UNION ALL
	SELECT 3, 0 --RACE-ATRIRL
	 UNION ALL
    SELECT 4, 0 --RACE-RUK
	 UNION ALL
	SELECT 5, 1 --RACE-TABCORP
	 UNION ALL
	SELECT 6, 1 --RACE-TABCORPNSW
	 UNION ALL
	SELECT 101, 1 --GREY-DTOTEUK
	 UNION ALL
	SELECT 102, 1 --GREY-DTOTEIRL
	 UNION ALL
	SELECT 103, 1 --GREY-TABCORP
	 UNION ALL
	SELECT 104, 1 --GREY-TABCORPNSW
	 UNION ALL
	SELECT 201, 1 --HAR-TABCORP
	 UNION ALL
	SELECT 202, 1 --HAR-TABCORPNSW

	INSERT INTO @CommSetting
	(
	    winlostdate,
	    MatchID,
	    IBCFee,
	    ToteCommWin,
	    ToteCommPlace,
	    ToteCommWP,
	    ToteFee
    )
	SELECT o.eventdate,
	       o.orid,
	       t.IBCFee,
	       p.ToteCommWin,
	       p.ToteCommPlace,
	       (p.ToteCommWin + p.ToteCommPlace) / 2 as ToteCommWP,
	       p.ToteFee
	  FROM outright o WITH(NOLOCK)
INNER JOIN LeagueDetail p WITH(NOLOCK) ON o.leagueID = p.LeagueID AND p.programDate = o.programDate
INNER JOIN RacingMeeting r WITH(NOLOCK) ON r.meetingID = p.leagueid
INNER JOIN @tmpIBCFee t ON r.partnerID = t.partnerID
	 WHERE o.eventdate between @fromdate and @todate


    INSERT INTO @Winning(winlostdate, product, winlost)
	---- sportsbook live & non-live
	SELECT winlostdate,
	       CASE
	         WHEN liveindicator = 1 THEN 'SPL'
			 WHEN liveindicator = 0 THEN 'SPNL'
		   END Product,
		   ISNULL(SUM(winlost), 0) winlost
	  FROM #bettranstmp
	 WHERE (bettype <= 999 AND bettype NOT IN (9, 10, 29, 31, 32, 33, 71, 72, 73) AND bettype NOT BETWEEN 81 AND 120)
		or bettype between 1301 and 1334		
  GROUP BY liveindicator, winlostdate

  	 UNION ALL

	SELECT winlostdate,
	       CASE
	     	 WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'	
			 WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN (71, 72) THEN 'Casino'
			 WHEN bettype = 73 THEN 'Bingo'
			 WHEN bettype = 1000 THEN 'Poker gross income'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 when bettype BETWEEN 1501 AND 1599 THEN 'Keno'
		   END AS Product,
		   ISNULL(SUM(winlost), 0) as winlost
	  FROM #bettranstmp
	 WHERE (bettype BETWEEN 1101 AND 1199
			OR bettype BETWEEN 31 AND 33
			OR bettype BETWEEN 80 AND 120
			OR bettype IN (71, 72, 73, 10, 1000, 9, 29)
			OR bettype BETWEEN 1201 AND 1299
			OR bettype BETWEEN 1501 AND 1599
		   )
  GROUP BY CASE
	         WHEN bettype BETWEEN 31 AND 33 THEN 'Racing gross income'
			 WHEN bettype BETWEEN 81 AND 120 THEN 'Number Game'
			 WHEN bettype BETWEEN 1101 AND 1199 THEN 'Live Casino'
			 WHEN bettype IN(71, 72) THEN 'Casino'
			 WHEN bettype = 73 THEN 'Bingo'
			 WHEN bettype = 1000 THEN 'Poker gross income'
			 WHEN bettype = 10 THEN 'Outright'
			 WHEN bettype IN (9, 29) THEN 'Parlay'
			 WHEN bettype BETWEEN 1201 AND 1299 THEN 'Virtual Sports'
			 when bettype BETWEEN 1501 AND 1599 THEN 'Keno'
		   END, winlostdate

     UNION ALL
    
    SELECT winlostdate,
           'Total Balance',
           ISNULL(SUM(winlost), 0) winlost
      FROM #bettranstmp
     WHERE custid NOT IN (SELECT custid FROM @dummyBalance WHERE custid <> 0)
  GROUP BY winlostdate

    ---- get Racing line total
	insert into @Winning(winlostdate, product, winlost)
	SELECT b.winlostdate,
	       'Racing',
	       -(SUM((CASE 
	                WHEN bettype = 33 THEN bm.WLIBC
	                ELSE -(b.winlost - b.actual_stake) * ISNULL(b.oddsspread, 0)
	              END) * b.actualrate)
		   - SUM(CASE
			       WHEN cs.IBCFee = 0 THEN 0
				   ELSE (CASE
						   WHEN b.bettype = 33 THEN bm.TOPhum
						   WHEN bettype in (31, 32) THEN b.actual_stake * (1 - b.tpositiontaking - ISNULL(b.oddsspread, 0))
						   ELSE 0 
						 END) * b.actualrate * cs.ToteFee
			     END) --FeeDue2 
		   + SUM((CASE bettype 
					WHEN 31 THEN b.actual_stake * cs.ToteCommWin * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
					WHEN 32 THEN b.actual_stake * cs.ToteCommPlace * (1 - b.tpositiontaking - ISNULL(oddsspread, 0))
					WHEN 33 THEN bm.TOPhum * cs.ToteCommWP  
					ELSE 0
				  END) * b.actualrate) --commIncomeIBC
		   - SUM(b.scomm*b.actualrate))
	  FROM bettrans b WITH(NOLOCK)
inner join @CommSetting AS cs ON b.matchid = cs.matchid and b.winlostdate = cs.winlostdate
 left join (SELECT refno,
				   SUM(CASE
				    WHEN bettype = 32 and liveawayscore = 0 THEN 0
				         ELSE stake * ISNULL(oddsspread, 0)
				       END) TOIBC,
				   -SUM((winlost - stake) * ISNULL(oddsspread, 0)) WLIBC,
				   SUM(CASE
				         WHEN bettype = 32 and liveawayscore = 0 THEN 0
				         WHEN bettype = 31 or (bettype = 32 and liveawayscore <> 0) THEN stake * (1 -tpositiontaking - ISNULL(oddsspread, 0))
				         ELSE 0
				       END) TOPhum
  			  FROM bettransm WITH(NOLOCK)
		  GROUP BY refno
		   ) bm ON b.transid = bm.refno
	 WHERE 1 = 1
	   AND b.ruben = 1
	   AND b.bettype in (31, 32, 33)
	   AND b.matchid > 0
	   AND statusid NOT IN (101, 102, 103, 121)
	   AND b.winlostdate between @fromdate and @todate
  group by b.winlostdate
	/*end calculating racing net income*/
	
	/*calculating poker net income*/
	insert into @Winning(winlostdate, product, winlost)
	select b.winlostdate,
	       'Poker',
	       ISNULL(SUM(-(odds - scomm) * actualrate), 0)  
	  FROM bettrans b WITH(NOLOCK)
	 WHERE 1 = 1
	   AND b.ruben = 1
	   AND b.bettype = 1000
	   AND b.matchid = 1000
	   AND statusid NOT IN (101, 102, 103, 121)
	   AND b.winlostdate between @fromdate and @todate
  group by b.winlostdate
	/*end calculating racing net income*/

	UPDATE w1
       SET w1.product = 'Racing (Due to Partners)',
		   w1.winlost = w1.winlost - w2.winlost
	  from @Winning w1
inner join @Winning w2 on w1.winlostdate = w2.winlostdate
	 WHERE w1.product = 'Racing gross income' 
	   and w2.product = 'Racing'

	UPDATE w1
	   SET w1.product = 'Poker (Due to Partners)',
		   w1.winlost = w1.winlost - w2.winlost
      from @Winning w1
inner join @Winning w2 on w1.winlostdate = w2.winlostdate
	 where w1.product = 'Poker gross income'
	   and w2.product = 'Poker'
	
    --view report
    if (@mode = 0)
    begin
	    ----- calculate reset
	    ;WITH rs AS
	    (
		    SELECT dm.winlostdate,
		           dm.Product,
		           ISNULL(SUM(b.winlost), 0) AS reset
		      FROM #bettranstmp b
	    INNER JOIN @dummyBalance dm ON b.custid = dm.custid and b.winlostdate = dm.winlostdate
	 	     WHERE bettype > 20000
		  GROUP BY dm.winlostdate, dm.product
	    )
	    SELECT dm.winlostdate,
	           dm.product,
	           ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
	           CASE dm.product
	             WHEN 'Total Balance' then 0
	             ELSE ROUND(ISNULL(rs.reset, 0), 2)
	           END AS reset
	      FROM @Winning w
    FULL OUTER JOIN rs rs ON w.product = rs.product and w.winlostdate = rs.winlostdate
	RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product) and dm.winlostdate = w.winlostdate
	  order BY dm.winlostdate desc, dm.seq desc

        drop table #bettranstmp
        
        return
	END
	--reset balance
	ELSE IF (@mode = 1)
	begin
	    ;WITH rs AS
	    (
		    SELECT dm.winlostdate,
		           dm.Product,
		           ISNULL(SUM(b.winlost), 0) AS reset
		      FROM #bettranstmp b
	    INNER JOIN @dummyBalance dm ON b.custid = dm.custid and b.winlostdate = dm.winlostdate
	 	     WHERE b.bettype > 20000
		  GROUP BY dm.winlostdate, dm.product
	    )
        insert into @reset(winlostdate, product, winlost, reset, latestreset, seq)
	    SELECT dm.winlostdate,
	           dm.product,
	           ROUND(ISNULL(w.winlost, 0), 2) AS winlost,
	           ROUND(ISNULL(rs.reset, 0), 2) AS reset,
	           CASE
	             WHEN dm.seq IN (0, 4, 6) THEN 0
	             ELSE ROUND(-ISNULL(w.winlost, 0) - ISNULL(rs.reset, 0), 2)
	           END,
	           ROW_NUMBER() over (order by dm.winlostdate DESC, dm.seq DESC)
	      FROM @winning w	
    FULL OUTER JOIN rs rs ON w.product = rs.product and w.winlostdate = rs.winlostdate
	     RIGHT JOIN @dummyBalance dm ON dm.product = ISNULL(w.product, rs.product) and dm.winlostdate = w.winlostdate

        drop table #bettranstmp

        declare @variance     money = 0,
                @winlostdate  datetime,
                @custid       int,
                @resetCount   tinyint = 0,
                @transDesc    varchar(300)= ''--,
                --@creator      int = 5838421,--dbaAdmin
                
        SELECT @maxseq = MAX(r.seq),
               @seq = 1,
               @resetCount = ISNULL(SUM(CASE
                                          WHEN -(ISNULL(r.winlost, 0)) - ISNULL(r.reset, 0) <> 0 AND r.seq NOT IN (9, 11) THEN 1
                                          ELSE 0
                                        END), 0)
          FROM @reset r
         WHERE seq < 15

        IF (@resetCount = 0)
        BEGIN
            SELECT @ErrMsg = 'No products need to reset winning!',
                   @ErrCode = 2

            RETURN
        END

        WHILE (@seq <= @maxseq)
        BEGIN
            SET @variance = 0

            SELECT @winlostdate = r.winlostdate,
                   @variance = r.latestreset,
                   @custid = d.custid
              FROM @reset r
        INNER JOIN @dummyBalance d on r.product = d.product
             where r.seq = @seq

            IF (@variance <> 0 AND @seq <> 9 AND @seq <> 11)
            BEGIN
                SELECT @transDesc = 'DWL-' + CAST(@fromdate as varchar(30))
                                           + CAST(@custid as varchar(50)) + ':'
                                           + CAST(@variance as varchar(100))

                EXEC DBTRANS.bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
                    @winlostdate = @winlostdate,
	                @custid = @custid,
	                @amount = @variance,
	                @transdesc = @transDesc,
	                @creator = @creator,
	                @ip = @ip,
	                @ErrCode = @ErrCode OUTPUT,
                    @ErrMsg = @ErrMsg OUTPUT

                IF (@ErrCode <> 0) BREAK
                    
                IF (@seq = @maxseq)
                BEGIN
	                EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Transfer
	                    @UserID = @creator,
	                    @FromCustID = 0,
	                    @ToCustID = @custid,
	                    @IP = @ip,
	                    @Doing = @transDesc
                END
            END

            SET @seq = @seq + 1

            SELECT @ErrMsg = 'The process has been successful!'
        END
      
        SELECT winlostdate,
               product,
               winlost,
               reset + latestreset AS totalreset,
               latestreset
          FROM @reset
       
	    RETURN
	END
END
GO
GRANT EXECUTE ON [dbo].[Task_ResetWinning_Non3rdParty] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_ResetWinning_Non3rdParty] TO [vnteam]

