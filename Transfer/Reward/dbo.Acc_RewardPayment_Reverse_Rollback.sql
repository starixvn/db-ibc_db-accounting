/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_RewardPayment_Reverse_Rollback]
	@RefNo			BIGINT,
	@Creator		INT,
	@SiteDBGroupId	SMALLINT,
	@IP				VARCHAR(45)	= '',
	@Language		VARCHAR(2)	= 'E',
	@ErrCode		INT	=	0	OUTPUT,
	@ErrMsg			NVARCHAR(200) =	''	OUTPUT
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

	DECLARE
		@RefNoCheck			BIGINT,
		@Server_SiteDBGroupID SMALLINT,
		@FromCustId			INT,
		@RoleId				TINYINT
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

	--TODO: Fetch transfer by RefNo - T1 only
	DROP TABLE IF EXISTS #reversalTransfer;
	SELECT t.TransId, t.IsReversed, t.TransTable, t.custid, ci.roleId
	INTO #reversalTransfer
	FROM (
		SELECT st.custid, st.TransId, CAST(IIF(st.TransDesc LIKE '%(Reversal)%', 1, 0) AS  BIT) AS IsReversed, CAST('Transfer' AS VARCHAR(30)) AS TransTable
		FROM dbo.[Transfer] st WITH(NOLOCK)
		INNER JOIN dbo.[TransferInfo] ti WITH(NOLOCK) ON ti.transid = st.transid
		WHERE st.RefNo = @RefNoCheck
			AND ti.IsDel = 1

		--UNION ALL
		--SELECT st.custid, st.TransId, CAST(IIF(st.TransDesc LIKE '%(Reversal)%', 1, 0) AS  BIT) AS IsReversed, 'TransferExtra'
		--FROM dbo.TransferExtra st WITH(NOLOCK)
		--WHERE st.RefNo = @RefNoCheck
		--	AND st.IsReversed = 1
	) AS t
	INNER JOIN CustDB.dbo.[Customer] ci WITH(NOLOCK) ON ci.custid = t.custid
	INNER JOIN CustDB.dbo.[Site] s WITH(NOLOCK) ON s.[site] = ci.[site]
	WHERE s.SiteDBGroupID = @Server_SiteDBGroupID

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg = 'There is no reversal transfer(s) to rollback.'
		RETURN;		
	END


	--TODO: Check RewardPayment to rollback
	--SELECT TOP(1)
	--	@FromCustId		= custid,
	--	@roleId			= roleId
	--FROM #reversalTransfer 
	--WHERE TransTable = 'TransferExtra'
	--;

	--TODO: Control flow
	DECLARE @stepDone	SMALLINT,
		@confirmData	NVARCHAR(MAX),
		@IsDirectCheck	BIT
	;

	BEGIN TRY
		SELECT @stepDone	= 0;

		BEGIN TRAN
		--TODO: rollback reversal transfer(s) by transid
		UPDATE st 
		SET st.custid			= IIF(tmp.IsReversed = 1, 0, st.custid)
			, st.Recommend		= IIF(tmp.IsReversed = 1, 0, st.Recommend)
			, st.Mrecommend		= IIF(tmp.IsReversed = 1, 0, st.Mrecommend)
			, st.Srecommend		= IIF(tmp.IsReversed = 1, 0, st.Srecommend)
			, st.winlost		= IIF(tmp.IsReversed = 1, 0, st.winlost)
			, st.actual_stake	= IIF(tmp.IsReversed = 1, 0, st.actual_stake)
			, st.RepUpdateTime	= SYSDATETIME()
		FROM dbo.[Transfer] st WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #reversalTransfer tmp ON tmp.transid = st.transid
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 1), 0);

		--[TransferInfo]
		UPDATE ti 
		SET ti.IsDel			= 0
			, ti.RepUpdateTime	= SYSDATETIME()
		FROM dbo.[TransferInfo] ti WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #reversalTransfer tmp ON tmp.transid = ti.transid
		;SET @stepDone |= IIF(@@ROWCOUNT > 0, POWER(2, 2), 0);

		COMMIT;
		/*
		--TODO: rollback reversal transferExtra by transid
		UPDATE st 
		SET st.custid			= IIF(tmp.IsReversed = 1, 0, st.custid)
			, st.Recommend		= IIF(tmp.IsReversed = 1, 0, st.Recommend)
			, st.Mrecommend		= IIF(tmp.IsReversed = 1, 0, st.Mrecommend)
			, st.Srecommend		= IIF(tmp.IsReversed = 1, 0, st.Srecommend)
			, st.Credit			= IIF(tmp.IsReversed = 1, 0, st.Credit)
			, st.Debit			= IIF(tmp.IsReversed = 1, 0, st.Debit)
			, st.IsReversed		= 0
			, st.RepUpdateTime	= SYSDATETIME()
		FROM dbo.[TransferExtra] st WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #reversalTransfer tmp ON tmp.transid = st.transid
		;
		SET @stepDone |= POWER(2, 3);

		--TODO: #1 - DO confirm payment on SUPER first --> SiteDB of @FromCustId
		SELECT @IsDirectCheck	= IIF(@roleId < 4, 1, 0);
		SELECT @confirmData		= (SELECT t.CustId, t.MaxTransId, t.RefNo, t.IsDirect
								FROM (VALUES(@FromCustId, 0, @RefNo, @IsDirectCheck)) AS t (CustId, MaxTransId, RefNo,IsDirect)
								WHERE t.CustId > 0
								FOR JSON PATH);

		----select @confirmData [@confirmData]
		IF ISJSON(@confirmData) = 1
		BEGIN
			EXEC dbo.Acc_RewardPayment_Confirm 
				@Data			= @confirmData,
				@Action			= 'Reverse',
				@ErrCode		= @ErrCode OUTPUT,
				@ErrMsg			= @ErrMsg OUTPUT
			;
			IF @ErrCode > 0
			BEGIN
				SELECT @ErrCode = 103
					,@ErrMsg	= ISNULL(@ErrMsg, 'Rollback reverse transfer - confirm payment status failed')
				RAISERROR(@ErrMsg, 11, 1); --- will be handled in the Begin...Catch block code
			END
			ELSE
				SET @stepDone |= POWER(2, 4) -- Done rollback reverse payment status
		END
		*/

	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 109,
			@ErrMsg = CONCAT('WhiteLabel: Rollback reversal transfer failed. Error: ', ERROR_MESSAGE())
		;
	END CATCH

	--TODO: write userlog successfully
	DECLARE @LogData VARCHAR(1000)
	IF @ErrCode = 0 --success
	BEGIN
		SELECT @LogData = CONCAT('WhiteLabel: Rollback reversal transfer refno = ', @refNo)
	END
	ELSE -- error logs
	BEGIN
		SELECT @LogData = CONCAT(@ErrMsg, '. Reversal transfer refno = ', @refNo)
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
