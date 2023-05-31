/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DailyTxn_UpdChecker]
@CheckerID		INT,
@CheckerName	VARCHAR(50),
@Refnos			VARCHAR(8000),
@IsVerified		BIT = 0, 
@IP				VARCHAR(45),
@ErrCode		INT = 0 OUTPUT,
@ErrMsg			NVARCHAR(200) = '' OUTPUT,
@SiteDBGroupID	SMALLINT
AS
/*
Created by: Jamie
Date: 2010-09-18 
Task : Daily Transaction - Update Checker 
DB: DBTXN/bodb02

Revisions:
	- 20101229@Lukas: Re-arrange bettype
	- 20130201@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20211122@Danny: Split transfer tickets out of bettrans [Redmine: #164196]
	- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
	- 20220825@Danny: change code to support SiteDB [Redmine: #175253]
	- 20220830@Danny: add filter to Remove orphan ticket [Redmine: #175253]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
	- 20230530@Evan: Not allow verify before balance up date [Redmine: #186750]

Param's Explanation:
	@TransIDs   : '1111,2341,...'
*/
BEGIN
	SET NOCOUNT ON
		
	-- get BU date
	DECLARE @balanceUpDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay FROM @tblMoveBetBalanceUp

	--Check permission for account site
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @CheckerID, @funcname = '[DailyFinanceTxn]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		IF @ErrCode <> 0 
			RETURN

	DECLARE	@UserID INT, @ActionID INT, @UserName VARCHAR(50)
	SELECT	@UserID = @CheckerID, @Username = @CheckerName , @ActionID = 1600 

	DECLARE	@tmpRefNo TABLE (RefNo BIGINT, TransID BIGINT, Checktime DATETIME, RepUpdateTime DATETIME2(7), custID INT, IsMoving BIT, IsVerified BIT)
	DECLARE	@tmpTransID TABLE (transID BIGINT, checktime DATETIME, RepUpdateTime DATETIME2(7), custID INT)
	DECLARE @SiteGroupInfo TABLE(CustID INT, SiteDBGroupID SMALLINT, LinkedServerName  VARCHAR(512), ClientAccessName VARCHAR(512), AGIP VARCHAR (50))
	DECLARE @CustList TABLE (CustID INT, ID INT IDENTITY(1,1) )

	--Check to not allow to veify before balance up date
	DECLARE @ArchivedDay SMALLDATETIME
		, @ConstraintDay SMALLDATETIME

	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @ConstraintDay =  CASE 
									WHEN @ArchivedDay > @balanceUpDay THEN DATEADD(DAY,7,@balanceUpDay) -- new BU
									ELSE @balanceUpDay -- old BU
								END
	
	INSERT INTO @tmpRefNo (RefNo, TransID, Checktime, RepUpdateTime, CustID, IsMoving, IsVerified)
	SELECT	t.refno,
			t.transID,
			t.checktime,
			t.RepUpdateTime,
			t.custID,
			CASE WHEN t.WinlostDate < @ConstraintDay THEN 1 ELSE 0 END AS IsMoving,
			CASE WHEN ti.CheckerId IS NULL THEN 0 ELSE 1 END AS IsVerified
	FROM	dbo.Transfer t WITH (NOLOCK) 
			LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK) ON t.TransID = ti.TransId 
	WHERE	RefNo IN (	SELECT	CONVERT(BIGINT, VALUE)
						FROM	STRING_SPLIT (@Refnos, ',' ))
			AND bettype > 20000 
			AND CustID <> 0

	INSERT INTO @tmpTransID(transID, checktime, RepUpdateTime, custID)
	SELECT	transID,
			checktime,
			RepUpdateTime,
			CustId 
	FROM	@tmpRefNo 
	WHERE	IsMoving = 0 
		AND IsVerified = CASE WHEN @IsVerified = 1 THEN 0 ELSE IsVerified END
	
	-- get CustList by SiteDbGroupID
	INSERT INTO @CustList(CustID) SELECT DISTINCT CustID FROM  @tmpTransID 

	DECLARE @cs_CustID INT
	DECLARE @i INT = 1

	WHILE EXISTS (SELECT TOP 1 1 FROM @CustList WHERE ID = @i)
	BEGIN
		SELECT @cs_CustID = CustID FROM @CustList WHERE ID = @i

		INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
		EXEC CustDB.dbo.Acc_SiteDBConfigSel @CustID = @cs_CustID

		UPDATE @SiteGroupInfo SET CustID = @cs_CustID WHERE CustID IS NULL

		SELECT @i = @i + 1
	END

	DELETE t
	FROM @tmpTransID t
	WHERE t.CustID IN (SELECT z.CustID FROM  @SiteGroupInfo z WHERE z.SiteDBGroupID <> @SiteDBGroupID )
	-- END get CustList by SiteDbGroupID

	IF @IsVerified = 0 
	BEGIN
		SELECT	@ActionID = 1601, @CheckerID = NULL, @CheckerName ='0'
	END

	UPDATE	dbo.Transfer WITH (UPDLOCK,ROWLOCK)
	SET		checkTime = GETDATE(),
			RepUpdateTime = SYSDATETIME()
	WHERE	transID IN (SELECT transID FROM @tmpTransID) 

	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Update failed. Please try again.'
				,@ErrCode = 100
			
		RETURN
	END

	MERGE dbo.TransferInfo t
	USING @tmpTransID s ON t.transid=s.transid
	WHEN MATCHED THEN
		UPDATE SET	t.CheckerId = @CheckerID, 
					t.CheckerName = @CheckerName,
					t.RepUpdateTime = SYSDATETIME()
	WHEN NOT MATCHED THEN
		INSERT (Transid, CheckerId, CheckerName, RepUpdateTime)
		VALUES (s.Transid, @CheckerID, @CheckerName, SYSDATETIME());

	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrMsg = 'Update failed. Please try again.'
				,@ErrCode = 100

		UPDATE	t
		SET		t.CheckTime = u.CheckTime,
				t.RepUpdateTime = u.RepUpdateTime
		FROM dbo.Transfer t WITH (UPDLOCK,ROWLOCK)
		INNER JOIN @tmpTransID u ON t.transID = u.TransID
		RETURN
	END

	--List number of Refno executed
	SELECT DISTINCT 
		a.RefNo, 
		CASE WHEN b.transID IS NULL THEN 0 ELSE 1 END AS Success, 
		CASE WHEN a.IsMoving = 1 THEN 'Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @constraintDay, 120) + '.'
			WHEN a.IsVerified = 1 AND @IsVerified = 1 THEN 'Unable to verify this transaction due to it is marked as "Verified"!' END AS ErrMsg
	FROM @tmpRefNo a 
		LEFT JOIN @tmpTransID b ON a.TransID = b.transID

	DECLARE	@LogData VARCHAR(1000)
	SELECT	@LogData = '<Acc_DailyTxn_UpdChecker CheckerName="'+ @Username +'" />'

	--ActionID: 1600 - Verify; 1601 - Unverify 
	BEGIN TRY
		INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(BIGINT, VALUE),@ActionID, @IP, @LogData
		FROM	STRING_SPLIT (@Refnos, ',' )
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_DailyTxn_UpdChecker CheckerName="'+ @Username +
						  '" ErrMsg="' + error_message() + '" />'
		INSERT INTO bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(BIGINT, VALUE),@ActionID, @IP, @LogData
		FROM	STRING_SPLIT (@Refnos, ',' )
	END CATCH
END
GO