SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_StatementSel]
	@fromdate DATE
	,@todate DATE
	,@custid INT
AS

/*
Created by:[Cody]
Date: 20141219
Task: get statement report
DB: DBRPT.bodb_Report
Revisions:
	
 */
BEGIN
		SET NOCOUNT ON
		
		DECLARE @rptStatementTable TABLE(
			Winlostdate			DATE
			,Custid				INT
			,OpeningBalance		MONEY	NULL
			,VoidAmt			MONEY	NULL
			,Outstanding		MONEY	NULL
			,Turnover			MONEY	NULL
			,TransferAmt		MONEY	NULL
			,Winlost			MONEY	NULL
			,Comm				MONEY	NULL
			,ClosingBalance		MONEY	NULL
			,BetCount			INT		DEFAULT 0
		)
		
		DECLARE @roleid INT  
  
		SELECT @roleid = roleid FROM bodb02.dbo.customer WITH(NOLOCK) WHERE custid = @custid  

		-- Member
		IF @roleid = 1
		BEGIN
			-- 1: get sum data from Bettrans into rptStatement
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Turnover
				,Winlost
				,Comm
				,BetCount
			)
			SELECT
				winlostdate
				,custid
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS Turnover
				,SUM(winlost - actual_stake) AS winlost
				,SUM(playercomm) AS comm
				,COUNT(transid) AS betcount
			FROM
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE
				winlostdate BETWEEN @fromdate AND @todate
				AND statusID NOT IN (0,1,102,101,103) -- 'running','waiting','VOID','REJECT','REFUND'
				AND bettype <= 19999
				AND ruben = 1
				AND custid = @custid
			GROUP BY
				winlostdate, custid
				
			--2: void/ Cancelled Bet - get data from bettrans with status = 101, 102
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,VoidAmt
			)
			SELECT 
				winlostdate
				,custid
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS VoidAmt
			FROM 
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE 
				statusID IN (101, 102) -- 'VOID','REJECT'
				AND bettype <= 19000
				AND winlostdate BETWEEN @fromdate AND @todate
				AND custid = @custid
			GROUP BY 
				winlostdate, custid
				
			-- 3: Outstanding
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Outstanding
			)
			SELECT 
				winlostdate
				,custid
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS Outstanding
			FROM 
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE 
				statusID IN (0, 1) -- 'runing','waiting'
				AND (bettype <= 19000
				OR bettype IN (23001,23002,23101,23102,23201,23202))
				AND winlostdate BETWEEN @fromdate AND @todate
				AND custid = @custid
			GROUP BY 
				winlostdate, custid
			
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Outstanding
			)
			SELECT 
				winlostdate
				,custid
				,SUM(stake) AS Outstanding
			FROM 
				bodb02.dbo.translog WITH(NOLOCK)  
			WHERE
				winlostdate BETWEEN @fromdate AND @todate 
				AND custid = @custid  
				AND statusID = 0  
			GROUP BY 
				winlostdate, custid			
		END
		-- Agent
		IF @roleid = 2
		BEGIN
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Turnover
				,Winlost
				,Comm
				,BetCount
			)
			SELECT
				winlostdate
				,recommend
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS Turnover
				,SUM(awinlost) AS winlost
				,SUM(comm - playercomm) AS comm
				,COUNT(transid) AS betcount
			FROM
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE
				winlostdate BETWEEN @fromdate AND @todate
				AND statusID NOT IN (0,1,102,101,103) -- 'running','waiting','VOID','REJECT','REFUND'
				AND bettype <= 19999
				AND ruben = 1
				AND recommend = @custid
			GROUP BY
				winlostdate, recommend
		END
		
		-- Master
		IF @roleid = 3
		BEGIN
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Turnover
				,Winlost
				,Comm
				,BetCount
			)
			SELECT
				winlostdate
				,mrecommend
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS Turnover
				,SUM(mwinlost) AS winlost
				,SUM(acomm - comm) AS comm
				,COUNT(transid) AS betcount
			FROM
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE
				winlostdate BETWEEN @fromdate AND @todate
				AND statusID NOT IN (0,1,102,101,103) -- 'running','waiting','VOID','REJECT','REFUND'
				AND bettype <= 19999
				AND ruben = 1
				AND mrecommend = @custid
			GROUP BY
				winlostdate, mrecommend
		END
		
		-- Super
		IF @roleid = 4
		BEGIN
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,Turnover
				,Winlost
				,Comm
				,BetCount
			)
			SELECT
				winlostdate
				,srecommend
				,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS Turnover
				,SUM(swinlost) AS winlost
				,SUM(scomm - acomm) AS comm
				,COUNT(transid) AS betcount
			FROM
				bodb02.dbo.Bettrans WITH(NOLOCK)
			WHERE
				winlostdate BETWEEN @fromdate AND @todate
				AND statusID NOT IN (0,1,102,101,103) -- 'running','waiting','VOID','REJECT','REFUND'
				AND bettype <= 19999
				AND ruben = 1
				AND srecommend = @custid
			GROUP BY
				winlostdate, srecommend
		END
		
		--4: Transfer rptStatement	
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid
			,TransferAmt
		)
		SELECT 
			winlostdate
			,custid
			,SUM(winlost - actual_stake) AS TransferAmt
		FROM  
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE  
			matchid = 0 
			AND bettype > 20000  
			AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
			AND winlostdate BETWEEN @fromdate AND @todate
			AND custid = @custid
		GROUP BY 
			winlostdate, custid
			
		--5: Opening Balance for rptStatement
		
		DECLARE @CurrentBU_Date DATE

		SELECT TOP 1 @CurrentBU_Date = winlostdate
		FROM bodb02.dbo.bettrans WITH(NOLOCK) 
		WHERE matchid = 0 AND bettype = 20000
		
		DECLARE @Winlostdate DATE = @fromdate
		
		WHILE(@Winlostdate <= @todate)
		BEGIN
			--SELECT @CurrentBU_Date, @Winlostdate
			
			IF (@Winlostdate = @CurrentBU_Date)
			BEGIN
				--get Opening Balance with bettype = 20000 from bettrans
				INSERT INTO @rptStatementTable(
					Winlostdate
					,Custid
					,OpeningBalance
				)
				SELECT
					@Winlostdate
					,custid
					,SUM(winlost - actual_stake) AS OpeningBalance
				FROM 
					bodb02.dbo.bettrans WITH(NOLOCK)
				WHERE 
					winlostdate = @CurrentBU_Date
					AND bettype = 20000
					AND custid = @custid
				GROUP BY custid
				
			END
			ELSE -- winlostdate > CurrentBU_Date
			BEGIN
				-- Opening Balance for Member
				IF @roleid = 1
				BEGIN
					INSERT INTO @rptStatementTable(
						Winlostdate
						,custid
						,OpeningBalance
					)
					SELECT
						@Winlostdate
						,custid
						,SUM(winlost - actual_stake + playercomm) AS OpeningBalance
					FROM
						bodb02.dbo.bettrans WITH(NOLOCK)
					WHERE
						ruben = 1
						AND winlostdate >= @CurrentBU_Date 
						AND winlostdate < @Winlostdate 
						AND	custid <> recommend
						AND custid <> mrecommend
						AND custid <> srecommend
						AND custid = @custid
					GROUP BY custid
				END
				
				-- Opening Balance for Agent
				IF @roleid = 2
				BEGIN
					INSERT INTO @rptStatementTable(
						Winlostdate
						,custid
						,OpeningBalance
					)
					SELECT	
						@Winlostdate
						,recommend
						,SUM(CASE WHEN custid = recommend THEN winlost - actual_stake ELSE awinlost + comm - playercomm END) AS OpeningBalance
					FROM
						bodb02.dbo.bettrans WITH(NOLOCK)
					WHERE
						ruben = 1 
						AND winlostdate >= @CurrentBU_Date 
						AND winlostdate < @Winlostdate
						AND recommend = @custid
					GROUP BY recommend
				END

				-- Opening Balance for Master
				IF @roleid = 3
				BEGIN
					INSERT INTO @rptStatementTable(
						Winlostdate
						,custid
						,OpeningBalance
					)
					SELECT
						@Winlostdate	
						,mrecommend
						,SUM(CASE WHEN custid = mrecommend THEN winlost - actual_stake ELSE mwinlost + acomm - comm END) AS OpeningBalance
					FROM
						bodb02.dbo.bettrans WITH(NOLOCK)
					WHERE
						ruben = 1 
						AND winlostdate >= @CurrentBU_Date 
						AND winlostdate < @Winlostdate
						AND mrecommend = @custid
					GROUP BY mrecommend
				END

				-- Opening Balance for Super
				IF @roleid = 4
				BEGIN
					INSERT INTO @rptStatementTable(
						Winlostdate
						,custid
						,OpeningBalance
					)
					SELECT
						@Winlostdate
						,srecommend
						,SUM(CASE WHEN custid = srecommend THEN winlost - actual_stake ELSE swinlost + scomm - acomm END) AS OpeningBalance
					FROM
						bodb02.dbo.bettrans WITH(NOLOCK)
					WHERE
						ruben = 1 
						AND winlostdate >= @CurrentBU_Date 
						AND winlostdate < @Winlostdate
						AND srecommend = @custid
					GROUP BY srecommend
				END
			END
			
			SET @Winlostdate = DATEADD(DD, 1, @Winlostdate)
		END
		
		-- show statement report
		SELECT 
			tmp.Winlostdate
			,tmp.Custid
			,SUM(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]
			,SUM(tmp.Voidamt) AS [VoidAmt]
			,SUM(tmp.Outstanding) AS [Outstanding]
			,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Turnover ELSE NULL END) AS [Turnover]
			,SUM(tmp.Transferamt) AS [TransferAmt]
			,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
			,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
			,SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance
		FROM 
			@rptStatementTable tmp
		GROUP BY 
			tmp.Winlostdate
			,tmp.Custid
		HAVING
			SUM(ISNULL(tmp.Openingbalance, 0)) <> 0
			OR SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) <> 0
END
GO
