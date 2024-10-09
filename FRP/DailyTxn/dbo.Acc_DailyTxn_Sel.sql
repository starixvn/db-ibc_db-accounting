/*<info serverAlias="DBACC-BODB02" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DailyTxn_Sel]
	@fromdate	DATETIME,	
	@Type		NVARCHAR(30) = '',
	@Creator	VARCHAR(30) = '',
	@checkerID	TINYINT = 1 ,
	@checkerName VARCHAR(50) = ''
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
  	- 20230530@Evan: Enhancement for Customer Statement - add output column IsAllowVerify [Redmine: #186750]
	- 20240826@Bobby: Reward Payement transfer [Redmine: #209633]

Param's Explanation: Daily transaction
	@Type   : Dep, Trac, ..
	@Creator: Admin's useranme
	@checkerID: 0 - Unverified ; 1 - All; 2 - Verified
*/
BEGIN
	SET NOCOUNT ON

	-- get BU date
	DECLARE @balanceUpDay SMALLDATETIME
		,	@ArchivedDay	SMALLDATETIME
		,	@ConstraintDay	SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp

	--Check to not allow to veify before balance up date
	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @ConstraintDay =  CASE 
									WHEN @ArchivedDay > @balanceUpDay THEN DATEADD(DAY,7,@balanceUpDay) -- new BU
									ELSE @balanceUpDay -- old BU
								END

	CREATE TABLE #StatementDaily
	(	
		transid BIGINT,
		refno BIGINT,
		username VARCHAR(50), 
		checkerID int,
		checkerName VARCHAR(50),
		checkTime DATETIME,
		transdate SMALLDATETIME, 
		amount MONEY, 
		transdesc NVARCHAR(300), 
		typenamee NVARCHAR(30), 
		creator VARCHAR(30),
		IsAllowVerify BIT DEFAULT 1
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
				creator.username creator,
				CASE WHEN b.WinlostDate < @ConstraintDay THEN 0 ELSE 1 END AS IsAllowVerify
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
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) --Confirmed with PM, BA & QC. Leave it as it is.
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

		UNION ALL
		SELECT	b.transid,
				b.refno,
				ower.username,
				b.CheckId betid, --checkerID      
				checker.username betcheck,--checkerName
				b.checkTime, 
				b.transdate,
				b.credit-b.debit amount,
				b.transdesc, 
				bt.typenamee,
				creator.username creator,
				CASE WHEN b.WinlostDate < @ConstraintDay THEN 0 ELSE 1 END AS IsAllowVerify
		FROM dbo.TransferExtra b with (nolock)
			INNER JOIN CustSuper s with (nolock) on b.srecommend = s.custid 
			INNER JOIN customer creator WITH (NOLOCK) on creator.custid=b.creator
			INNER JOIN bettype bt WITH (NOLOCK) on bt.typeid=b.bettype
			INNER JOIN customer checker WITH(NOLOCK) ON checker.custid=b.CheckId
			INNER JOIN customer ower WITH(NOLOCK) ON ower.custid=b.custid
		WHERE
			bt.typeid > 30000
			AND b.WinlostDate >= @balanceUpDay
			AND creator.roleid > 4 
			AND s.isInternal = 1 
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) --Confirmed with PM, BA & QC. Leave it as it is.
			AND CASE WHEN @Type <> '' THEN bt.typenamee ELSE @Type END = @Type 
			AND CASE WHEN @Creator <> '' THEN creator.username ELSE @Creator END = @Creator 
			AND CASE WHEN @checkerName <> '' AND @checkerID = 1 THEN checker.username ELSE @checkerName END = @checkerName 
			AND CASE   
				WHEN @checkerID = 0 THEN ISNULL(b.CheckId,0)
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
				creator.username creator,
				CASE WHEN b.WinlostDate < @ConstraintDay THEN 0 ELSE 1 END AS IsAllowVerify
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
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) --Confirmed with PM, BA & QC. Leave it as it is.
			AND CASE WHEN @Type <> '' AND @Type <> 'Coll' THEN bt.typenamee ELSE @Type END = @Type 
			AND (
					(@Type LIKE 'Trac' AND ISNULL(t.IsCollection,0) = 0) 
					OR (@Type LIKE 'Coll' AND ISNULL(t.IsCollection,0) = 1) 
					OR (@Type NOT LIKE 'Trac' AND @Type NOT LIKE 'Coll')
				) 
			AND CASE WHEN @Creator <> '' THEN creator.username ELSE @Creator END = @Creator 
			AND CASE WHEN @checkerName <> '' THEN t.CheckerName ELSE @checkerName END = @checkerName 
			AND ISNULL(t.CheckerId,0) <> 0 

		UNION ALL
		SELECT	b.transid,
				b.refno,
				ower.username,
				b.CheckId betid, --checkerID      
				checker.username betcheck,--checkerName
				b.checkTime, 
				b.transdate,
				b.credit-b.debit amount,
				b.transdesc, 
				bt.typenamee,
				creator.username creator,
				CASE WHEN b.WinlostDate < @ConstraintDay THEN 0 ELSE 1 END AS IsAllowVerify
		FROM dbo.TransferExtra b WITH(NOLOCK)
			INNER JOIN CustSuper s WITH(NOLOCK) ON b.srecommend = s.custid 
			INNER JOIN customer creator WITH(NOLOCK) ON creator.custid=b.creator
			INNER JOIN bettype bt WITH(NOLOCK) ON bt.typeid=b.bettype
			INNER JOIN customer checker WITH(NOLOCK) ON checker.custid=b.CheckId
			INNER JOIN customer ower WITH(NOLOCK) ON ower.custid=b.custid
		WHERE
			bt.typeid > 30000 
			AND b.WinlostDate >= @balanceUpDay
			AND creator.roleid > 4 
			AND s.isInternal = 1 
			AND b.winlostdate between @fromdate AND Dateadd(d,1,@fromdate) --Confirmed with PM, BA & QC. Leave it as it is.
			AND CASE WHEN @Type <> '' THEN bt.typenamee ELSE @Type END = @Type 
			AND CASE WHEN @Creator <> '' THEN creator.username ELSE @Creator END = @Creator 
			AND CASE WHEN @checkerName <> '' THEN checker.username ELSE @checkerName END = @checkerName 
			AND ISNULL(b.CheckId,0) <> 0 
	END 

	SELECT * 
	FROM #StatementDaily
	ORDER BY transid

	DROP TABLE #StatementDaily 

END
