/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_RewardPayment_Transfer_Rollback
	@RefNo			BIGINT, -- Rollback Transfer & TransferExtra & SabaWalletTicket
	@MaxTransId		BIGINT ,
	@Creator		INT,
	@SiteDBGroupId	SMALLINT,
	@IP				VARCHAR(45)	= '',
	@Language		VARCHAR(2)	= 'E',
	@ErrCode		INT	=	0	OUTPUT,
	@ErrMsg			NVARCHAR(200) =	''	OUTPUT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Add new transfer - rollback
	DB: DBAGE.bodb02
	
	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@RefNoCheck			BIGINT,
		@Server_SiteDBGroupID SMALLINT
	;

	SELECT @RefNoCheck = ISNULL(@RefNo, 0);

	--Check the SiteDBGroupID of CustID and Server is match
	SELECT @Server_SiteDBGroupID = dbo.f_Get_SiteDBGroupID();
	IF ISNULL(@SiteDBGroupID,-1) <> @Server_SiteDBGroupID
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = 'Executing on invalid server. Please check SiteDBGroupID information.'
		RETURN;		
	END

	--TODO: Fetch transfer & TransferExtra by RefNo
	DROP TABLE IF EXISTS #tmpTransfer;
	SELECT tmp.TransId, tmp.custid, tmp.srecommend, tmp.mrecommend, tmp.recommend, ci.roleId, tmp.TransTable
	INTO #tmpTransfer
	FROM (
		SELECT TransId, custid, srecommend, mrecommend, recommend, CONVERT(VARCHAR(30),'Transfer') AS TransTable
		FROM dbo.[Transfer] WITH(NOLOCK)
		WHERE RefNo = @RefNoCheck
		UNION ALL
		SELECT TransId, custid, srecommend, mrecommend, recommend, 'TransferExtra'
		FROM dbo.[TransferExtra] WITH(NOLOCK)
		WHERE RefNo = @RefNoCheck
	) AS tmp
		INNER JOIN CustDB.dbo.Customer ci WITH(NOLOCK) ON ci.custid = tmp.custid
		INNER JOIN CustDB.dbo.[Site] s WITH(NOLOCK) ON s.[site] = ci.[site]
	WHERE s.SiteDBGroupID = @Server_SiteDBGroupID
	;

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg = 'There are no transfer(s) to rollback.'
		RETURN;		
	END

	--TODO: Control flow
	DECLARE @stepDone	SMALLINT = 0,
		@confirmData	NVARCHAR(1000),
		@FromCustId		INT,
		@srecommend		INT, 
		@mrecommend		INT, 
		@recommend		INT,
		@roleId			TINYINT,
		@IsDirectCheck	BIT
	;

	BEGIN TRY
		--TODO: Check RewardPayment to rollback
		SELECT @FromCustId	= custid,
			@srecommend		= srecommend,
			@mrecommend		= mrecommend,
			@recommend		= recommend,
			@roleId			= roleId
		FROM #tmpTransfer 
		WHERE TransTable = 'TransferExtra'
		;

		WITH CTE_DirectAccount AS (
			SELECT 
				SUM(IIF(cd.custid = @FromCustId, 1, 0)) AS DummyCount,
				SUM(IIF(cd.custid <> @FromCustId, 1, 0)) AS UplineCount
			FROM CUSTDB.dbo.Acc_CustDirect cd WITH(NOLOCK) 
			WHERE cd.custid IN (@srecommend, @mrecommend, @recommend, @FromCustId)
				AND cd.roleid >= @roleId
		)
		SELECT @IsDirectCheck = IIF(ck.DummyCount = 0 AND ck.UplineCount > 0, 1, 0)
		FROM CTE_DirectAccount ck;

		IF @roleId <> 4 AND @IsDirectCheck = 0
		BEGIN
			SELECT @ErrCode = 103,
				@ErrMsg = 'Invalid payment account to rollback.'
			RETURN;		
		END

		--TODO: #1 - Rollback confirm payment on SUPER first --> SiteDB of @FromCustId
		SELECT @confirmData = (SELECT t.CustId, t.MaxTransId, t.RefNo, t.IsDirect
								FROM (VALUES(@FromCustId, @MaxTransId, @RefNo, @IsDirectCheck)) AS t (CustId, MaxTransId, RefNo, IsDirect)
								WHERE t.CustId > 0
								FOR JSON PATH);

		IF ISJSON(@confirmData) = 1
		BEGIN
			EXEC dbo.Acc_RewardPayment_Confirm_Rollback 
				@Data			= @confirmData,
				@ErrCode		= @ErrCode OUTPUT,
				@ErrMsg			= @ErrMsg OUTPUT
			;

			IF @ErrCode > 0 
			BEGIN
				SELECT @ErrMsg = @ErrMsg
					, @ErrCode = 103
				RETURN
			END
			ELSE
				SET @stepDone |= POWER(2, 1); --> Mark done payment confirmation on SUPER
		END

		BEGIN TRAN;
		--TODO: rollback transferExtra by transid
		UPDATE st 
		SET custid = 0, Recommend = 0, Mrecommend=0, Srecommend=0, Credit=0, Debit=0, RepUpdateTime = SYSDATETIME()
		FROM dbo.[TransferExtra] st WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #tmpTransfer tmp ON tmp.transid = st.transid
		;
		SET @stepDone |= IIF(@@ROWCOUNT = 1 AND @@ERROR = 0, POWER(2, 2), 0);

		--TODO: rollback transfer by transid
		UPDATE st 
		SET custid = 0, Recommend = 0, Mrecommend=0, Srecommend=0, winlost=0, actual_stake=0, RepUpdateTime = SYSDATETIME()
		FROM dbo.[Transfer] st WITH(ROWLOCK, UPDLOCK)
			INNER JOIN #tmpTransfer tmp ON tmp.transid = st.transid
		;
		SET @stepDone |= IIF(@@ROWCOUNT = 1 AND @@ERROR = 0, POWER(2, 3), 0);
		
		COMMIT;
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 109,
			@ErrMsg = CONCAT('CreditReward: Rollback reward payment failed = ', @refNo, 'maxtransid=', @MaxTransId, '. Error: ', ERROR_MESSAGE())
		;

		IF @@TRANCOUNT > 0
			ROLLBACK;

	END CATCH

	--TODO: write userlog successfully
	DECLARE @LogData VARCHAR(1000)
	IF @ErrCode = 0 --success
	BEGIN
		SELECT @LogData = CONCAT('CreditReward: Rollback reward payment refno = ', @refNo)
	END
	ELSE -- error logs
	BEGIN
		SELECT @LogData = CONCAT(@ErrMsg, '. Reward payment refno = ', @refNo)
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
