CREATE PROCEDURE [dbo].[Acc_Rpt_SMAs_TurnOver]
	@WinlostDate	SMALLDATETIME	= '2014-05-22', 
	@MoveBetsDay	SMALLDATETIME	= '2014-05-19', 
	@ShowSB			BIT				=1,  
	@ShowRB			BIT				=1,  
	@ShowNG			BIT				=1,
	@ShowKN			BIT				=1,
	@ShowLC 		BIT				=1,
	@ShowVS			BIT				=1,
	@ShowCS  		BIT				=1,
	@ShowOpened		BIT				=1,
	@ShowClosed		BIT				=0,  
	@ShowSuspended	BIT				=0
AS  
/*  Created: Dominic  
	Date: 2014-05-22  
    Task : SMA Turnover Report by Date
    DB: DBACC/bodb02  
   
    Revisions:  
		
	Param's Explanation:  
	  + @winLostDate: The specified date used as one of the filter criterias
	  + @MoveBetsDay: The day when bets are moved to bettrans14
	  + @ShowSB: Include SportsBook bets
	  + @ShowRB: Include RB bets
	  + @ShowNG: Include Number game bets
	  + @ShowKN: Include Keno
	  + @ShowLC: Include Live Casino
	  + @ShowVS: Include Virtual Sports
	  +	@ShowCS: Include RNG Casino
	  +	@ShowOpened: Include Opened account status
	  +	@ShowClosed: Include closed account status
	  +	@ShowSuspended: Include suspended account status
  
*/  
BEGIN  
	SET NOCOUNT ON  

	--Declare variables and create temp tables
	CREATE TABLE #CustTbl (
		IsAssignedGroup BIT,
		GroupID SMALLINT,
		GroupHeadline NVARCHAR(30),
		CustID INT,
		UserName NVARCHAR(30),
		RoleID TINYINT,
		Currency INT,
		CurrencyName NVARCHAR(50)
		)
	CREATE TABLE #AvailableCustID (
		CustID INT,
		)
	CREATE TABLE #TmpReportResultTbl (
		IsAssignedGroup BIT,
		GroupID SMALLINT,
		GroupHeadline NVARCHAR(30),
		CustID INT,
		UserName NVARCHAR(30),
		RoleID TINYINT,
		Currency INT,
		CurrencyName NVARCHAR(50),
		TurnOverAfterPT MONEY,
		TurnOverAfterPTMYR MONEY,
		TurnOver MONEY,
		--MYR
		TurnOverMYR MONEY
		)
	CREATE TABLE #TmpAvailableBetTrans(
			SRecomend INT,
			MRecomend INT,
			Recomend INT,
			CustID INT,
		)

	--Get Super Accounts
	INSERT INTO #CustTbl (
		IsAssignedGroup,
		GroupID,
		GroupHeadline,
		CustID,
		UserName,
		RoleID,
		Currency,
		CurrencyName
		)
	SELECT
		CASE
			WHEN custacc.groupID IS NULL THEN 0 ELSE 1
		END,
		custacc.groupID,
		NULL, 
		custacc.custid,
		cust.username,
		cust.roleid,
		cust.currency,
		e.currency
	FROM  dbo.custAccount custacc WITH(NOLOCK)
	INNER JOIN dbo.Customer cust WITH(NOLOCK) ON custacc.custid = cust.custid AND cust.roleid = 4 AND cust.currency NOT IN (20 ,27 , 28)
	INNER JOIN dbo.CustSuper cs WITH(NOLOCK) ON custacc.custid = cs.custid AND cs.IsInternal = 0
	INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON custacc.custid = ci.custid
	LEFT JOIN dbo.Exchange e WITH(NOLOCK) ON cust.currency = e.exchangeid
	WHERE ci.[Enabled] = 1
		  AND ((@ShowOpened=1 AND ci.closed = 0	AND ci.reject = 0)
			   OR (@ShowSuspended = 1 AND ci.closed = 0 AND ci.reject = 1)
			   OR (@ShowClosed=1 AND ci.closed = 1) )			 
	--Get Direct Master Accounts
	INSERT INTO #CustTbl (
		IsAssignedGroup,
		GroupID,
		GroupHeadLine,
		CustID,
		UserName,
		RoleID,
		Currency,
		CurrencyName
		)
	SELECT 
		CASE
			WHEN custacc.groupID IS NULL THEN 0
			ELSE 1
		END,
		custacc.groupID,
		NULL,
		cust.custid,
		cust.username,
		cust.roleid,
		cust.currency,
		e.currency
	FROM dbo.Customer cust WITH(NOLOCK)
	INNER JOIN bodb_acc.dbo.Acc_CustDirect acccust WITH(NOLOCK) ON cust.srecommend = acccust.custid AND cust.roleid = 3	AND acccust.roleid = 4
	INNER JOIN dbo.CustMaster csm WITH(NOLOCK) ON cust.custid = csm.custid AND csm.IsInternal = 0 AND cust.currency NOT IN (20 , 27, 28)
	INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cust.custid = ci.custid
	LEFT JOIN dbo.custAccount custacc WITH(NOLOCK) ON custacc.custid = cust.custid
	LEFT JOIN dbo.Exchange e WITH(NOLOCK) ON cust.currency = e.exchangeid
	WHERE ci.[Enabled] = 1
		  AND ((@ShowOpened=1 AND ci.closed = 0 AND ci.reject = 0)
			   OR (@ShowSuspended = 1 AND ci.closed = 0 AND ci.reject = 1)
			   OR (@ShowClosed=1 AND ci.closed = 1) )
	--Get Direct Agent Accounts
	INSERT INTO #CustTbl (
		IsAssignedGroup,
		GroupID,
		GroupHeadLine,
		CustID,
		UserName,
		RoleID,
		Currency,
		CurrencyName
		)
	SELECT 
		CASE
			WHEN custacc.groupID IS NULL THEN 0
			ELSE 1
		END,
		custacc.groupID,
		NULL,
		cust.custid,
		cust.username,
		cust.roleid,
		cust.currency,
		e.currency
	FROM dbo.Customer cust WITH (NOLOCK)
	INNER JOIN bodb_acc.dbo.Acc_CustDirect acccust WITH(NOLOCK) ON cust.mrecommend = acccust.custid AND cust.roleid = 2	AND acccust.roleid = 3
	INNER JOIN dbo.CustAgent WITH(NOLOCK) ON cust.custid = CustAgent.custid AND CustAgent.IsInternal = 0	
				AND cust.currency NOT IN (20 , 27 , 28)
	INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cust.custid = ci.custid
	LEFT JOIN dbo.custAccount custacc WITH(NOLOCK) ON custacc.custid = cust.custid
	LEFT JOIN dbo.Exchange e WITH(NOLOCK) ON cust.currency = e.exchangeid
	WHERE ci.[Enabled] = 1
		  AND ((@ShowOpened=1 AND ci.closed = 0 AND ci.reject = 0) OR (@ShowSuspended = 1 AND ci.closed = 0 AND ci.reject = 1)
			   OR (@ShowClosed=1 AND ci.closed = 1) )
	--Get Direct Member Accounts
	INSERT INTO #CustTbl (
		IsAssignedGroup,
		GroupID,
		GroupHeadLine,
		CustID,
		UserName,
		RoleID,
		Currency,
		CurrencyName
		)
	SELECT 
		CASE
			WHEN custacc.groupID IS NULL THEN 0
			ELSE 1
		END,
		custacc.groupID,
		NULL,
		cust.custid,
		cust.username,
		cust.roleid,
		cust.currency,
		e.currency
	FROM dbo.Customer cust WITH (NOLOCK) 
	INNER JOIN bodb_acc.dbo.Acc_CustDirect acccust ON cust.recommend = acccust.custid AND cust.roleid = 1 AND acccust.roleid = 2
	INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON cust.custid = ci.custid
	LEFT JOIN dbo.custAccount custacc WITH(NOLOCK) ON custacc.custid = cust.custid
	LEFT JOIN dbo.Exchange e WITH(NOLOCK) ON cust.currency = e.exchangeid
	WHERE cust.recommend NOT IN
		( SELECT cag.custid
		 FROM dbo.CustAgent cag WITH(NOLOCK)
		 WHERE cag.IsInternal = 1 )
		  AND cust.currency NOT IN ( 20 , 27 , 28 )
		  AND ci.[Enabled] = 1
		  AND ((@ShowOpened = 1	AND ci.closed = 0 AND ci.reject = 0)
			   OR (@ShowSuspended = 1 AND ci.closed = 0 AND ci.reject = 1)
			   OR (@ShowClosed=1 AND ci.closed = 1))
	
	--If data in bettrans table
	IF @WinlostDate > @MoveBetsDay
	BEGIN
		--Get necessary customerIDs for performance reasons
		INSERT INTO #TmpAvailableBetTrans
		SELECT DISTINCT b.srecommend, b.mrecommend, b.recommend, b.custid
		 FROM dbo.bettrans b WITH (NOLOCK,INDEX=IX_winlostdate) 
		 WHERE b.statusID IN (111, 112, 113)
		   AND b.winlostdate = @WinlostDate
		   
		INSERT INTO #AvailableCustID
		SELECT DISTINCT custid
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT Recomend
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT MRecomend
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT SRecomend
		 FROM #TmpAvailableBetTrans
		  
		--Delete unnecessary customerIDs for performance reasons 
		DELETE
		FROM #CustTbl
		WHERE CustID NOT IN
			(SELECT CustID
			 FROM #AvailableCustID)	


		--Update GroupHeadlineName
		UPDATE #CustTbl
		SET #CustTbl.GroupHeadline =
		  ( SELECT cs.username
		   FROM dbo.custAccount cusacc
		   LEFT JOIN dbo.Customer cs ON cs.custid=cusacc.custid
		   WHERE cusacc.groupID = #CustTbl.GroupID
			 AND cusacc.IsGroupHeadLine=1 )
			
		--Calculation for Super
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID, 
			s.GroupHeadline, 
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(spositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(spositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans b WITH (NOLOCK)  ON s.custid = b.srecommend AND s.RoleID=4 
			AND b.winlostdate = @WinlostDate AND b.statusID IN (111, 112, 113)		
		WHERE s.RoleID=4
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)
			AND
				(SELECT ca.IsInternal
				 FROM dbo.CustAgent ca with(nolock)
				 WHERE ca.custid=b.recommend) = 0
			AND
				(SELECT cm.IsInternal
				 FROM dbo.CustMaster cm with(nolock)
				 WHERE cm.custid=b.mrecommend) = 0
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,    
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName
		--Calculation for Direct Master	
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(mpositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(mpositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans b WITH (NOLOCK)  ON s.custid = b.mrecommend AND s.RoleID=3
			AND b.winlostdate = @WinlostDate AND b.statusID  IN (111, 112, 113)
		WHERE s.RoleID=3	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)
			AND
				(SELECT ca.IsInternal
				 FROM dbo.CustAgent ca with(nolock)
				 WHERE ca.custid=b.recommend) = 0
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName	
		--Calculation for Direct Agent
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,  
			s.GroupHeadline, 
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(apositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(apositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans b WITH (NOLOCK) ON s.custid = b.recommend AND s.RoleID=2
			AND b.winlostdate = @WinlostDate AND  b.statusID  IN (111, 112, 113) 
		WHERE 
			s.RoleID=2	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)	
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID, 
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName		
		--Calculation for Direct Member	
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,  
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans b WITH (NOLOCK)  ON s.custid = b.custid AND s.RoleID=1
			AND b.winlostdate = @WinlostDate AND b.statusID IN (111, 112, 113) 
		WHERE 
			s.RoleID=1	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)	
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,    
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName		
	END
	ELSE
	BEGIN
		--Get necessary customerIDs for performance reasons
		INSERT INTO #TmpAvailableBetTrans
		SELECT DISTINCT b.srecommend, b.mrecommend, b.recommend, b.custid
		 FROM dbo.bettrans14 b WITH (NOLOCK) 
		 WHERE b.statusID IN (111, 112, 113)
		   AND b.winlostdate = @WinlostDate
		   
		INSERT INTO #AvailableCustID
		SELECT DISTINCT custid
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT Recomend
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT MRecomend
		 FROM #TmpAvailableBetTrans
		 UNION SELECT DISTINCT SRecomend
		 FROM #TmpAvailableBetTrans
		  
		--Delete unnecessary customerIDs for performance reasons 
		DELETE
		FROM #CustTbl
		WHERE CustID NOT IN
			(SELECT CustID
			 FROM #AvailableCustID)	


		--Update GroupHeadlineName
		UPDATE #CustTbl
		SET #CustTbl.GroupHeadline =
		  ( SELECT cs.username
		   FROM dbo.custAccount cusacc
		   LEFT JOIN dbo.Customer cs ON cs.custid=cusacc.custid
		   WHERE cusacc.groupID = #CustTbl.GroupID
			 AND cusacc.IsGroupHeadLine=1 )
			
		--Calculation for Super
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID, 
			s.GroupHeadline, 
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(spositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(spositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans14 b WITH (NOLOCK)  ON s.custid = b.srecommend AND s.RoleID=4 
			AND b.winlostdate = @WinlostDate AND b.statusID IN (111, 112, 113)		
		WHERE s.RoleID=4
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)
			AND
				(SELECT ca.IsInternal
				 FROM dbo.CustAgent ca with(nolock)
				 WHERE ca.custid=b.recommend) = 0
			AND
				(SELECT cm.IsInternal
				 FROM dbo.CustMaster cm with(nolock)
				 WHERE cm.custid=b.mrecommend) = 0
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,    
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName
		--Calculation for Direct Master	
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(mpositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(mpositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans14 b WITH (NOLOCK)  ON s.custid = b.mrecommend AND s.RoleID=3
			AND b.winlostdate = @WinlostDate AND b.statusID  IN (111, 112, 113)
		WHERE s.RoleID=3	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)
			AND
				(SELECT ca.IsInternal
				 FROM dbo.CustAgent ca with(nolock)
				 WHERE ca.custid=b.recommend) = 0
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName	
		--Calculation for Direct Agent
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,  
			s.GroupHeadline, 
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
				*
				ISNULL(apositiontaking,0)
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
				* ISNULL(apositiontaking,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans14 b WITH (NOLOCK) ON s.custid = b.recommend AND s.RoleID=2
			AND b.winlostdate = @WinlostDate AND  b.statusID  IN (111, 112, 113) 
		WHERE 
			s.RoleID=2	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)	
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID, 
			s.GroupHeadline,   
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName		
		--Calculation for Direct Member	
		INSERT INTO #TmpReportResultTbl
		SELECT   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,  
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName,
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END --liveawayscore is 0 mean Place is refund
			) turnoverPT,
			--MYR
			SUM(CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END
				* ISNULL(b.actualrate,0)
			) turnoverMYRPT,
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
			) turnover,
			--MYR
			SUM(
				CASE WHEN b.bettype IN (33, 43) AND liveawayscore = 0 THEN  ISNULL(ABS(stake),0)/2 ELSE ISNULL(ABS(stake),0) END 
				* ISNULL(b.actualrate,0)
			) turnoverMYR
		FROM #CustTbl s
			LEFT JOIN dbo.bettrans14 b WITH (NOLOCK)  ON s.custid = b.custid AND s.RoleID=1
			AND b.winlostdate = @WinlostDate AND b.statusID IN (111, 112, 113) 
		WHERE 
			s.RoleID=1	
			AND	(
					b.bettype < CASE WHEN @showSB=1 THEN 31 ELSE 0 END
					OR b.bettype between 121 and CASE WHEN @showSB=1 THEN 999 ELSE 0 END
					OR b.bettype between 1301 and CASE WHEN @showSB=1 THEN 1334 ELSE 0 END
					OR b.bettype between 31 and CASE WHEN @ShowRB=1 THEN 49 ELSE 0 END
					OR b.bettype BETWEEN 81 AND (CASE WHEN @showNG=1 THEN 120 ELSE 0 END)
					OR b.bettype BETWEEN 1101 AND (CASE WHEN @ShowLC=1 THEN 1199 ELSE 0 END)
					OR b.bettype BETWEEN 1201 AND (CASE WHEN @showVS=1 THEN 1299 ELSE 0 END)
					OR b.bettype BETWEEN 71 AND (CASE WHEN @showCS=1 THEN 71 ELSE 0 END)
					OR b.bettype BETWEEN 1501 AND (CASE WHEN @ShowKN=1 THEN 1599 ELSE 0 END)
				)	
		GROUP BY   
			s.IsAssignedGroup,
			s.GroupID,
			s.GroupHeadline,    
			s.custid,
			s.UserName,
			s.RoleID,
			s.currency, 
			s.CurrencyName	
	END


	--Return reported data
	SELECT ROW_NUMBER() over(
                         ORDER BY rs.IsAssignedGroup ASC,rs.GroupID ASC,rs.TurnOverMYR DESC) AS RowNum,
       rs.IsAssignedGroup,
       rs.GroupID,
       rs.GroupHeadline,
       rs.CustID,
       rs.UserName,
       rs.CurrencyName Currency,
       rs.RoleID,
       rs.TurnOverAfterPT,
       rs.TurnOverAfterPTMYR,
       rs.TurnOver MemberTurnOver,
       rs.TurnOverMYR MemberTurnOverMYR
	FROM #TmpReportResultTbl rs
	WHERE ABS(rs.TurnOver) <> 0
	

	--Drop temp tables
	DROP TABLE #CustTbl
	DROP TABLE #TmpReportResultTbl
	DROP TABLE #AvailableCustID
	Drop TABLE #TmpAvailableBetTrans
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_SMAs_TurnOver] TO [bodbAdminNet]



