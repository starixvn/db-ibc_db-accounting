/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_Acc_ReverseTransfer_Rollback]
(
	@Refno					BIGINT,
	@IP						VARCHAR(45)='',
	@UserID					INT,
	@ErrCode				INT				= 0  OUTPUT,
	@ErrMsg					NVARCHAR(200)	= '' OUTPUT,
	@SiteDBGroupID			SMALLINT
) AS
/*
Task: Check input
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20220829@Danny: Init. SP rollback Reverse Transfer by refno [Redmine: #175253]
	- 20221107@Danny: Database - Sync-up Standby Server data - [RedmineID: #167261]
						   
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @BalanceUpDay	SMALLDATETIME
		, @archivedDay		SMALLDATETIME
		, @constraintDay	SMALLDATETIME
		, @MoveBetsDay		SMALLDATETIME
		, @winlostdate		SMALLDATETIME
		, @LogData nvarchar(2000)

	SELECT @LogData = 'Reverse Transfer rollback Refno: ' + CONVERT(VARCHAR(20), @RefNo) + ' At ' + CONVERT(VARCHAR(10), @SiteDBGroupID)

	-- Get ticket detail 
	DECLARE @tranDetails TABLE ( transid BIGINT, winlost MONEY, IsDel BIT, CustID INT, actual_stake MONEY, winlostdate SMALLDATETIME, transDesc NVARCHAR(1000))
	DECLARE @remove TABLE ( transid BIGINT, winlost MONEY, IsDel BIT, CustID INT, actual_stake MONEY, winlostdate SMALLDATETIME)	-- List transid update to orphan ticket 
	DECLARE @reversal TABLE ( transid BIGINT, winlost MONEY, IsDel BIT, CustID INT, actual_stake MONEY, winlostdate SMALLDATETIME) -- List transid update IsDel = 1 =>  IsDel = 0
	DECLARE @balanceCheck TABLE ( CustID INT, balance MONEY, cnt_IsDel SMALLINT, max_isDel BIT)
	DECLARE @alias VARCHAR(100), 
			@sqlCommand VARCHAR(MAX),
			@doNotRunInServer VARCHAR(1000),
			@remark VARCHAR(4000)

	---get server name that dont need to run
	EXEC bodb02.dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
	SELECT @alias = 'DBRPT', @remark = 'SiteDB_Acc_ReverseTransfer_Rollback -> Acc_StatementUpdateTransfer'

	INSERT INTO @tranDetails (transid, CustID, winlost, actual_stake, IsDel, winlostdate, transDesc)
	SELECT	t.transid, t.custid, t.Winlost, t.Actual_Stake, ISNULL(ti.IsDel,0) IsDel, winlostdate, TransDesc
	FROM	dbo.Transfer t WITH (NOLOCK)
	LEFT JOIN dbo.TransferInfo ti WITH (NOLOCK) ON t.TransId = ti.TransId
	WHERE	refno = @refno AND bettype > 20000 AND custid <> 0

	IF (	@Refno IS NULL  -- Refno is invalid
			OR @Refno = 0   -- Refno is invalid
			OR NOT EXISTS (SELECT TOP 1 1 FROM @tranDetails) -- No data relation with @refno
		)
	BEGIN
		SELECT @ErrMsg = 'Input is invalid.', @ErrCode = 100 
		RETURN
	END

	SELECT TOP 1 @winlostdate = winlostdate FROM  @tranDetails

	-- Check balance (If ticket is reversed success, SUM(winlost-actualStake) = 0)
	INSERT INTO @balanceCheck(CustID, balance, cnt_IsDel, max_isDel)
	SELECT CustID, SUM(winlost-actual_stake), COUNT(DISTINCT Isdel), MAX(CAST(isDel AS TINYINT)) FROM @tranDetails
	GROUP BY CustID

	--Check to not allow to transfer before balance up date
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	SELECT @archivedDay	= MAX(winlostdate)
	FROM dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @constraintDay =  CASE 
									WHEN @archivedDay > @BalanceUpDay THEN @BalanceUpDay+7 -- new BU
									ELSE @BalanceUpDay -- old BU
								END

	IF @winlostdate < @constraintDay --Before BU date
	BEGIN
		SELECT @ErrMsg ='Not allow to add transaction before balance up date - ' + convert(NVARCHAR(10), @constraintDay, 120) + '.'
			, @ErrCode = 101

		RETURN
	END

	-- Detect CustID relation with @SiteDBGroupID input
	DECLARE @tblUniqueCustIds TABLE (CustId INT, ID INT IDENTITY(1,1))

	INSERT INTO @tblUniqueCustIds (custid)
	SELECT	DISTINCT custid
	FROM	@tranDetails

	-- handle sitegroup DB
	DECLARE @SiteGroupInfo TABLE(CustID INT, SiteDBGroupID SMALLINT, LinkedServerName  VARCHAR(512), ClientAccessName VARCHAR(512), AGIP VARCHAR (50))
	DECLARE @cs_CustID INT
	DECLARE @i INT = 1

	WHILE EXISTS (SELECT TOP 1 1 FROM @tblUniqueCustIds WHERE ID = @i)
	BEGIN
		SELECT @cs_CustID = CustID FROM @tblUniqueCustIds WHERE ID = @i

		INSERT INTO @SiteGroupInfo (SiteDBGroupID, LinkedServerName, ClientAccessName, AGIP)
		EXEC CustDB.dbo.Acc_SiteDBConfigSel @CustID = @cs_CustID

		UPDATE @SiteGroupInfo SET CustID = @cs_CustID WHERE CustID IS NULL

		SELECT @i = @i + 1
	END

	-- clean data
	IF NOT EXISTS (SELECT TOP 1 1 FROM @balanceCheck WHERE balance = 0 AND cnt_IsDel = 1 AND max_isDel = 1) 
	BEGIN
		SELECT @ErrMsg = 'Input is invalid.', @ErrCode = 101
		RETURN
	END

	DELETE @balanceCheck
	WHERE CustID NOT IN (SELECT z.CustID FROM @SiteGroupInfo z WHERE SiteDBGroupID = @SiteDBGroupID) AND  (balance <> 0 OR max_isDel = 0 OR cnt_IsDel <> 1)

	DELETE @tranDetails 
	WHERE CustID NOT IN (SELECT z.CustID FROM @balanceCheck z)

	INSERT INTO @remove(transid, CustID)
	SELECT transid, CustID 
	FROM @tranDetails 
	WHERE IsDel = 1 AND CustID IN (SELECT z.CustID FROM @SiteGroupInfo z WHERE SiteDBGroupID = @SiteDBGroupID) AND transDesc LIKE '%(Reversal)%'

	INSERT INTO @reversal(transid, CustID, winlost, actual_stake, winlostdate)
	SELECT transid, CustID, winlost, actual_stake, winlostdate  
	FROM @tranDetails 
	WHERE IsDel = 1 AND CustID IN (SELECT z.CustID FROM @SiteGroupInfo z WHERE SiteDBGroupID = @SiteDBGroupID) AND transDesc NOT LIKE '%(Reversal)%'

	-- Rollback here
	BEGIN TRANSACTION 
		BEGIN TRY
			UPDATE dbo.Transfer WITH(ROWLOCK)
			SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0		
			WHERE transid IN (SELECT transid FROM @remove)
	
			UPDATE Transfer_Coll WITH(ROWLOCK)
			SET		custid = 0, Debit = 0, Credit = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (SELECT transid FROM @remove)

			UPDATE	dbo.TransferInfo WITH (ROWLOCK) 
			SET		IsDel = 0, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (Select transid from @Reversal)

			UPDATE	dbo.TransferInfo WITH (ROWLOCK) 
			SET		IsDel = 1, RepUpdateTime = SYSDATETIME()
			WHERE	transid IN (Select transid from @remove)

			DECLARE @tblPending TABLE (CustID INT, Balance	MONEY)
			DECLARE @MemID INT, @Balance	MONEY
			INSERT INTO @tblPending (CustID, Balance)
			SELECT		a.custid, SUM(a.winlost - a.actual_stake) as Balance
			FROM		@Reversal a
			GROUP BY	a.custid

			DECLARE CS_MemBal 
			CURSOR FOR  
			SELECT CustID, Balance
			FROM @tblPending 
	   		 
			OPEN CS_MemBal  
			FETCH NEXT FROM CS_MemBal INTO @MemID, @Balance
			WHILE @@FETCH_STATUS = 0  
			BEGIN
				IF @Balance > 0
					EXEC Dot_BalanceCreditUpd @CustID = @MemID, @balance = @Balance, @type = 2

				IF @Balance < 0
				BEGIN
					DECLARE @ABS_Balance MONEY
					SELECT @ABS_Balance = ABS(@Balance)
					EXEC Dot_BalanceDebitUpd @CustID = @MemID, @balance = @ABS_Balance, @type = 2, @IsForced = 1
				END

				IF  @winlostdate <= @MoveBetsDay
				BEGIN
					SELECT @SqlCommand = CONCAT('EXEC bodb_report.dbo.[Acc_StatementUpdateTransfer] ', ' @custid = ',@MemID,' ,@Amount = ',@Balance,' ,@winlostdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121), '''')

					EXEC bodb02.dbo.Task_ExecRep_Wrapper 
						@ServerName = '', 
						@AliasName = @alias, 
						@SqlCommand = @SqlCommand, 
						@doNotRunInServer = @doNotRunInServer,
						@Remark = @remark

				END

				FETCH NEXT FROM CS_MemBal INTO @MemID, @Balance 
			END  

			CLOSE CS_MemBal  
			DEALLOCATE CS_MemBal  

		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = 'Reverse Transfer rollback failed', @ErrCode = 103 
				ROLLBACK TRANSACTION
				RETURN
		END CATCH
	COMMIT TRANSACTION

	EXEC DBCTG.bodb02.dbo.Acc_ExchangeRateUpdisDeleted @refNo = @refno, @isDeleted = 0

	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = 0, @IP = @IP, @Doing = @LogData
	END TRY
	BEGIN CATCH
		Select @LogData = @LogData + ' ErrMsg=' + error_message()
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = 0, @IP = @IP, @Doing = @LogData
	END CATCH


END
GO

