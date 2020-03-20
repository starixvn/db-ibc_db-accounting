/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelClearBalance]
	@custid		INT,
	@UserId		INT = 0,
	@pageIndex	INT = 1,
	@pageSize	INT = 50,
	@TotalRows	INT = 0 OUTPUT
AS
/*
	Created: 
	Task : Clear Balance
	DB: DBAGE.bodb02
	Original:

	Revisions:
		- 20100709@Khoa: add more column SyncCasino
		- 20110517@Lukas: re-arrange bettype
		- 20110830@Jamie: COUNT phonebetting's negative stake as positive number
		- 20140305@Dom: Update outstanding for keno
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
		- 20151214@Percy: exclude Cock Fighting running ticket from bettrans [Redmine: #48601]
		- 20160125@Percy: expand new range RNG Casino [Redmine: #50674]
		- 20160215@Percy: support AllBet [Redmine: #50588]
		- 20160412@Percy: support Voidbridge single wallet [Redmine: #55258]
		- 20160608@Percy: Enhance performance - refactor code [RedmineID: #58288]
		- 20161006@Percy: Support Super and Master levels [RedmineID: #63209]
		- 20170622@Percy: Return ClosedReason column to apply color for closed accounts [RedmineID : #74494]
		- 20171018@Percy: Get status waiting from translog [RedmineID: #84692]
		- 20181003@Helen: Modify code to adapt indexes changed on DB053 [Redmine:101405]
		- 20200305@Elodie: Hardcode list finance permission [Redmine: #129890]
		- 20200316@Elodie: Remove from Hardcode list finance permission for Nova [Redmine: #130499]
		- 20200317@Malcolm: grant permission for finance account [Redmine : #128128] 

	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @today SMALLDATETIME, @yesterday SMALLDATETIME 
	SELECT  @today = CONVERT(DATE, GETDATE())
	SELECT  @yesterday = DATEADD(DAY, -1, @today)

	DECLARE @isTest BIT
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettypeMatrix (ProductID INT, Bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettypeMatrix (ProductID, Bettype, RefTable)
	SELECT ProductID, Bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)
	
	DECLARE @roleID TINYINT
	SELECT  @roleID = roleID FROM dbo.custInfo WITH(NOLOCK) WHERE custid = @custid

	CREATE TABLE #data (custid INT, yesterday_balance MONEY, balance MONEY, yesterday_cash MONEY, cash MONEY, outstanding MONEY)

	DECLARE @srecommend INT
	SELECT  @srecommend = srecommend FROM dbo.custInfo WITH(NOLOCK) WHERE custid = @custid

	DECLARE @GroupId SMALLINT = 0
	
	SELECT @GroupId = ISNULL(GroupId,0)
	FROM dbo.Acc_FinancePermission f WITH(NOLOCK) 
		 INNER JOIN Customer c WITH(NOLOCK) ON f.FinanceCode = c.username
    WHERE c.custid = @UserId AND c.roleid > 4
	
	IF @roleID = 4 -- Super
	BEGIN
		-- bettrans
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.mrecommend,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) balance,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN ruben = 0 THEN ABS(actual_stake*mpositiontaking) END), 0) outstanding
		FROM dbo.bettrans b WITH(NOLOCK)
			LEFT JOIN #SportBettypeMatrix s ON b.bettype = s.Bettype
		WHERE srecommend = @custid
			AND ((b.ruben = 0 AND ISNULL(s.RefTable, 0) = 0) OR b.ruben <> 0)
			AND ((b.winlostdate >= @yesterday AND ISNULL(s.RefTable, 0) NOT IN (1,2)) OR b.winlostdate < @yesterday)
		GROUP BY b.mrecommend

		-- bettransRnG
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.mrecommend,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN custid<>recommend AND custid<>mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN custid<>recommend AND custid<>mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake*mpositiontaking) END), 0) outstanding
		FROM dbo.bettransRnG b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE srecommend = @custid
			--AND s.RefTable = 1
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.mrecommend

		-- bettransLC
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.mrecommend,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN custid<>recommend AND custid<>mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN custid<>recommend AND custid<>mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END), 0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake*mpositiontaking) END), 0) outstanding
		FROM dbo.bettransLC b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE srecommend = @custid
			--AND s.RefTable = 2
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.mrecommend

		-- translog
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			t.mrecommend,
			0 yesterday_balance,
			0 balance,
			0 yesterday_cash,
			0 cash,
			ISNULL(SUM(ABS(actual_stake*mpositiontaking)), 0) outstanding
		FROM translog t (NOLOCK)
		WHERE t.srecommend = @custid
			AND statusID IN (0, 1)
		GROUP BY t.mrecommend
	END
	ELSE IF @roleID = 3
	BEGIN
		
		-- bettrans
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.recommend,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN b.custid <> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) yesterday_balance,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN b.custid<> b.recommend AND b.custid <> b.mrecommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) balance,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN CASE WHEN custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN CASE WHEN custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN ruben = 0 THEN ABS(actual_stake*apositiontaking) END), 0) outstanding
		FROM dbo.bettrans b WITH(NOLOCK)
			LEFT JOIN #SportBettypeMatrix s ON b.bettype = s.Bettype
		WHERE b.mrecommend = @custid AND
			((b.ruben = 0 AND ISNULL(s.RefTable, 0) = 0) OR b.ruben <> 0)
			AND ((winlostdate >= @yesterday AND ISNULL(s.RefTable, 0) NOT IN (1,2)) OR winlostdate < @yesterday)
		GROUP BY b.recommend

		-- bettransRnG
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.recommend,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake*apositiontaking) END), 0) outstanding
		FROM dbo.bettransRnG b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE mrecommend = @custid
			--AND s.RefTable = 1
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.recommend

		-- bettransLC
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.recommend,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0)
			+ ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid <> b.recommend THEN winlost-actual_stake+playercomm ELSE 0 END ELSE 0 END),0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN CASE WHEN b.custid = b.recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake*apositiontaking) END), 0) outstanding
		FROM dbo.bettransLC b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE mrecommend = @custid
			--AND s.RefTable = 2
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.recommend

		-- translog
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			t.recommend,
			0 yesterday_balance,
			0 balance,
			0 yesterday_cash,
			0 cash,
			ISNULL(SUM(ABS(actual_stake*apositiontaking)), 0) outstanding
		FROM translog t (NOLOCK)
		WHERE t.mrecommend = @custid AND statusID IN (0, 1)
		GROUP BY t.recommend
	END
	ELSE IF @roleID = 2
	BEGIN
		-- bettrans
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.custid,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN winlost-actual_stake+playercomm END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN winlost-actual_stake+playercomm END), 0) balance,
			ISNULL(SUM(CASE WHEN ruben = 1 AND (winlostdate < @today OR (winlostdate = @today AND b.bettype > 20000)) THEN winlost-actual_stake+playercomm END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN ruben = 1 THEN winlost-actual_stake+playercomm END), 0) cash,
			ISNULL(SUM(CASE WHEN ruben = 0 THEN ABS(actual_stake) END), 0) outstanding
		FROM dbo.bettrans b WITH(NOLOCK)
			LEFT JOIN #SportBettypeMatrix s ON b.bettype = s.Bettype
		WHERE b.recommend = @custid
			AND ((b.ruben = 0 AND ISNULL(s.RefTable, 0) = 0) OR b.ruben <> 0)
			AND ((winlostdate >= @yesterday AND ISNULL(s.RefTable, 0) NOT IN (1,2)) OR winlostdate < @yesterday)
		GROUP BY b.custid

		-- bettransRnG
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.custid,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN winlost-actual_stake+playercomm END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm END), 0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN winlost-actual_stake+playercomm END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) END), 0) outstanding
		FROM dbo.bettransRnG b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE recommend = @custid
			--AND s.RefTable = 1
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.custid

		-- bettransLC
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			b.custid,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN winlost-actual_stake+playercomm END), 0) yesterday_balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm END), 0) balance,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) AND winlostdate < @today THEN winlost-actual_stake+playercomm END), 0) yesterday_cash,
			ISNULL(SUM(CASE WHEN statusID NOT IN (0,1) THEN winlost-actual_stake+playercomm END), 0) cash,
			ISNULL(SUM(CASE WHEN statusID IN (0,1) THEN ABS(actual_stake) END), 0) outstanding
		FROM dbo.bettransLC b WITH(NOLOCK)
			--INNER JOIN #SportBettypeMatrix s ON b.gameID = s.Bettype
		WHERE recommend = @custid
			--AND s.RefTable = 2
			AND (b.statusID IN (0,1) OR (b.statusID NOT IN (0,1) AND b.winlostdate >= @yesterday))
		GROUP BY b.custid

		-- translog
		INSERT INTO #data (custid, yesterday_balance, balance, yesterday_cash, cash, outstanding)
		SELECT
			t.custid,
			0 yesterday_balance,
			0 balance,
			0 yesterday_cash,
			0 cash,
			ISNULL(SUM(ABS(actual_stake)), 0) outstanding
		FROM translog t (NOLOCK)
		WHERE recommend = @custid AND statusID IN (0, 1)
		GROUP BY t.custid
	END

	CREATE CLUSTERED INDEX IX_CustID ON #data (custid)
					
	SELECT @TotalRows = COUNT(c.CustId) 
		FROM dbo.Customer c WITH(NOLOCK)
		WHERE c.srecommend = @srecommend -- to using index on srecommend
			AND	c.srecommend	= CASE WHEN @roleID = 4 THEN @custid ELSE c.srecommend END
			AND c.mrecommend	= CASE WHEN @roleID = 3 THEN @custid ELSE c.mrecommend END
			AND c.recommend		= CASE WHEN @roleID = 2 THEN @custid ELSE c.recommend END
			AND c.roleid		= @roleID - 1
			
	-- Paging --
	DECLARE @rowStart INT, @rowEnd INT
	SELECT @PageIndex = @PageIndex - 1

	IF @roleID = 2 -- no paging on agent level
	BEGIN
		SELECT	@RowStart = 1
				,@RowEnd = @TotalRows
	END
	ELSE
	BEGIN
		SELECT	@RowStart = @PageSize * @PageIndex + 1
				,@RowEnd = @RowStart + @PageSize - 1
	END	
 

	DECLARE @result TABLE (rownum INT, custid INT PRIMARY KEY, username VARCHAR(30), closed BIT, firstname NVARCHAR(100), lastname NVARCHAR(100), credit MONEY, recommend INT, mrecommend INT, srecommend INT, SyncCasino BIT)
	INSERT INTO @result (rownum, custid, username, closed, firstname, lastname, credit, recommend, mrecommend, srecommend, SyncCasino)
	SELECT rownum, custid, username, closed, firstname, lastname, credit, recommend, mrecommend, srecommend, SyncCasino
	FROM (
		SELECT
			ROW_NUMBER() OVER(ORDER BY ci.closed, c.username) AS rownum,
			c.custid, c.username, ci.closed, c.firstname, c.lastname, ci.credit, c.recommend, c.mrecommend, c.srecommend, ci.SyncCasino /* recommend, mrecommend, SyncCasino for agent level*/
		FROM dbo.Customer c WITH(NOLOCK)
			INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON c.custid = ci.custid
		WHERE c.srecommend = @srecommend -- to using index on srecommend
			AND	c.srecommend	= CASE WHEN @roleID = 4 THEN @custid ELSE c.srecommend END
			AND c.mrecommend	= CASE WHEN @roleID = 3 THEN @custid ELSE c.mrecommend END
			AND c.recommend		= CASE WHEN @roleID = 2 THEN @custid ELSE c.recommend END
			AND c.roleid		= @roleID - 1
	) AS A
	WHERE A.rownum BETWEEN @rowStart AND @rowEnd

	CREATE TABLE #ClosedReason (custid INT, ClosedReason TINYINT)
	DECLARE @SQL NVARCHAR(MAX)

	IF @roleID = 2 -- agent view member
	BEGIN
		SELECT @SQL = 'SELECT CustID, ClosedReason
						FROM OPENQUERY(DBCUST, ''SELECT m.CustID, m.ClosedReason
												FROM CustDB.dbo.CustLoginInfo_Member m WITH(NOLOCK)
													INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON m.CustID = c.custid
												WHERE c.roleid = 1 AND c.recommend = ' + CONVERT(VARCHAR(30), @custid) + ''')'
	END
	ELSE -- super/master view master/agent
	BEGIN
		SELECT @SQL = 'SELECT CustID, ClosedReason
						FROM OPENQUERY(DBCUST, ''SELECT m.CustID, m.ClosedReason
												FROM CustDB.dbo.CustLoginInfo m WITH(NOLOCK)
													INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON m.CustID = c.custid
												WHERE c.roleid = ' + CONVERT(VARCHAR(1), @roleID-1) + ' AND '
												+ CASE @roleID WHEN 3 THEN 'c.mrecommend = ' WHEN 4 THEN 'c.srecommend = ' END + CONVERT(VARCHAR(30), @custid) + ''')'
	END

	INSERT INTO #ClosedReason (custid, ClosedReason)
	EXEC (@SQL)
	
	-- select --
	SELECT
		r.rownum AS RowNum,
		r.username AS Username,
		r.custid AS CustId,
		r.closed AS Closed,
		ISNULL(cr.ClosedReason, 0) AS ClosedReason,
		firstname AS FirstName,
		lastname AS LastName,
		ISNULL(b.outstanding, 0) Outstanding,
		ISNULL(b.balance, 0) Balance,
		ISNULL(b.yesterday_balance, 0) YesterdayBalance,
		ISNULL(b.cash, 0) Cash,
		ISNULL(b. yesterday_cash, 0) YesterdayCash,
		r.credit AS GivenCredit,
		c.used_credit AS UsedCredit,
		r.credit - c.used_credit AS AvailableCredit,
		r.recommend AS Recommend,
		r.mrecommend AS Mrecommend,
		r.SyncCasino
	FROM @result r
	CROSS APPLY (
				  SELECT TOP 1  CASE WHEN @GroupId = 1       THEN 1 
						             ELSE ISNULL(f.IsView,0) END AS IsView
				  FROM DBCUST.CustDB.dbo.Acc_FinancePermission f WITH(NOLOCK)
						LEFT JOIN Customer s WITH(NOLOCK) ON p.srecommend = s.custid
						LEFT JOIN Customer m WITH(NOLOCK) ON p.mrecommend = m.custid
	          			LEFT JOIN Customer a WITH(NOLOCK) ON p.recommend  = a.custid  
						LEFT JOIN Customer p WITH(NOLOCK) ON p.recommend  = a.custid 
				  WHERE (f.GroupId = @GroupId AND f.FinanceCode IN (@Username_S, @Username_M, @Username_P, @Username_A)) OR @GroupId = 1)
						AND p.custid = @custid
				  ORDER BY f.RoleId ASC
				) f
	CROSS APPLY (
		SELECT SUM(credit) AS used_credit
		FROM dbo.custInfo WITH(NOLOCK)
		WHERE srecommend = @srecommend -- to using index on srecommend
			AND	r.custid = CASE WHEN @roleID = 4 THEN mrecommend ELSE r.custid END
			AND r.custid = CASE WHEN @roleID = 3 THEN recommend ELSE r.custid END
			AND r.custid = CASE WHEN @roleID = 2 THEN custid ELSE r.custid END
			AND roleid = @roleID - 2

	) c
		LEFT JOIN (
			SELECT
				custid,
				SUM(outstanding) outstanding,
				SUM(balance) balance,
				SUM(yesterday_balance) yesterday_balance,
				SUM(cash) cash,
				SUM(yesterday_cash) yesterday_cash
			FROM #data
			GROUP BY custid
		) b ON r.custid = b.custid
		LEFT JOIN #ClosedReason cr ON r.custid = cr.custid
	WHERE f.IsView = 1 
	ORDER BY rownum
	
	DROP TABLE #data
	DROP TABLE #SportBettypeMatrix
	DROP TABLE #ClosedReason
END
GO