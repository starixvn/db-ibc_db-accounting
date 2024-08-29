/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelGroupHeadlineByRefno]
	@File			VARCHAR(MAX),
	@ProductID		INT,
	@MatchId		INT = 0,
	@MessageId		INT = 0,
	@HeadlineType	TINYINT = 2,
	@PageSize		INT = 0,
	@PageIndex		INT = 0,
	@TotalRows		INT = 0 OUTPUT,
	@ActualResult	NVARCHAR(MAX) ='',
	@WrongResult    NVARCHAR(MAX) ='',
	@IsCheckMessage	BIT = 0 OUTPUT,
	@DeniedList		NVARCHAR(MAX)=NULL,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created by: 20161031@Winnie
	Task: Get headline info by Refno RedmineID: #51925
	DB: DBACC.bodb02
	Original:	
	
	Revisions:
		- 20170828@Percy: Support Virtual Sports 2 [RedmineID: #82216]
		- 20170905@Percy: Using RefTable column to avoid missing products [RedmineID: #82419]
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20200303@Malcolm : support to upload ticket of SA Gaming [RedmineID : #129597]
		- 20200415@Malcolm : support to upload ticket of BBIN Live Casino [RedmineID : #131358]
		- 20210122@Malcolm : Get more information to notify headlines [RedmineId : #147470]
		- 20210922@Malcolm : remove the Actual and Wrong result requirements if messageid <> 0 [RedmineId : #161524]
		- 20240110@Johnson: check permission for 777 [redmineID: #197160]
		- 20240419@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240729@Lewis: Scale Out DBCust - Remove Linked Server [Redmine : #206895]

	Param's Explanation:
	- @Fie:	<ROOT>
                <File UserName="member1" RefNo="123456789"/>
            </ROOT>	
	- @HeadlineType: 2-All,1-Vip,0-Normal
	- ErrCode:	1-Deposit Customer	
				2-Invalid Ref No
				3-Invalid Username
				4-Mismatched Username and Ref No
*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@File, '') = ''
		RETURN

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1
	
	DECLARE @iDoc			INT			
			,@UserName		VARCHAR(50)	
			,@tmpEventType  INT
			,@tmpMatchId	INT
	
	CREATE TABLE #inputRaw
	(
		RowAt INT IDENTITY(2, 1),
		UserNameRaw NVARCHAR(50),
		UserName VARCHAR(50),
		RefNo NVARCHAR(50)
	)

	CREATE TABLE #input
	(
		UserNameRaw NVARCHAR(50),
		UserName VARCHAR(50),
		RefNo BIGINT,
		CustId INT,
		Site  VARCHAR(10),
		Currency INT
	)

	CREATE TABLE #tmpData
	(
		Currency		INT,
		custid			INT, -- custid from bettrans
		inputCustId		INT, -- custid from input file
		inputUsername	VARCHAR(50), -- username from input file
		Refno			NVARCHAR(50),
		Bettype			SMALLINT,
		WinlostDate		SMALLDATETIME,
		MatchId			INT,
		MatchCode		NVARCHAR(100),
		Sporttype		INT,
		StatusId		TINYINT
	)
	
	CREATE TABLE #result
	(
		GroupHeadline	INT,
		HeadlineType	TINYINT,
		Currency		INT,
		srecommend		INT,
		mrecommend		INT,
		recommend		INT,
		custid			INT, -- custid from bettrans
		inputCustId		INT, -- custid from input file
		inputUsername	VARCHAR(50), -- username from input file
		Refno			NVARCHAR(50),
		ErrorCode		TINYINT,
		Bettype			SMALLINT,
		WinlostDate		SMALLDATETIME,
		RefTable		TINYINT,
		MatchId			INT,
		MatchCode		NVARCHAR(100),
		ProductId		TINYINT,
		EventType       TINYINT,
		Sporttype		INT,
		StatusId		TINYINT
	)
	
	CREATE TABLE #tmpResult
	(
		GroupHeadline	VARCHAR(500),
		HeadlineType	VARCHAR(50),
		Currency		VARCHAR(50),
		Super			VARCHAR(50),
		Master			VARCHAR(50),
		Agent			VARCHAR(50),
		Member			NVARCHAR(50),
		Refno			NVARCHAR(50),
		ErrorCode		TINYINT
	)	
	
	CREATE TABLE #tmpAccCustGroup
	(
		CustID		INT,
		GroupName	VARCHAR(50)
	)
	
	CREATE TABLE #GroupHeadline
	(
		GroupID			SMALLINT PRIMARY KEY,
		CustID			INT,
		HeadlineType	TINYINT
	)
	
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @File
		
		INSERT #inputRaw (UserName, UserNameRaw, RefNo)
		SELECT UserName, UserName, RefNo
		FROM OPENXML(@iDoc, '/ROOT/File', 1) WITH (UserName NVARCHAR(50), RefNo NVARCHAR(50))
	END TRY
	BEGIN CATCH
		RETURN
	END CATCH
	
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	DECLARE @cnt INT

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END
	
	-- Check invalid input username, ErrCode = 3
	DELETE i	
	OUTPUT deleted.UserNameRaw, deleted.RefNo, 3
	INTO #result (inputUsername, Refno, ErrorCode)
	FROM #inputRaw i
		LEFT JOIN dbo.Customer c WITH (NOLOCK) ON i.username = c.username
	WHERE c.custid IS NULL
	-- End check invalid input username

	-- Check invalid input Refno, ErrCode = 2
	DELETE i
	OUTPUT deleted.UserNameRaw, deleted.RefNo, 2
	INTO #result (inputUsername, Refno, ErrorCode)
	FROM #inputRaw i
	WHERE ISNUMERIC(Refno + '.0e0') = 0 -- cannot convert to bigint -- data type of Refno
	-- End check invalid input Refno

	-- Check Deposit Customer, ErrCode = 1
	DELETE i
	OUTPUT deleted.UserNameRaw, deleted.RefNo, 1
	INTO #result (inputUsername, Refno, ErrorCode)
	FROM #inputRaw i
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON i.userName = c.username
		INNER JOIN dbo.Dep_CustSuper d WITH (NOLOCK) ON c.srecommend = d.custid
	-- End check Deposit Customer
	
	-- Get data
	INSERT INTO #input (CustId, UserName, RefNo, UserNameRaw,Site, Currency)
	SELECT c.custid, i.UserName, i.RefNo, i.UserNameRaw, c.Site, c.currency
	FROM #inputRaw i
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON i.UserName = c.username
	
	SELECT @cnt = @@ROWCOUNT
	
	DECLARE @strRefno VARCHAR(MAX) = ''
	
	SELECT @strRefno = @strRefno + ',' + CAST(RefNo as VARCHAR(50))
	FROM #input
	WHERE Site IN (SELECT site FROM @tmp)
	OR currency IN (SELECT exchangeID FROM @tmpExchange)

	SELECT @strRefno = STUFF(@strRefno,1,1,'')
	
	IF @strRefno <> ''
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg ='You don''t have permission to access. TicketID:' + @strRefno
		RETURN
	END
	
	IF @cnt <> 0
	BEGIN		
		-- Get Sport Bettype Matrix
		DECLARE @IsTest BIT = 0
		DECLARE	@Bettype TABLE (BetType INT PRIMARY KEY, RefTable TINYINT)
	
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	
		INSERT INTO @Bettype (BetType, RefTable)
		SELECT DISTINCT BetType, RefTable
		FROM bodb02.dbo.f_SportBettypeMatrix_Sel (@ProductID, 0, 0, 2, '', '', @IsTest)

		-- Checking product is belong to bettrans (bettrans.transid = input.RefNo)
		/* bettransG --> bettrans --> bettransG14 --> bettrans14 */
		/* bettransG.transid, bettrans.transid, bettransG14.transid, bettrans14.transid */
		IF EXISTS (SELECT Bettype FROM @Bettype WHERE RefTable = 0)
		BEGIN
			-- Step 1: check bettransG
				-- 1.1 mapping transid
			DELETE i
			OUTPUT  ct.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo,b.bettype,b.winlostdate,b.matchid, b.matchid
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno,Bettype,WinlostDate, MatchId, Sporttype)
			FROM #input i
				INNER JOIN dbo.bettransG b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo)
				INNER JOIN @Bettype bt ON bt.BetType = b.bettype AND bt.RefTable = 0
				LEFT  JOIN dbo.Customer ct WITH (NOLOCK) ON i.custid = ct.custid

				-- 1.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 1.3 if not mapping username, check on bettrans, bettrans14 (no need check bettransG14 due to can not the same transid)
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END,
				b.bettype, 
				b.winlostdate, 
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END,
				b.matchid, 
				b.betcheck, -- missmatch username, refno
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, 
				b.bettype, 
				b.winlostdate, 
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END, 
				b.matchid, 
				b.betcheck,-- missmatch username, refno
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 1.4 if not mapping on bettrans, bettrans14 --> missmatch username on bettransG, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 2: check bettrans
				-- 2.1 mapping transid
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				b.bettype, 
				b.winlostdate, 
				b.matchid, 
				b.betcheck,
				b.matchid,
				b.statusID
			INTO #tmpData 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				Bettype, 
				WinlostDate, 
				MatchId, 
				MatchCode,
				Sporttype,
				StatusId
			)
			FROM #input i
				INNER JOIN bettrans b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType AND bt.RefTable = 0
			
				-- 2.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				DELETED.Currency, 
				DELETED.inputUsername, 
				DELETED.inputCustId, 
				DELETED.custid, 
				DELETED.Refno, 
				NULL, 
				DELETED.Bettype, 
				DELETED.WinlostDate, 
				0, 
				DELETED.MatchId, 
				DELETED.MatchCode,
				DELETED.Sporttype,
				deleted.StatusId
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype,
				StatusId
			)
			WHERE inputCustId = custid

				-- 2.3 if not mapping username --> check on bettransG14 (no need check bettrans14 due to can not the same transid)
			DELETE i
			OUTPUT 
				c.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				NULL, 
				b.Bettype, 
				b.WinlostDate, 
				0,
				b.matchid,
				NULL,
				deleted.Sporttype,
				deleted.StatusId
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype,
				StatusId
			)
			FROM #tmpData i
				INNER JOIN dbo.bettransG14 b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.Refno) AND b.custid = i.inputCustId
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
				LEFT  JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = i.inputCustId


				-- 2.4 if not mapping on bettransG14 --> missmatch username on bettrans, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted. Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype,
				deleted.StatusId
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype,
				StatusId
			)

			-- Step 3: check bettransG14
				-- 3.1 mapping transid
			DELETE i
			OUTPUT	
				ct.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				b.Bettype, 
				b.WinlostDate, 
				b.MatchId, 
				NULL,
				b.matchid
			INTO #tmpData
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				Bettype, 
				WinlostDate, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN dbo.bettransG14 b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo)
				INNER JOIN @Bettype bt ON bt.BetType = b.bettype AND bt.RefTable = 0
				LEFT  JOIN dbo.Customer ct WITH (NOLOCK) ON i.custid = ct.custid


				-- 3.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 3.3 if not mapping username, check on bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId, 
				b.betcheck,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 3.4 if not mapping on bettrans14 --> missmatch username on bettransG14, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 4: check bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 0 END,
				b.MatchId, 
				b.betcheck,
				b.matchid,
				b.statusID
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype,
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype,
				StatusId
			)
			FROM #input i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType AND bt.RefTable = 0
		END

		-- Checking product is belong to bettransRnG (bettransRnG.transid = input.RefNo)
		/* bettransRnG --> bettrans --> bettransRnG14 --> bettrans14 */
		/* bettransRnG.transid, bettrans.transid, bettransRnG14.transid, bettrans14.transid */
		IF EXISTS (SELECT Bettype FROM @Bettype WHERE RefTable = 1)
		BEGIN
			-- Step 1: check bettransRNG
				-- 1.1 mapping transid
			DELETE i
			OUTPUT b.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo,b.gameID, b.WinlostDate, NULL, NULL, b.ProductID
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno, Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i
				INNER JOIN bettransRnG b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 1.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL,
				deleted.Bettype, 
				deleted.WinlostDate, 
				1, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno,
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 1.3 if not mapping username, check on bettrans, bettrans14 (no need check bettransRnG14 due to can not the same transid)
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate,
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END,
				b.MatchId, 
				b.betcheck,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId, 
				b.betcheck,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 1.4 if not mapping on bettrans, bettrans14 --> missmatch username on bettransRnG, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 2: check bettrans
				-- 2.1 mapping transid
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				b.Bettype, 
				b.WinlostDate, 
				b.MatchId, 
				b.betcheck,
				b.matchid
			INTO #tmpData 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				Bettype, 
				WinlostDate, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN bettrans b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
			
				-- 2.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				DELETED.Currency, 
				DELETED.inputUsername, 
				DELETED.inputCustId,
				DELETED.custid, 
				DELETED.Refno, 
				NULL, 
				DELETED.Bettype, 
				DELETED.WinlostDate, 
				0, 
				DELETED.MatchId, 
				DELETED.MatchCode,
				DELETED.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 2.3 if not mapping username --> check on bettransRnG14 (no need check bettrans14 due to can not the same transid)
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId,
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.gameID,
				b.winlostdate,
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 1 END,
				NULL,
				NULL,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettransRnG14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 2.4 if not mapping on bettransRnG14 --> missmatch username on bettrans, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername,
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)

			-- Step 3: check bettransRnG14
				-- 3.1 mapping transid
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				b.gameID,
				b.WinlostDate, 
				NULL,
				NULL,
				b.ProductID
			INTO #tmpData 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				Bettype, 
				WinlostDate, 
				MatchId,
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN bettransRnG14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 3.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				1, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 3.3 if not mapping username, check on bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId, 
				b.betcheck,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 3.4 if not mapping on bettrans14 --> missmatch username on bettransRnG14, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 4: check bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId, 
				b.betcheck,
				b.MatchId
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
		END

		-- Checking product is belong to bettransLC (bettransLC.transid = input.RefNo)
		/* bettransG -> bettransLC --> bettrans --> bettransG14 ->bettransLC14 --> bettrans14 */
		/* bettransG.transid ,bettransLC.transid, bettrans.transid, bettransG14.transid, bettransLC14.transid, bettrans14.transid */
		IF EXISTS (SELECT Bettype FROM @Bettype WHERE RefTable = 2)
		BEGIN
		    -- Step 1: check bettransG
				-- 1.1: mapping transid 
			DELETE i
			OUTPUT  ct.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo, b.bettype, b.WinlostDate, b.matchid, NULL, b.matchid
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno, Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i
				INNER JOIN dbo.bettransG b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo)
				INNER JOIN @Bettype bt ON bt.BetType = b.bettype
				LEFT  JOIN dbo.Customer ct WITH (NOLOCK) ON i.custid = ct.custid
				-- 1.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE i
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
			WHERE i.custid = i.inputCustId
				-- 1.3 if not mapping username, check on bettransLC, bettrans, bettransLC14, bettrans14 (no need check bettransG14 due to can not the same transid)
			DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.Refno, NULL, b.gameID, b.winlostdate, 2,NULL, NULL, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettransLC b WITH (NOLOCK) ON i.Refno = b.transid  AND  i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				b.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN dbo.bettrans b WITH (NOLOCK) ON i.Refno = b.transid  AND  i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId,
				b.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype,
				deleted.WinlostDate,
				2, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN dbo.bettransLC14 b WITH (NOLOCK) ON i.Refno = b.transid  AND  i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

			DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.Refno, NULL, b.bettype, b.winlostdate, 0, b.matchid, b.betcheck, deleted.Sporttype
			INTO #result (Currency,inputUsername, inputCustId, custid,Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettrans14 b WITH (NOLOCK) ON i.Refno = b.transid  AND  i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 1.4 if not mapping on bettransLC,bettrans, bettransLC14, bettrans14 --> missmatch username on bettrans, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.custid, 
				deleted.inputCustId, 
				deleted.inputUsername, 
				deleted.Refno, 
				4, 
				deleted.Bettype,
				deleted.WinlostDate, 
				NULL, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result
			(
				Currency, 
				custid,
				inputCustId, 
				inputUsername, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
				-- Step 2: check bettransLC
				-- 2.1 mapping transid
			DELETE i
			OUTPUT b.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo,b.gameID, b.WinlostDate, NULL, NULL, b.ProductId
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno,Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i
				INNER JOIN dbo.bettransLC b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 2.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency,
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid,
				deleted.Refno,
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate,
				2, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency,
				inputUsername,
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 2.3 if not mapping username, check on bettrans, bettransG14 ,bettrans14 (no need check bettransLC14 due to can not the same transid)
			DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo,NULL, b.Bettype,b.WinlostDate, 0, b.MatchId, b.betcheck, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode,Bettype,WinlostDate,RefTable,MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettrans b WITH(NOLOCK) ON b.transid = i.RefNo AND i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType


			DELETE i
			OUTPUT c.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo, NULL, b.bettype, b.WinlostDate, 0,b.matchid,NULL, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettransG14 b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo) AND b.custid = i.inputCustId
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
				LEFT  JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = i.inputCustId


			DELETE i
			OUTPUT b.currency, deleted.inputUsername,deleted.inputCustId,b.custid, deleted.RefNo,NULL, b.Bettype, b.WinlostDate,0, b.MatchId,b.betcheck, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate,	RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo AND i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 2.4 if not mapping on bettrans, bettransG14, bettrans14 --> missmatch username on bettransLC, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency,
				deleted.inputUsername,
				deleted.inputCustId, 
				deleted.custid,
				deleted.Refno, 
				4, 
				deleted.Bettype,
				deleted.WinlostDate,
				NULL,
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype,
				WinlostDate,
				RefTable,
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 3: check bettrans
				-- 3.1 mapping transid
			DELETE i
			OUTPUT b.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo, b.Bettype, b.WinlostDate, b.MatchId, b.betcheck, b.matchId
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno, Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i
				INNER JOIN dbo.bettrans b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
			
				-- 3.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 3.3 if not mapping username --> check on bettransG14, bettransLC14 (no need check bettrans14 due to can not the same transid)
		
		    DELETE i
			OUTPUT c.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo, NULL, b.bettype, b.WinlostDate, NULL, b.MatchId,NULL, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettransG14 b WITH(NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo) AND b.custid = i.inputCustId
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
				LEFT  JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = i.inputCustId

		    DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo, NULL, b.gameID, b.WinlostDate, 2, NULL, NULL, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettransLC14 b WITH(NOLOCK) ON b.transid = i.RefNo AND b.custid = i.inputCustId
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 3.4 if not mapping on bettransG14,bettransLC14 --> missmatch username on bettrans, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate,
				NULL,
				deleted.MatchId,
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId,
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)

			-- Step 4: check bettransG14
				-- 4.1 mapping transid
			DELETE i
			OUTPUT c.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo, b.Bettype, b.WinlostDate, b.MatchId, NULL, b.matchid
			INTO #tmpData(Currency, inputUsername, inputCustId, custid, Refno, Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i 
				INNER JOIN dbo.bettransG14 b WITH (NOLOCK) ON b.transid = CONVERT(BIGINT,i.RefNo)
				INNER JOIN @Bettype bt ON bt.BetType = b.bettype
				LEFT  JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = b.custid
				-- 4.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate,
				0, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid
				-- 4.3 if not mapping username, check on bettransLC14, bettrans14

			DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo, NULL, b.gameID, b.WinlostDate, 2, NULL, NULL, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettransLC14 b WITH(NOLOCK) ON b.transid = i.RefNo AND i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

			DELETE i
			OUTPUT b.currency, deleted.inputUsername, deleted.inputCustId, b.custid, deleted.RefNo, NULL, b.Bettype, b.WinlostDate, 0, b.MatchId, b.betcheck, deleted.Sporttype
			INTO #result (Currency, inputUsername, inputCustId, custid, Refno, ErrorCode, Bettype, WinlostDate, RefTable, MatchId, MatchCode, Sporttype)
			FROM #tmpData i
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo AND i.inputCustId = b.custid
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 4.4 if not mapping on bettransLC14, bettrans14 --> missmatch username on bettransG14, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid, 
				deleted.Refno, 
				4, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				NULL,
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode, 
				Bettype, 
				WinlostDate, 
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)

			-- Step 5: check bettransLC14
				-- 5.1 mapping transid
			DELETE i
			OUTPUT b.currency, deleted.UserName, deleted.CustId, b.custid, deleted.RefNo, b.gameID, b.WinlostDate, NULL, NULL, b.ProductID
			INTO #tmpData (Currency, inputUsername, inputCustId, custid, Refno, Bettype, WinlostDate, MatchId, MatchCode, Sporttype)
			FROM #input i
				INNER JOIN dbo.bettransLC14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

				-- 5.2 if mapping username --> insert into result, ErrCode = NULL
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId, 
				deleted.custid,
				deleted.Refno, 
				NULL, 
				deleted.Bettype, 
				deleted.WinlostDate, 
				2, 
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate,
				RefTable,
				MatchId, 
				MatchCode,
				Sporttype
			)
			WHERE inputCustId = custid

				-- 5.3 if not mapping username, check on bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.inputUsername, 
				deleted.inputCustId,
				b.custid, 
				deleted.RefNo,
				CASE WHEN deleted.inputCustId <> b.custid THEN 4 ELSE NULL END, -- missmatch username, refno
				b.Bettype,
				b.WinlostDate,
				CASE WHEN deleted.inputCustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId,
				b.betcheck,
				deleted.Sporttype
			INTO #result 
			(
				Currency, 
				inputUsername,
				inputCustId,
				custid, 
				Refno, 
				ErrorCode,
				Bettype, 
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #tmpData i
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType

				-- 5.4 if not mapping on bettrans14 --> missmatch username on bettransLC14, ErrCode = 4
			DELETE #tmpData
			OUTPUT 
				deleted.Currency, 
				deleted.inputUsername, 
				deleted.inputCustId,
				deleted.custid, 
				deleted.Refno,
				4, 
				deleted.Bettype, 
				deleted.WinlostDate,
				NULL,
				deleted.MatchId, 
				deleted.MatchCode,
				deleted.Sporttype
			INTO #result 
			(	
				Currency, 
				inputUsername,
				inputCustId,
				custid, 
				Refno, 
				ErrorCode, 
				Bettype,
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			
			-- Step 6: check bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName,
				deleted.CustId, 
				b.custid,
				deleted.RefNo,
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate,
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId, 
				b.betcheck,
				b.matchId
			INTO #result 
			(
				Currency,
				inputUsername,
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype,
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN dbo.bettrans14 b WITH(NOLOCK) ON b.transid = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType
		END

		-- Checking product is belong to translog (translog.translogid = input.RefNo)
		/* translog --> bettrans --> bettrans14 */
		/* translog.translogid --> bettrans.refno --> bettrans14.refno */
		IF EXISTS (SELECT Bettype FROM @Bettype WHERE RefTable = 3)
		BEGIN
			-- Step 1: check translog
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId, 
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.gameID, 
				b.WinlostDate, 
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 3 END, 
				b.eventID, 
				b.Gameid3rd,
				b.ProductId
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno, 
				ErrorCode,
				Bettype,
				WinlostDate,
				RefTable, 
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN translog b WITH(NOLOCK) ON b.translogid = i.RefNo
				INNER JOIN @Bettype bt ON b.gameID = bt.BetType

			-- Step 1: check bettrans
			DELETE i
			OUTPUT
				b.currency, 
				deleted.UserName, 
				deleted.CustId,
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 0 END,
				b.MatchId, 
				b.betcheck,
				b.matchid
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId, 
				custid, 
				Refno,
				ErrorCode, 
				Bettype,
				WinlostDate,
				RefTable,
				MatchId, 
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN bettrans b WITH(NOLOCK) ON b.refno = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType AND bt.RefTable = 3
		
			-- Step 1: check bettrans14
			DELETE i
			OUTPUT 
				b.currency, 
				deleted.UserName, 
				deleted.CustId,
				b.custid, 
				deleted.RefNo, 
				CASE WHEN deleted.CustId <> b.custid THEN 4 END, -- missmatch username, refno
				b.Bettype, 
				b.WinlostDate, 
				CASE WHEN deleted.CustId <> b.custid THEN NULL ELSE 0 END, 
				b.MatchId,
				b.betcheck,
				b.matchid
			INTO #result 
			(
				Currency, 
				inputUsername, 
				inputCustId,
				custid,
				Refno, 
				ErrorCode,
				Bettype,
				WinlostDate,
				RefTable, 
				MatchId,
				MatchCode,
				Sporttype
			)
			FROM #input i
				INNER JOIN bettrans14 b WITH(NOLOCK) ON b.refno = i.RefNo
				INNER JOIN @Bettype bt ON b.bettype = bt.BetType AND bt.RefTable = 3
		END

		-- Still having data once checking done --> invalid RefNo
		INSERT INTO #result (inputUsername, Refno, ErrorCode)
		SELECT UserName, RefNo, 2 FROM #input
	END

	-- Update SMA's Id
	UPDATE r
	SET r.recommend = c.recommend, r.mrecommend = c.mrecommend, r.srecommend = c.srecommend
	FROM #result r
		INNER JOIN Customer c WITH(NOLOCK) ON r.custid = c.custid
	
	-- Update headline
	INSERT INTO #GroupHeadline (GroupID, CustID, HeadlineType)
	SELECT ca.GroupID, t.CustID, t.HeadlineType
	FROM dbo.custAccount ca WITH (NOLOCK)
		INNER JOIN dbo.CustGroupHeadline t WITH (NOLOCK) ON t.GroupID = ca.GroupID AND ca.custid = t.CustID
	WHERE ca.IsGroupHeadLine = 1

	-- Super >> Master >> Agent >> Member
	UPDATE r
	SET r.GroupHeadline = hed.CustID, r.HeadlineType = hed.HeadlineType
	FROM #result r	
		INNER JOIN custAccount ca WITH (NOLOCK) ON r.srecommend = ca.custid -- super
		INNER JOIN #GroupHeadline hed WITH (NOLOCK) ON ca.groupID = hed.groupID
	WHERE r.ErrorCode IS NULL

	UPDATE r
	SET r.GroupHeadline = hed.CustID, r.HeadlineType = hed.HeadlineType
	FROM #result r	
		INNER JOIN custAccount ca WITH (NOLOCK) ON r.mrecommend = ca.custid -- master
		INNER JOIN #GroupHeadline hed WITH (NOLOCK) ON ca.groupID = hed.groupID
	WHERE r.ErrorCode IS NULL AND r.GroupHeadline IS NULL

	UPDATE r
	SET r.GroupHeadline = hed.CustID, r.HeadlineType = hed.HeadlineType
	FROM #result r	
		INNER JOIN custAccount ca WITH (NOLOCK) ON r.recommend = ca.custid -- agent
		INNER JOIN #GroupHeadline hed WITH (NOLOCK) ON ca.groupID = hed.groupID
	WHERE r.ErrorCode IS NULL AND r.GroupHeadline IS NULL

	UPDATE r
	SET r.GroupHeadline = hed.CustID, r.HeadlineType = hed.HeadlineType
	FROM #result r	
		INNER JOIN custAccount ca WITH (NOLOCK) ON r.custid = ca.custid -- member
		INNER JOIN #GroupHeadline hed WITH (NOLOCK) ON ca.groupID = hed.groupID
	WHERE r.ErrorCode IS NULL AND r.GroupHeadline IS NULL

	;WITH Super AS
	(
		SELECT DISTINCT srecommend FROM #result
	)
	INSERT INTO #tmpAccCustGroup (CustID, GroupName)
	SELECT cg.custid, cg.GroupName
	FROM dbo.Acc_CustGroup cg WITH (NOLOCK)
		INNER JOIN Super s ON cg.custid = s.srecommend
		
	INSERT INTO #tmpResult (GroupHeadline, HeadlineType, Currency, Super, Master, Agent, Member, Refno, ErrorCode)
	SELECT STUFF((	SELECT ',' + CASE WHEN t.GroupName = 'AccYen668' THEN 'ETUS(ET688)' 
									  WHEN t.GroupName = 'AccYen789' THEN 'ETUS(ET789)'
									  WHEN t.GroupName = 'AccYen888' THEN 'ETUS(ET888)'
									  WHEN t.GroupName = 'AccYen889' THEN 'ETUS(ET889)'
									  ELSE 'ETUS' END
					FROM #tmpAccCustGroup t
					WHERE t.CustID = r.srecommend
					FOR XML PATH('')), 1, 1, '') AS GroupHeadline,
		CASE
			WHEN r.HeadlineType = 1 THEN 'VIP'
			WHEN ISNULL(r.HeadlineType, 0) = 0 AND r.ErrorCode IS NULL THEN 'Normal'
			ELSE NULL END AS HeadlineType,
		e.currency AS Currency,
		s.username AS Super,
		m.username AS Master,
		a.username AS Agent,
		r.inputUsername AS Member,
		r.Refno,
		r.ErrorCode
	FROM #result r
		LEFT JOIN Customer a WITH (NOLOCK) ON r.recommend = a.custid
		LEFT JOIN Customer m WITH (NOLOCK) ON r.mrecommend = m.custid
		LEFT JOIN Customer s WITH (NOLOCK) ON r.srecommend = s.custid
		LEFT JOIN Customer h WITH (NOLOCK) ON r.GroupHeadline = h.custid
		LEFT JOIN Exchange e WITH (NOLOCK) ON r.Currency = e.exchangeid
	WHERE
	(
		@HeadlineType = 2
		OR (@HeadlineType = 1 AND r.HeadlineType = 1)
		OR (@HeadlineType = 0 AND ISNULL(r.HeadlineType, 0) = 0)
	)
	AND h.username = 'ETUS'
	
	UPDATE #tmpresult
	SET GroupHeadline = 'ETUS'
	WHERE GroupHeadline IS NULL

	INSERT INTO #tmpResult (GroupHeadline, HeadlineType, Currency, Super, Master, Agent, Member, Refno, ErrorCode)
	SELECT
		h.username AS GroupHeadline,
		CASE
			WHEN r.HeadlineType = 1 THEN 'VIP'
			WHEN ISNULL(r.HeadlineType, 0) = 0 AND r.ErrorCode IS NULL AND r.GroupHeadline IS NOT NULL THEN 'Normal'
			ELSE NULL END AS HeadlineType,
		e.currency AS Currency,
		s.username AS Super,
		m.username AS Master,
		a.username AS Agent,
		r.inputUsername AS Member,
		r.Refno,
		r.ErrorCode
	FROM #result r
		LEFT JOIN Customer a WITH (NOLOCK) ON r.recommend = a.custid
		LEFT JOIN Customer m WITH (NOLOCK) ON r.mrecommend = m.custid
		LEFT JOIN Customer s WITH (NOLOCK) ON r.srecommend = s.custid
		LEFT JOIN Customer h WITH (NOLOCK) ON r.GroupHeadline = h.custid
		LEFT JOIN Exchange e WITH (NOLOCK) ON r.Currency = e.exchangeid
	WHERE
	(
		(
			@HeadlineType = 2
			OR (@HeadlineType = 1 AND r.HeadlineType = 1)
			OR (@HeadlineType = 0 AND ISNULL(r.HeadlineType, 0) = 0)
		)
		AND ISNULL(h.username, '') <> 'ETUS'
	)
	OR r.ErrorCode IS NOT NULL
			
	-- Total rows
	SELECT @TotalRows = COUNT(1) FROM #tmpresult

	-- Return result
	IF ((@PageSize <= 0) AND (@PageIndex <= 0))
	BEGIN
		SELECT ErrorCode, GroupHeadLine, HeadlineType, Currency, Super, Master, Agent, Member, Refno,
			ROW_NUMBER() OVER(ORDER BY ErrorCode, HeadlineType DESC, GroupHeadLine, Currency, Super, Master, Agent, Member, RefNo) AS RowNum
		FROM #tmpresult
	END
	ELSE
	BEGIN
		;WITH Pag AS
		(
			SELECT *, ROW_NUMBER() OVER(ORDER BY ErrorCode, HeadlineType DESC, GroupHeadLine, Currency, Super, Master, Agent, Member, RefNo) AS RowNum
			FROM #tmpresult
		)
		SELECT ErrorCode, GroupHeadLine, HeadlineType, Currency, Super, Master, Agent, Member, Refno, RowNum
		FROM Pag
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END

	IF @ProductID IN (1, 3, 5, 27)
	BEGIN
		DECLARE @IsOutright BIT = 0

		SELECT @MatchId = ISNULL(@MatchId,0), @MessageId = ISNULL(@MessageId, 0)
		
		IF EXISTS(SELECT TOP(1) 1 FROM #result WHERE ErrorCode IS NOT NULL)
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'There is an error in the uploaded file.'
			RETURN
		END

		IF EXISTS (SELECT TOP(1) 1 FROM #result r GROUP BY r.Refno HAVING COUNT(1) > 1)
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Some Ticket Ref No are duplicated. Please check again.'
			RETURN
		END	
			
		/*
		EventType = 0: Can't join with any table 
					1: Match
					2: Outright
					3: VSOutright/VSRaceInfo: (bettrans.MatchId = VSRaceInfo .EventID)
					   + VSRaceInfo table contains event info (not have Eventdate)
					   + VSOutright table contains eventId and Race info (can get Event date from this table or bettrans.winlostdate)
					(can get eventdate form VsraceInfo.Eventtime column)
					9: League
		*/
		UPDATE r
			SET r.ProductId = s.ProductID, 
				r.EventType = CASE WHEN s.bettype IN (9, 29, 2799) THEN 1 
							  ELSE s.EventType END, 
				r.MatchId   = CASE WHEN s.bettype IN (9, 29, 2799) THEN @MatchId 
						      ELSE r.MatchId END
		FROM #result r
			INNER JOIN dbo.SportBettypeMatrix s WITH(NOLOCK) ON s.BetType = r.Bettype
		
		SELECT TOP 1 @tmpMatchId = MatchId, @tmpEventType = EventType FROM #result

		--Check whether matchid is required
		SELECT TOP 1
			@ErrCode = CASE WHEN @MatchId = 0 THEN 104
					   ELSE 0 END
			,@ErrMsg = CASE WHEN @ErrCode <> 0 THEN 'Match ID is required!' ELSE '' END
		FROM #Result r 
		WHERE r.EventType NOT IN (0, 2) 

		IF @@ROWCOUNT = 0
		BEGIN
			SET @MatchId = 0 -- Not use param @MatchId
		END
			
		IF @ErrCode <> 0
			RETURN

		/*MatchCode= NULL when EventType <> 0, MatchCode : [ENV][TableNo]-[YYMM]-[MatchCode]*/
		UPDATE r
		SET r.MatchCode = CASE WHEN r.EventType <> 0 THEN NULL
						  ELSE SUBSTRING(r.MatchCode, CHARINDEX('-', r.MatchCode, CHARINDEX('-', r.MatchCode, 0) + 1) + 1, CHARINDEX(';', r.MatchCode + ';', 1) - CHARINDEX('-', r.MatchCode, CHARINDEX('-', r.MatchCode, 0) + 1) -1) END
		FROM #result r

		CREATE CLUSTERED INDEX ix_EventType ON #result (EventType)

		IF @MatchId <> 0
		BEGIN
			DECLARE @EventType VARCHAR(200) = ','

			;WITH CTE AS
			(
				SELECT DISTINCT EventType
				FROM #result
			)
			SELECT @EventType = @EventType + CONVERT(VARCHAR(20), e.EventType) + ','
			FROM CTE e

			--Check match is valid
			DECLARE @IsValidMatchId BIT = 0

			IF @EventType LIKE '%,1,%' -- Match
			BEGIN
				IF EXISTS(SELECT 1 FROM match WITH(NOLOCK) WHERE matchid = @MatchId)
				BEGIN
					SELECT @IsValidMatchId = 1
				END

				IF EXISTS(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @MatchId AND @IsValidMatchId = 0)
				BEGIN
					SELECT @IsValidMatchId = 1
				END
			END
			IF @EventType LIKE '%,3,%' -- VSOutright/VSRaceInfo
			BEGIN
				IF EXISTS(SELECT 1 FROM VSRaceInfo WITH(NOLOCK) WHERE EventID = @MatchId)
				BEGIN
					SELECT @IsValidMatchId = 1
				END

				IF EXISTS(SELECT 1 FROM VSRaceInfo14 WITH(NOLOCK) WHERE EventID = @MatchId AND @IsValidMatchId = 0)
				BEGIN
					SELECT @IsValidMatchId = 1
				END
			END		
						
			IF @IsValidMatchId = 0 
			BEGIN
				SELECT @ErrCode = 107, @ErrMsg = 'Match ID does not exist. Please check!'
				RETURN
			END

			DECLARE @ErrorRefNo TABLE (RefNo BIGINT, Bettype INT, TypeId INT)

			INSERT INTO @ErrorRefNo (RefNo, Bettype)
			SELECT r.Refno, r.Bettype
			FROM #result r
			WHERE r.MatchId <> @MatchId OR r.Bettype IN (9, 29, 2799) OR r.Bettype = 10

			IF EXISTS(SELECT 1 FROM #result WHERE Bettype IN (9, 29, 2799))
			BEGIN
				DELETE r 
				FROM @ErrorRefNo r
				WHERE r.Bettype IN (9, 29 , 2799)
				AND EXISTS(
					SELECT 1
					FROM dbo.bettrans b WITH(NOLOCK)
						INNER JOIN dbo.bettransm m WITH(NOLOCK) ON b.refno = m.refno AND m.matchid = @MatchId
					WHERE b.transid = r.Refno
				)

				DELETE r 
				FROM @ErrorRefNo r
				WHERE r.Bettype IN (9, 29 , 2799)
				AND EXISTS(
					SELECT 1
					FROM dbo.bettrans b WITH(NOLOCK)
						INNER JOIN dbo.bettransm14 m WITH(NOLOCK) ON b.refno = m.refno AND m.matchid = @MatchId
					WHERE b.transid = r.Refno
				)

				DELETE r 
				FROM @ErrorRefNo r
				WHERE r.Bettype IN (9, 29 , 2799)
				AND EXISTS(
					SELECT 1
					FROM dbo.bettrans14 b WITH(NOLOCK)
						INNER JOIN dbo.bettransm14 m WITH(NOLOCK) ON b.refno = m.refno AND m.matchid = @MatchId
					WHERE b.transid = r.Refno
				)

				DELETE r 
				FROM @ErrorRefNo r
				WHERE r.Bettype IN (9, 29 , 2799)
				AND EXISTS(
					SELECT 1
					FROM dbo.bettrans14 b WITH(NOLOCK)
						INNER JOIN dbo.bettransm m WITH(NOLOCK) ON b.refno = m.refno AND m.matchid = @MatchId
					WHERE b.transid = r.Refno
				)
			END

			IF EXISTS(SELECT 1 FROM @ErrorRefNo)
			BEGIN
				SELECT	@ErrCode = 103
						,@ErrMsg = 'All Ticket Ref No have to belong to an event/game! Please check at row: '
						,@ErrMsg = @ErrMsg + STUFF
											 (
												(
													SELECT ',' + CONVERT(VARCHAR(20), i.RowAt)
													FROM @ErrorRefNo e
														INNER JOIN #inputRaw i ON i.RefNo = e.RefNo
													ORDER BY i.RowAt ASC
													FOR XML PATH('')
												),1,1,''
											 )
				RETURN			   	
			END

			--If MatchIds are same but Eventtypes is different
			IF EXISTS(SELECT 1 FROM #result r WHERE r.EventType <> @tmpEventType)
			BEGIN
				DECLARE @TeamName TABLE (Id INT IDENTITY(1, 1), EventType INT, EventName NVARCHAR(2000), ErrorRow VARCHAR(MAX))

				IF EXISTS(SELECT 1 FROM #result WHERE EventType = 1)
				BEGIN
					INSERT INTO @TeamName (EventType, EventName)
					SELECT 1, h.TeamName + ' -vs- ' + a.TeamName
					FROM dbo.match m WITH(NOLOCK)
					CROSS APPLY (SELECT h.teamname FROM Team h WITH(NOLOCK) WHERE h.teamid = m.homeid) AS h(TeamName)
					CROSS APPLY (SELECT a.teamname FROM Team a WITH(NOLOCK) WHERE a.teamid  = m.awayid) AS a(TeamName)
					WHERE m.matchid = @MatchId

					IF NOT EXISTS(SELECT 1 FROM @TeamName WHERE EventType = 1)
					BEGIN
						INSERT INTO @TeamName (EventType, EventName)
						SELECT 1, h.TeamName + ' -vs- ' + a.TeamName
						FROM dbo.match14 m WITH(NOLOCK)
						CROSS APPLY (SELECT h.teamname FROM Team h WITH(NOLOCK) WHERE h.teamid = m.homeid) AS h(TeamName)
						CROSS APPLY (SELECT a.teamname FROM Team a WITH(NOLOCK) WHERE a.teamid  = m.awayid) AS a(TeamName)
						WHERE m.matchid = @MatchId
					END
				END

				IF EXISTS(SELECT 1 FROM #result WHERE EventType = 3)
				BEGIN
					INSERT INTO @TeamName (EventName, EventType, ErrorRow)
					VALUES ('', 3, '')
				END
				UPDATE @TeamName
				SET ErrorRow = 	
				(
						SELECT STUFF
								(
									(
										SELECT ',' + CONVERT(VARCHAR(20), i.RowAt)
										FROM #result r 
											INNER JOIN #inputRaw i ON r.Refno = i.RefNo
										WHERE EventType = 1
										FOR XML PATH('')
									), 1, 1,''
								)
				)
				WHERE EventType = 1

				UPDATE @TeamName
				SET ErrorRow = 	
				(
						SELECT STUFF
								(
									(
										SELECT ',' + CONVERT(VARCHAR(20), i.RowAt)
										FROM #result r 
											INNER JOIN #inputRaw i ON r.Refno = i.RefNo
										WHERE EventType = 3
										FOR XML PATH('')
									), 1, 1,''
								)
				)
				WHERE EventType = 3
				/*
				Message : All Ticket Ref No have to belong to an event/game! Please check:
							Group 1 (<Event 1>): row <row1>, <row3>
							Group 2: row <row2>
				*/
				SELECT @ErrMsg = COALESCE(@ErrMsg, '') + 'Group ' + CONVERT(VARCHAR(MAX), Id) 
								+ CASE WHEN EventName <> '' THEN '(' + EventName + ')'
								  ELSE '' END
								+ ': row ' + ErrorRow + '<br />&emsp;'  
				FROM @TeamName
				ORDER BY Id ASC

				SELECT @ErrCode = 112 ,@ErrMsg = 'All Ticket Ref No have to belong to an event/game! Please check:' + '<br />&emsp;' + @ErrMsg
				RETURN
			END
		END
		ELSE IF @MatchId = 0
		BEGIN
			SET @IsOutright = 0

			IF EXISTS(SELECT 1 FROM #result WHERE Bettype = 10)
			BEGIN
				SET @IsOutright = 1

				IF @MessageId = 0 
				BEGIN
					SELECT @ErrCode = 110, @ErrMsg = 'Message ID is required!'
					RETURN
				END

				DECLARE @Type SMALLINT = 0
 
				SELECT @Type = CASE WHEN r.StatusId = 0  THEN CASE WHEN @Type IN (0, 1) THEN 1 ELSE -1 END
									WHEN r.StatusId <> 0 THEN CASE WHEN @Type IN (0, 2) THEN 2 ELSE -1 END	
							   ELSE NULL END
				FROM #result r

				IF @Type = -1 
				BEGIN
					SELECT @ErrCode = 108, @ErrMsg ='There are both Running and Settled tickets. Please check!'
					RETURN
				END

				IF EXISTS(SELECT 1 FROM #result r WHERE r.MatchId <> @tmpMatchId)
				BEGIN
					UPDATE r
					SET r.MatchId = o.leagueid, r.EventType = 9
					FROM #result r
						INNER JOIN dbo.outright o WITH(NOLOCK) ON r.MatchId = o.orid

					UPDATE r
						SET r.MatchId = o.leagueid, r.EventType = 9
					FROM #result r
						INNER JOIN dbo.outright14 o WITH(NOLOCK) ON r.MatchId = o.orid		
				END	
			END
			;WITH CTE AS 
			(
				SELECT TOP(1)  r.MatchId AS MatchId, r.MatchCode, r.EventType FROM #result r 
			)
			SELECT TOP 1 
					@ErrCode = 103, 
					@ErrMsg = CASE WHEN r.Bettype = 10 THEN  'All Ticket Ref No have to belong to an Outright league!'
							  ELSE 'All Ticket Ref No have to belong to an event/game!' END	  					 
			FROM #result r
				,CTE e 
			WHERE 
			(
				ISNULL(r.MatchId, -1) <> ISNULL(e.MatchId, -1) 
				OR ISNULL(r.MatchCode, '') <> ISNULL(e.MatchCode,'') 
				OR (ISNULL(r.MatchId, -1) = -1 AND ISNULL(r.MatchCode,'') = '')
			) 
		END

		IF @ErrCode <> 0
			RETURN

		IF @ProductID IN (1, 27) AND @IsOutright = 0
		BEGIN
			IF (ISNULL(@ActualResult,'') = '' OR ISNULL(@WrongResult, '') = '') AND @MessageID = 0
			BEGIN
				SELECT @ErrCode = 101, @ErrMsg = 'Actual/Wrong Result OR MessageID are required!'
				RETURN
			END

			IF @MessageID <> 0
				SELECT @ActualResult = '', @WrongResult = '' 
		END
		ELSE
		BEGIN
			SELECT @ActualResult = '', @WrongResult = ''
			IF @IsOutright = 0 
				SET @MessageId = 0
		END

		IF @MessageId <> 0
			SET @IsCheckMessage = 1
	
		SELECT i.RowAt, Custid, inputUsername AS Username, r.Refno, RefTable, Bettype, r.GroupHeadline AS HeadlineId
		FROM #result r
			INNER JOIN #inputRaw i ON i.RefNo = r.Refno

		SELECT TOP(1) 
				ProductId, 
				CASE WHEN EventType = 0 AND RefTable =3 THEN Sporttype ELSE MatchId END MatchId, 
				MatchCode, 
				EventType, 
				WinlostDate		AS EventDate, 
				@MessageId		AS MessageId,
				@ActualResult	AS ActualResult, 
				@WrongResult	AS WrongResult
		FROM #result r

	END

	-- Drop tmp table
	DROP TABLE #GroupHeadline
	DROP TABLE #input
	DROP TABLE #inputRaw
	DROP TABLE #result
	DROP TABLE #tmpAccCustGroup
	DROP TABLE #tmpData
	DROP TABLE #tmpResult
END
GO