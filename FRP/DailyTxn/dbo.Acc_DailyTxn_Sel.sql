/*<info serverAlias="DBACC-BODB02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DailyTxn_Sel]
	@fromdate	datetime,	
	@Type		nvarchar(30) = '',
	@Creator	varchar(30) = '',
	@checkerID	TINYINT = 1 ,
	@checkerName varchar(50) = ''
as

/*
Created by: Jamie
Date: 2010-09-18
Task : Daily Transaction 
DB: DBACC.bodb02
Original: Acc_RptStatementDaily

Revisions:
	- 20101124@Kevin: Add new parameter is @checkerName. 
	Select all transactions what verified by that user.	
	- 20101225@Lukas: Re-arrange bettype
	- 20111015@Lukas: remove paging
	- 20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
	- 20211115@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]

Param's Explanation: Daily transaction
	@Type   : Dep, Trac, ..
	@Creator: Admin's useranme
	@checkerID: 0 - Unverified ; 1 - All; 2 - Verified
*/
BEGIN
	SET NOCOUNT ON

	-- get BU date
	DECLARE @balanceUpDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp

	CREATE TABLE #StatementDaily
	(	
		transid bigint,
		refno bigint,
		username varchar(50), 
		checkerID int,
		checkerName varchar(50),
		checkTime datetime,
		transdate smalldatetime, 
		amount money, 
		transdesc nvarchar(300), 
		typenamee nvarchar(30), 
		creator varchar(30)
	)

	IF @checkerID in (0,1)
	BEGIN 
		INSERT INTO #StatementDaily
		SELECT	b.transid,
				b.refno,
				b.username,
				t.CheckerId betid, --checkerID      
				t.CheckerName betcheck,--checkerName
				b.checkTime, 
				b.transdate,
				b.winlost-b.actual_stake amount,
				b.transdesc, 
				CASE WHEN bt.typeId = 21003 AND ISNULL(t.IsCollection,0) = 1 THEN 'Coll' ELSE bt.typenamee END typenamee,
				creator.username creator
		FROM dbo.Transfer b with (nolock)
			INNER JOIN CustSuper s with (nolock) on b.srecommEND = s.custid 
			INNER JOIN customer creator WITH (NOLOCK) on creator.custid=b.creator
			INNER JOIN bettype bt WITH (NOLOCK) on bt.typeid=b.bettype
			LEFT JOIN dbo.TransferInfo t WITH (NOLOCK) ON b.TransId = t.TransId
		WHERE
			bt.typeid > 20000
			AND b.WinlostDate >= @balanceUpDay
			AND creator.roleid > 4 
			AND s.isInternal = 1 
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) 
			AND CASE WHEN @Type <> '' AND @Type <> 'Coll' THEN bt.typenamee ELSE @Type END = @Type 
			AND	(
					(@Type LIKE 'Trac' AND ISNULL(t.IsCollection,0) = 0) 
					OR (@Type LIKE 'Coll' AND ISNULL(t.IsCollection,0) = 1) 
					OR (@Type NOT LIKE 'Trac' AND @Type NOT LIKE 'Coll')
				) 
			AND CASE WHEN @Creator <> '' THEN creator.username ELSE @Creator END = @Creator 
			AND CASE WHEN @checkerName <> '' AND @checkerID = 1 THEN t.CheckerName ELSE @checkerName END = @checkerName 
			AND CASE   
				WHEN @checkerID = 0 THEN ISNULL(t.CheckerId,0)
				WHEN @checkerID = 1 THEN @checkerID  				
				END = @checkerID 
	
	END 
	ELSE 
	BEGIN
		INSERT INTO #StatementDaily
		SELECT	b.transid,
				b.refno,
				b.username,
				t.CheckerId betid, --checkerID      
				t.CheckerName betcheck,--checkerName
				b.checkTime, 
				b.transdate,
				b.winlost-b.actual_stake amount,
				b.transdesc, 
				CASE WHEN bt.typeId = 21003 AND ISNULL(t.IsCollection,0) = 1 THEN 'Coll' ELSE bt.typenamee END typenamee,
				creator.username creator
		FROM dbo.Transfer b WITH(NOLOCK)
			INNER JOIN CustSuper s WITH(NOLOCK) ON b.srecommEND = s.custid 
			INNER JOIN customer creator WITH(NOLOCK) ON creator.custid=b.creator
			INNER JOIN bettype bt WITH(NOLOCK) ON bt.typeid=b.bettype
			LEFT JOIN dbo.TransferInfo t WITH (NOLOCK) ON b.TransId = t.TransId
		WHERE
			bt.typeid > 20000 
			AND b.WinlostDate >= @balanceUpDay
			AND creator.roleid > 4 
			AND s.isInternal = 1 
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) 
			AND CASE WHEN @Type <> '' AND @Type <> 'Coll' THEN bt.typenamee ELSE @Type END = @Type 
			AND (
					(@Type LIKE 'Trac' AND ISNULL(t.IsCollection,0) = 0) 
					OR (@Type LIKE 'Coll' AND ISNULL(t.IsCollection,0) = 1) 
					OR (@Type NOT LIKE 'Trac' AND @Type NOT LIKE 'Coll')
				) 
			AND CASE WHEN @Creator <> '' THEN creator.username ELSE @Creator END = @Creator 
			AND CASE WHEN @checkerName <> '' THEN t.CheckerName ELSE @checkerName END = @checkerName 
			AND ISNULL(t.CheckerId,0) <> 0 
	END 



	SELECT * 
	FROM #StatementDaily
	ORDER BY transid

	DROP TABLE #StatementDaily 

END
