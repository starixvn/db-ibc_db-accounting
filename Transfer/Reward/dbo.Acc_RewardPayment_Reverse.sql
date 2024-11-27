/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_RewardPayment_Reverse]
	@RefNo			BIGINT,
	@Creator		INT,
	@SiteDBGroupId	SMALLINT,
	@IP				VARCHAR(45)	= '',
	@Language		VARCHAR(2)	= 'E',
	@ErrCode		INT	=	0	OUTPUT,
	@ErrMsg			NVARCHAR(200) =	''	OUTPUT,
	@PaymentLog		NVARCHAR(MAX) = NULL OUTPUT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Add new transfer - reverse
	DB: DBAGE.bodb02
	
	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @FromCustId		INT,
		@roleId				INT,
		@transId			BIGINT,
		@currencyId			INT,
		@actualRate			FLOAT,
		@walletId			TINYINT = 2, --1: RewardPayment wallet, 2: Reward wallet
		@statusId			TINYINT = 131, --0:Pending, 1: completed
		@transDate			DATETIME,
		@winlostDate		SMALLDATETIME,
		@Server_SiteDBGroupID SMALLINT,
		@IsReversed			BIT = 1,
		@rowInput			INT = 0,
		@rowCheck			INT = 0	
	;

	--Check the SiteDBGroupID of CustID and Server is match
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID();
	IF ISNULL(@SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.'
		RETURN;		
	END

	--Check to not allow to veify before balance up date
	DECLARE @ArchivedDay	SMALLDATETIME,
		@ConstraintDay		SMALLDATETIME,
		@balanceUpDay		SMALLDATETIME
	;
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @balanceUpDay OUTPUT;

	SELECT @ArchivedDay	= MAX(winlostdate)
	FROM bodb02.dbo.Task_ArchiveDate WITH (NOLOCK);

	SELECT @ConstraintDay = CASE 
								WHEN @ArchivedDay > @balanceUpDay THEN DATEADD(DAY,7,@balanceUpDay) -- new BU
								ELSE @balanceUpDay -- old BU
							END
	;

	DROP TABLE IF EXISTS #reversalTransfer;
	CREATE TABLE #reversalTransfer (rIdx INT IDENTITY(1, 1) PRIMARY KEY, CustId INT, TransId BIGINT, RefNo BIGINT, IsReversed BIT, ReversalTransId BIGINT, 
		TransTable VARCHAR(30),
		IsMoving BIT,
		RoleId TINYINT
	);

	WITH CTE_RefNo (RefNo) AS (
		SELECT @RefNo
	)
	INSERT INTO #reversalTransfer (CustId, TransId, RefNo, IsReversed, TransTable, IsMoving)
	SELECT st.custid, st.TransId, st.RefNo, ISNULL(ti.IsDel,0) AS IsReversed, 'Transfer' AS TransTable,
		CASE WHEN st.WinlostDate < @ConstraintDay THEN 1 ELSE 0 END AS IsMoving
	FROM CTE_RefNo tmp
		INNER JOIN  dbo.[Transfer] st WITH(NOLOCK) ON st.RefNo = tmp.RefNo
		LEFT JOIN dbo.TransferInfo ti WITH(NOLOCK) ON ti.transid = st.transid
	WHERE ISNULL(ti.IsDel,0) = 0
		AND st.custid > 0
		
	--UNION ALL ---TransferExtra
	--TODO: transferExtra
	IF OBJECT_ID(N'dbo.TransferExtra') > 0
	BEGIN
		WITH CTE_RefNo (RefNo) AS (
			SELECT @RefNo
		)
		INSERT INTO #reversalTransfer (CustId, TransId, RefNo, IsReversed, TransTable, IsMoving)
		SELECT st.custid, st.TransId, st.RefNo, ISNULL(st.IsReversed, 0), 'TransferExtra',
			CASE WHEN st.WinlostDate < @ConstraintDay THEN 1 ELSE 0 END AS IsMoving
		FROM CTE_RefNo tmp
			INNER JOIN  dbo.TransferExtra st WITH(NOLOCK) ON st.RefNo = tmp.RefNo
		WHERE ISNULL(st.IsReversed,0) = 0
			AND st.custid > 0
	END

	--CONFIRM: siteDB
	UPDATE t
	SET roleId = ci.roleId
	FROM #reversalTransfer t
		INNER JOIN CustDB.dbo.[Customer] ci WITH(NOLOCK) ON ci.custid = t.custid
		INNER JOIN CustDB.dbo.[Site] s WITH(NOLOCK) ON s.[site] = ci.[site]
	WHERE s.SiteDBGroupID = @Server_SiteDBGroupID
	;SET @rowCheck = @@ROWCOUNT;

	--select * from #reversalTransfer;
	IF @rowCheck = 0
		OR EXISTS (SELECT 1 FROM #reversalTransfer WHERE IsMoving = 1 OR RoleID IS NULL)
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg		= 'Sorry, reversal transfer(s) is invalid.'
		RETURN;
	END

	--TODO: Process reversing tickets
	DECLARE @rTransId BIGINT, @rRow INT = 1;
	WHILE EXISTS (SELECT 1 FROM #reversalTransfer WHERE rIdx = @rRow)
	BEGIN
		SET @rTransId = 0;
		EXEC dbo.Get_Bettrans_TransID @TransID = @rTransId OUTPUT;

		UPDATE #reversalTransfer
		SET ReversalTransId = @rTransId
		WHERE rIdx = @rRow

		SET @rRow += 1;
	END

	IF EXISTS (SELECT 1 FROM #reversalTransfer WHERE ReversalTransId IS NULL)
	BEGIN
		SELECT @ErrCode = 103,
			@ErrMsg = 'Generate reversal transid error.'
		RETURN;		
	END

	--TODO: Check RewardPayment to rollback
	SELECT TOP(1)
		@FromCustId		= custid,
		@roleId			= roleId
	FROM #reversalTransfer 
	WHERE TransTable = 'TransferExtra'
	;

	--TODO: Control flow
	DECLARE @stepDone	SMALLINT,
		@confirmData	NVARCHAR(MAX),
		@IsDirectCheck	BIT
	;

	BEGIN TRY
		SELECT @transDate	= GETDATE(),
			@stepDone		= 0
		;

		BEGIN TRAN -- T1 & T2
		--TODO: T1 - Add (Reversal) transfer T1.1
		INSERT INTO dbo.[Transfer](
			transid, creator, custid, username, refno, transdate, bettype, transdesc, 
			winlost, actual_stake, --> reverse
			winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			scomm, swinlost, [ip], statusID, RepUpdateTime
		)
		SELECT tmp.ReversalTransId AS transid, @creator AS creator, tmp.custid, username, tmp.refno, @TransDate AS transdate, bettype, CONCAT('(Reversal) ', st.TransDesc) AS transdesc, 
			actual_stake, winlost, --> reverse
			winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
			scomm, swinlost, @IP AS [ip], statusID, SYSDATETIME() AS RepUpdateTime
		FROM dbo.[Transfer] st WITH(NOLOCK)
			INNER JOIN #reversalTransfer tmp ON tmp.transid = st.transid
		WHERE TransTable = 'Transfer'
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 1), 0);

		--TODO: T1 - Update (Reversal - IsDel) transferInfo - T1.2
		;WITH CTE_TransferId AS (
			SELECT ck.transid
			FROM #reversalTransfer t
			CROSS APPLY (VALUES (t.TransId), (t.ReversalTransId)) AS ck (transid)
			WHERE t.TransTable = 'Transfer'
		)
		MERGE dbo.TransferInfo t
		USING CTE_TransferId s ON t.transid = s.transid
		WHEN MATCHED THEN UPDATE 
			SET	t.IsDel = 1, t.RepUpdateTime = SYSDATETIME()
		WHEN NOT MATCHED THEN
			INSERT (Transid, IsDel, RepUpdateTime)
			VALUES (s.Transid, 1, SYSDATETIME())
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 2), 0);

		--TODO: T2 - Add (Reversal) transferExtra T2.1
		IF OBJECT_ID(N'dbo.TransferExtra') > 0
		BEGIN
			INSERT INTO dbo.TransferExtra(
				TransId
				,CustID
				,Recommend
				,Mrecommend
				,Srecommend
				,CurrencyID
				,ActualRate
				,Bettype
				,Credit
				,Debit
				,TransDate
				,WinlostDate
				,TransDesc
				,RefNo
				,WalletID
				,Creator
				,SiteDBGroupID
				,RepUpdateTime
				,IsReversed
			)
			SELECT tmp.ReversalTransId
				,st.CustID
				,st.Recommend
				,st.Mrecommend
				,st.Srecommend
				,st.CurrencyID
				,st.ActualRate
				,st.Bettype
				,st.Debit
				,st.Credit
				,@TransDate AS TransDate
				,st.WinlostDate
				,CONCAT('(Reversal) ', st.TransDesc)
				,st.RefNo
				,st.WalletID
				,@Creator AS Creator
				,st.SiteDBGroupID
				,SYSDATETIME() AS RepUpdateTime
				,@IsReversed AS IsReversed
			FROM dbo.TransferExtra st WITH(NOLOCK)
				INNER JOIN #reversalTransfer tmp ON tmp.transid = st.transid
			WHERE tmp.TransTable = 'TransferExtra'
			;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 3), 0);

			--TODO: T2 - Update Orginal transferExtra T2.2
			UPDATE st WITH(ROWLOCK, UPDLOCK)
			SET st.IsReversed = 1
			FROM dbo.TransferExtra st
				INNER JOIN #reversalTransfer tmp ON tmp.transid = st.transid
			WHERE tmp.TransTable = 'TransferExtra'
			;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 4), 0);
		END
		COMMIT;

		--TODO: T3 - DO confirm payment status on @FromCustId
		SELECT @IsDirectCheck	= IIF(@roleId < 4, 1, 0);
		SELECT @confirmData		= (SELECT t.CustId, t.MaxTransId, t.RefNo, t.IsDirect
								FROM (VALUES(@FromCustId, 0, @RefNo, @IsDirectCheck)) AS t (CustId, MaxTransId, RefNo,IsDirect)
								WHERE t.CustId > 0
								FOR JSON PATH);

		--select @confirmData [@confirmData]
		IF ISJSON(@confirmData) = 1
		BEGIN
			SET @PaymentLog = '';
			EXEC dbo.Acc_RewardPayment_Confirm_Rollback 
				@Data			= @confirmData,
				@Creator		= @Creator,
				@ErrCode		= @ErrCode OUTPUT,
				@ErrMsg			= @ErrMsg OUTPUT,
				@PaymentLog		= @PaymentLog OUTPUT
			;
			IF @ErrCode > 0
			BEGIN
				SELECT @ErrCode = 104
					,@ErrMsg	= ISNULL(@ErrMsg, 'Reverse transfer - Rollback payment status failed.')
				RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
			END
			ELSE
				SET @stepDone |= POWER(2, 4) -- Done reverse payment status
		END

	END TRY
	BEGIN CATCH 

		IF @@TRANCOUNT > 0
			ROLLBACK;

		SELECT @ErrCode = 109,
			@ErrMsg = CONCAT('RewardPayment: Reverse transfer failed. Error: ', ERROR_MESSAGE())
		;

		--TODO: T1 rollback if ERROR - T1.1
		UPDATE st
		SET custid = 0, Recommend = 0, Mrecommend=0, Srecommend=0, winlost=0, actual_stake = 0, RepUpdateTime = SYSDATETIME()
		FROM dbo.[Transfer] st WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #reversalTransfer tmp ON tmp.ReversalTransId = st.TransId
		WHERE tmp.TransTable = 'Transfer'
			AND POWER(2, 1) & @stepDone > 0
		;

		--TODO: T1 rollback if ERROR - T1.2
		UPDATE st
		SET IsDel = 0, RepUpdateTime = SYSDATETIME()
		FROM dbo.[TransferInfo] st WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #reversalTransfer tmp ON st.TransId IN (tmp.TransId, tmp.ReversalTransId)
		WHERE tmp.TransTable = 'Transfer'
			AND POWER(2, 2) & @stepDone > 0

		--TODO: T2 rollback if ERROR - T2.1-2
		IF OBJECT_ID(N'dbo.TransferExtra') > 0
		BEGIN
			UPDATE st WITH(ROWLOCK, UPDLOCK)
			SET custid		= IIF(st.TransId = tmp.ReversalTransId, 0, st.custid), 
				Recommend	= IIF(st.TransId = tmp.ReversalTransId, 0, st.Recommend),  
				Mrecommend	= IIF(st.TransId = tmp.ReversalTransId, 0, st.Mrecommend),  
				Srecommend	= IIF(st.TransId = tmp.ReversalTransId, 0, st.Srecommend),  
				Credit		= IIF(st.TransId = tmp.ReversalTransId, 0, st.Credit),  
				Debit		= IIF(st.TransId = tmp.ReversalTransId, 0, st.Debit),  
				IsReversed	= 0, 
				RepUpdateTime = SYSDATETIME()
			FROM dbo.TransferExtra st 
			INNER JOIN #reversalTransfer tmp ON st.transid IN (tmp.TransId, tmp.ReversalTransId)
			WHERE tmp.TransTable = 'TransferExtra'
				AND POWER(2, 4) & @stepDone > 0
			;
		END

	END CATCH

	--TODO: write userlog successfully
	DECLARE @LogData VARCHAR(1000)
	IF @ErrCode = 0 --success
	BEGIN
		SELECT @LogData = CONCAT('RewardPayment: Reverse transfer Creator = ', @Creator,', RefNo = ', @RefNo)
	END
	ELSE -- error logs
	BEGIN
		SELECT @LogData = CONCAT(@ErrMsg, '. Transfer Creator = ', @Creator,', RefNo = ', @RefNo)
	END

	BEGIN TRY	
	
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
								@UserID		= @Creator, 
								@FromCustID = 0, 
								@ToCustID	= 0, 
								@IP			= @IP, 
								@Doing		= @LogData 
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
		SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
			
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
							@UserID		= @Creator, 
							@FromCustID = 0, 
							@ToCustID	= 0, 
							@IP			= @IP, 
							@Doing		= @LogData
	END CATCH

END
GO
