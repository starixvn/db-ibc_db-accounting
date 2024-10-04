/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_RewardPayment_UpdChecker
	@CheckerID		INT,
	@CheckerName	VARCHAR(50),
	--@Refnos			VARCHAR(8000),
	@Refno			BIGINT,
	@SiteDBGroupID	SMALLINT,
	@IsVerified		BIT = 0, 
	@IP				VARCHAR(45),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
	
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Reward Transfer
	DB: DBACC.bodb02
	ORIGINAL: Acc_AllStatement4Agent

	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @Server_SiteDBGroupID SMALLINT;

	--Check the SiteDBGroupID of CustID and Server is match
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID();
	IF ISNULL(@SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.'
		RETURN;		
	END

	-- get BU date
	DECLARE @balanceUpDay	SMALLDATETIME,
		@ArchivedDay		SMALLDATETIME,
		@ConstraintDay		SMALLDATETIME
	;
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT;

	--Check to not allow to veify before balance up date
	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @ConstraintDay = CASE 
								WHEN @ArchivedDay > @balanceUpDay THEN DATEADD(DAY,7,@balanceUpDay) -- new BU
								ELSE @balanceUpDay -- old BU
							END

	DECLARE	@UserID INT, @ActionID INT, @UserName VARCHAR(50)
	SELECT	@UserID = @CheckerID, @Username = @CheckerName , @ActionID = 1600 

	DECLARE	@tmpRefNo TABLE (RefNo BIGINT, TransID BIGINT, Checktime DATETIME, RepUpdateTime DATETIME2(7), custID INT, IsMoving BIT, IsVerified BIT, TransTable VARCHAR(30), CheckerId INT)
	DECLARE	@tmpTransInfo TABLE (transID BIGINT, checktime DATETIME, RepUpdateTime DATETIME2(7), custID INT, CheckerId INT)

	--TODO: Fetch transfer & TransferExtra by RefNo
	;WITH CTE_RefNo AS (
		SELECT @Refno AS RefNo
	)
	INSERT INTO @tmpRefNo (RefNo, TransID, Checktime, RepUpdateTime, CustID, IsMoving, IsVerified, TransTable, CheckerId)
	SELECT	t.refno,
			t.transID,
			t.checktime,
			t.RepUpdateTime,
			t.custID,
			CASE WHEN t.WinlostDate < @ConstraintDay THEN 1 ELSE 0 END AS IsMoving,
			CASE WHEN ti.CheckerId IS NULL THEN 0 ELSE 1 END AS IsVerified,
			'Transfer' AS TransTable,
			ti.CheckerId
	FROM	dbo.[Transfer] t WITH (NOLOCK) 
		INNER JOIN CTE_RefNo tmp ON tmp.RefNo = t.RefNo
		LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK) ON t.TransID = ti.TransId 
	WHERE	bettype > 20000 
			AND CustID > 0

	UNION ALL
	--TODO: collect old info - [TransferExtra]
	SELECT	t.refno,
			t.transID,
			t.checktime,
			t.RepUpdateTime,
			t.custID,
			CASE WHEN t.WinlostDate < @ConstraintDay THEN 1 ELSE 0 END AS IsMoving,
			CASE WHEN t.CheckId IS NULL THEN 0 ELSE 1 END AS IsVerified,
			'TransferExtra' AS TransTable, 
			t.CheckId
	FROM	dbo.[TransferExtra] t WITH (NOLOCK) 
		INNER JOIN CTE_RefNo tmp ON tmp.RefNo = t.RefNo
	WHERE	bettype > 30000 
			AND CustID > 0
	
	--TODO: save rollback info
	INSERT INTO @tmpTransInfo(transID, checktime, RepUpdateTime, custID, CheckerId)
	SELECT t.transID,
		t.checktime,
		t.RepUpdateTime,
		t.CustId,
		t.CheckerId
	FROM @tmpRefNo t
		INNER JOIN CustDB.dbo.[Customer] ci WITH(NOLOCK) ON ci.custid = t.custid
		INNER JOIN CustDB.dbo.[Site] s WITH(NOLOCK) ON s.[site] = ci.[site]
	WHERE s.SiteDBGroupID = @Server_SiteDBGroupID
		AND t.IsMoving = 0 
		AND t.IsVerified = IIF(@IsVerified = 1, 0, 1)  --0-Verify/1-Unverify

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg = CONCAT('There is no transfer to ', IIF(@IsVerified = 1, ' verify', 'unverify') ,'.')
		RETURN;	
	END
	
	IF @IsVerified = 0 
	BEGIN
		SELECT	@ActionID = 1601, @CheckerID = NULL, @CheckerName ='0'
	END

	--TODO: control flow
	DECLARE @stepDone	TINYINT = 0,
		@checkTime		DATETIME
	;

	BEGIN TRY
		SET @checkTime = GETDATE();

		BEGIN TRAN
		--TODO: Verify/UnVerify transfer
		UPDATE	dbo.Transfer WITH (UPDLOCK,ROWLOCK)
		SET		checkTime = IIF(@IsVerified=1, @checkTime, NULL),
				RepUpdateTime = SYSDATETIME()
		WHERE transID IN (SELECT transID FROM @tmpTransInfo) 
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 1), 0);

		--TODO: Verify/UnVerify transferExtra
		UPDATE	dbo.TransferExtra WITH (UPDLOCK,ROWLOCK)
		SET		checkTime = IIF(@IsVerified=1, @checkTime, NULL),
				checkId = @CheckerID,
				RepUpdateTime = SYSDATETIME()
		WHERE	transID IN (SELECT transID FROM @tmpTransInfo) 
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 2), 0);

		--TODO: Verify/UnVerify transferInfo
		MERGE dbo.TransferInfo t
		USING @tmpTransInfo s ON t.transid=s.transid
		WHEN MATCHED THEN UPDATE 
			SET	t.CheckerId = @CheckerID, 
				t.CheckerName = @CheckerName,
				t.RepUpdateTime = SYSDATETIME()
		WHEN NOT MATCHED THEN
			INSERT (Transid, CheckerId, CheckerName, RepUpdateTime)
			VALUES (s.Transid, @CheckerID, @CheckerName, SYSDATETIME())
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 3), 0);
	
		COMMIT;

		--SELECT @stepDone [@stepDone]
	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT >0
			ROLLBACK;

		SELECT	@ErrMsg = 'Update failed. Please try again.'
				,@ErrCode = 109

		--UPDATE	t
		--SET		t.CheckTime = u.CheckTime,
		--		t.RepUpdateTime = SYSDATETIME()
		--FROM dbo.[Transfer] t WITH (UPDLOCK,ROWLOCK)
		--INNER JOIN @tmpTransInfo u ON t.transID = u.TransID
		--WHERE POWER(2, 1) & @stepDone > 0
		--;

		--UPDATE	t
		--SET		t.CheckTime = u.CheckTime,
		--		t.CheckId	= u.CheckerId,
		--		t.RepUpdateTime = SYSDATETIME()
		--FROM dbo.[TransferExtra] t WITH (UPDLOCK,ROWLOCK)
		--INNER JOIN @tmpTransInfo u ON t.transID = u.TransID
		--WHERE POWER(2, 2) & @stepDone > 0;
	END CATCH

	-- Output for display message
	SELECT DISTINCT 
		a.RefNo, 
		CASE WHEN b.transID IS NULL THEN 0 ELSE 1 END AS Success 
		,CASE WHEN a.IsMoving = 1 THEN 'Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @constraintDay, 120) + '.' END AS ErrMsg
	FROM @tmpRefNo a 
		LEFT JOIN @tmpTransInfo b ON a.TransID = b.transID
	WHERE  a.IsVerified = 0 AND @IsVerified = 1

	DECLARE	@LogData VARCHAR(1000)
	SELECT	@LogData = '<Acc_RewardPayment_UpdChecker CheckerName="'+ @Username +'" />'

	--ActionID: 1600 - Verify; 1601 - Unverify 
	DECLARE @Refnos VARCHAR(8000) = CONCAT('', @Refno);
	BEGIN TRY
		INSERT INTO DBLOG.bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(BIGINT, VALUE),@ActionID, @IP, @LogData
		FROM	STRING_SPLIT (@Refnos, ',' )
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_RewardPayment_UpdChecker CheckerName="'+ @Username +
						  '" ErrMsg="' + error_message() + '" />'
		INSERT INTO bodb_CustomerLog.dbo.UserLog_Transaction(UserID, Refno, ActionID, IP, Doing)
		SELECT	@UserID, CONVERT(BIGINT, VALUE),@ActionID, @IP, @LogData
		FROM	STRING_SPLIT (@Refnos, ',' )
	END CATCH
END
GO