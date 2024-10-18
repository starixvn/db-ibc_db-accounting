/*<info serverAlias="DBSIC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_RewardPayment_Confirm]  
	@Data NVARCHAR(MAX)='' --Confirmed
	,@Creator INT
	,@SubAccID INT = 0
	,@SubAccName VARCHAR(30) = ''
	,@IP VARCHAR(45) = ''
	,@Language VARCHAR(2) = 'E'
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,@PaymentLog NVARCHAR(MAX) = '' OUTPUT

AS  
/*  
    Created: 20240918@Lewis  
    Task: Rebate and Retention for Credit Players - Confirm Payment
    DB: DBSIC-bodb02
  
    Revisions:  
        - 20240918@Lewis: Initialize SP [RedmineId: #208503]
  
    Param's Explanation: 
		- @PaymentDate DATETIME='' OUTPUT 

	Example: 
		- ALPHA: 
				+ @Data NVARCHAR(MAX) =	 '[{
												"FromDate":"2024-10-10 00:00:00"
												,"ToDate":"2024-10-12 00:00:00"
												,"CustId":82224285
												,"ProgramId":1
												,"MaxTransId":19398755858776064
										  }]'
		- NAP: 
			Case 1: Transfer - Headline confirm Super - IsDirect = 0	
				+ @Data NVARCHAR(MAX) =	 '[
										   {"CustId":1176083,"MaxTransId":302848984550999114,"Refno":123456789,"IsDirect":0}
										  ]'

			Case 2: Transfer - Headline confirm (M/A/Mem)- IsDirect = 1			
				+ @Data NVARCHAR(MAX) =	 '[
										   {"CustId":1176083,"MaxTransId":302848984550999114,"Refno":123456789,"IsDirect":1}
										  ]'	
*/  

BEGIN
	SET NOCOUNT ON
	
	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @TrackingValue	NVARCHAR(MAX) --new
			, @TrackingValue2	NVARCHAR(MAX) --old
			, @SPName VARCHAR(100) = 'Acc_RewardPayment_Confirm'
			, @ActionID INT = 95121

	SELECT @StartRun = GETDATE()
	-- =========================
	-- Validate JSON
	-- =========================

	IF ISNULL(@Data,'') = ''
	BEGIN
		SELECT @ErrCode = 1, @ErrMsg = '@Data is not allowed null'
		RETURN
	END

	CREATE TABLE #tmpData (
			FromDate SMALLDATETIME
			, ToDate SMALLDATETIME
			, CustId INT
			, RoleId TINYINT
			, ProgramId SMALLINT
			, MaxTransId BIGINT
			, RefNo BIGINT
			, IsDirect BIT
	)
	INSERT INTO #tmpData (
			FromDate
			, ToDate
			, CustId
			, RoleId
			, ProgramId
			, MaxTransId
			, RefNo
			, IsDirect
	)
	SELECT A.FromDate , A.ToDate, A.CustId, C.roleid, A.ProgramId, A.MaxTransId, A.RefNo, A.IsDirect
	FROM OPENJSON (@Data) WITH 
								(	
									FromDate SMALLDATETIME '$.FromDate',
									ToDate SMALLDATETIME '$.ToDate',
									CustId INT '$.CustId',
									ProgramId SMALLINT '$.ProgramId',
									MaxTransId BIGINT '$.MaxTransId',
									RefNo BIGINT '$.RefNo',
									IsDirect BIT '$.IsDirect'
								) A
	INNER JOIN custdb.dbo.custinfo C WITH (NOLOCK) ON A.CustId = C.custid

	-- =========================
	-- Get UNPAID transid by level
	-- =========================

	CREATE TABLE #TransIds (
			RId INT IDENTITY(1,1)
			, TransId BIGINT
			, DownlineId INT
			, ProgramId INT
			, Amount MONEY
			, RoleId TINYINT
			, RefNo BIGINT
			, IsDirect BIT
	)

	/*  #tmpData
		ALPHA 
			FromDate <> NULL
			ToDate <> NULL
			CustId <> NULL
			ProgramId <> NULL
			MaxTransId <> NULL
			RefNo = NULL
			IsDirect = NULL

		NAP 
			FromDate = NULL
			ToDate = NULL
			CustId <> NULL
			ProgramId = NULL
			MaxTransId <> NULL
			RefNo <> NULL
			IsDirect <> NULL
	*/

	--Member
	IF EXISTS (SELECT TOP 1 1 FROM #tmpData WHERE RoleId = 1) 
	BEGIN
		INSERT INTO #TransIds (
				TransId
				, DownlineId
				, ProgramId
				, Amount
				, RoleId
				, RefNo
				, IsDirect
		)
		SELECT 
				swt.TransId
				, tmp.CustId
				, swt.ProgramId
				, swt.Amount
				, tmp.RoleId
				, tmp.RefNo
				, tmp.IsDirect
		FROM SabaWalletTicket swt WITH (NOLOCK) 
		INNER JOIN #tmpData tmp 
			ON swt.CustId = tmp.CustId 
			AND (tmp.ProgramId IS NULL OR swt.ProgramId = tmp.ProgramId)
		WHERE swt.TransId <= tmp.MaxTransId
			AND (tmp.FromDate IS NULL OR swt.WinlostDate >= tmp.FromDate)
			AND (tmp.ToDate IS NULL OR swt.WinlostDate <= tmp.ToDate)
			AND PaymentStatus & POWER(2,tmp.RoleId - 1) <> POWER(2,tmp.RoleId - 1) --get OFF_Bit
			AND WalletID = 2
	END

	--Agent
	IF EXISTS (SELECT TOP 1 1 FROM #tmpData WHERE RoleId = 2) 
	BEGIN
		INSERT INTO #TransIds (
				TransId
				, DownlineId
				, ProgramId
				, Amount
				, RoleId
				, RefNo
				, IsDirect
		)
		SELECT 
				swt.TransId
				, tmp.CustId
				, swt.ProgramId
				, swt.Amount
				, tmp.RoleId
				, tmp.RefNo
				, tmp.IsDirect
		FROM SabaWalletTicket swt WITH (NOLOCK) 
		INNER JOIN #tmpData tmp 
			ON swt.Recommend = tmp.CustId 
			AND (tmp.ProgramId IS NULL OR swt.ProgramId = tmp.ProgramId)
		WHERE TransId <= tmp.MaxTransId	
			AND (tmp.FromDate IS NULL OR swt.WinlostDate >= tmp.FromDate)
			AND (tmp.ToDate IS NULL OR swt.WinlostDate <= tmp.ToDate)	
			AND PaymentStatus & POWER(2,tmp.RoleId - 1) <> POWER(2,tmp.RoleId - 1) --get OFF_Bit
			AND WalletID = 2
	END

	--Master
	IF EXISTS (SELECT TOP 1 1 FROM #tmpData WHERE RoleId = 3) 
	BEGIN
		INSERT INTO #TransIds (
				TransId
				, DownlineId
				, ProgramId
				, Amount
				, RoleId
				, RefNo
				, IsDirect
		)
		SELECT 
				swt.TransId
				, tmp.CustId
				, swt.ProgramId
				, swt.Amount
				, tmp.RoleId
				, tmp.RefNo
				, tmp.IsDirect
		FROM SabaWalletTicket swt WITH (NOLOCK) 
		INNER JOIN #tmpData tmp 
			ON swt.Mrecommend = tmp.CustId
			AND (tmp.ProgramId IS NULL OR swt.ProgramId = tmp.ProgramId)
		WHERE TransId <= tmp.MaxTransId	
			AND (tmp.FromDate IS NULL OR swt.WinlostDate >= tmp.FromDate)
			AND (tmp.ToDate IS NULL OR swt.WinlostDate <= tmp.ToDate)		
			AND PaymentStatus & POWER(2,tmp.RoleId - 1) <> POWER(2,tmp.RoleId - 1) --get OFF_Bit
			AND WalletID = 2
	END

	 --Super
	IF EXISTS (SELECT TOP 1 1 FROM #tmpData WHERE RoleId = 4)
	BEGIN
		INSERT INTO #TransIds (
				TransId
				, DownlineId
				, ProgramId
				, Amount
				, RoleId
				, RefNo
				, IsDirect
		)
		SELECT 
				swt.TransId
				, tmp.CustId
				, swt.ProgramId
				, swt.Amount
				, tmp.RoleId
				, tmp.RefNo
				, tmp.IsDirect
		FROM SabaWalletTicket swt WITH (NOLOCK) 
		INNER JOIN #tmpData tmp 
			ON swt.Srecommend = tmp.CustId
		WHERE TransId <= tmp.MaxTransId	
			AND PaymentStatus & POWER(2,tmp.RoleId - 1) <> POWER(2,tmp.RoleId - 1) --get OFF_Bit
			AND WalletID = 2
	END	

	-- =========================
	-- Confirm Payment
	-- =========================
	DECLARE @PaymentDate DATE
	SELECT @PaymentDate = GETDATE()

	IF NOT EXISTS (SELECT TOP 1 1 FROM #TransIds)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = N'Already Paid'
		RETURN
	END

	IF EXISTS (SELECT TOP 1 1 FROM #TransIds)
	BEGIN
		--Finance / Agent confirm Member
		IF EXISTS (SELECT TOP 1 1 FROM #TransIds WHERE RoleId = 1)
			BEGIN
				UPDATE swt WITH (ROWLOCK, UPDLOCK)
				SET swt.PaymentStatus |= (
											POWER(2, t.RoleId - 1) --bit1
											|IIF(t.IsDirect = 1,
													 POWER(2, t.RoleId) --bit2
													|POWER(2, t.RoleId + 1) --bit3
													|POWER(2, t.RoleId + 2) --bit4
												, 0)
										 )
					,swt.APaymentDate = @PaymentDate
					,swt.MPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.MPaymentDate)
					,swt.SPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.SPaymentDate)
					,swt.HPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.HPaymentDate)
					,swt.RefNo = IIF(t.IsDirect=1,t.RefNo,swt.RefNo)
					,swt.StatusId = 1
					,swt.RepUpdateTime = dbo.f_GetDateTime2()
				FROM SabaWalletTicket swt 
				INNER JOIN #TransIds t ON swt.TransId = t.TransId
			END
		
		--Finance / Master confirm Agent
		IF EXISTS (SELECT TOP 1 1 FROM #TransIds WHERE RoleId = 2)
			BEGIN
				UPDATE swt WITH (ROWLOCK, UPDLOCK)
				SET swt.PaymentStatus |= (
											POWER(2, t.RoleId - 1) --bit2
											|IIF(t.IsDirect = 1, 
													POWER(2, t.RoleId) --bit3
													|POWER(2, t.RoleId + 1) --bit4
												, 0) 
										 )
					,swt.MPaymentDate = @PaymentDate
					,swt.SPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.SPaymentDate)
					,swt.HPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.HPaymentDate)
					,swt.RefNo = IIF(t.IsDirect=1,t.RefNo,swt.RefNo)
					,swt.RepUpdateTime = dbo.f_GetDateTime2()
				FROM SabaWalletTicket swt 
				INNER JOIN #TransIds t ON swt.TransId = t.TransId
			END
		
		--Finance / Super confirm Master
		IF EXISTS (SELECT TOP 1 1 FROM #TransIds WHERE RoleId = 3)
			BEGIN
				UPDATE swt WITH (ROWLOCK, UPDLOCK)
				SET swt.PaymentStatus |= (
											POWER(2, t.RoleId - 1) --bit3
											| IIF(t.IsDirect = 1
													, POWER(2, t.RoleId) --bit4
													, 0) 
										 )
					,swt.SPaymentDate = @PaymentDate
					,swt.HPaymentDate = IIF(t.IsDirect=1,@PaymentDate,swt.HPaymentDate)
					,swt.RefNo = IIF(t.IsDirect=1,t.RefNo,swt.RefNo)
					,swt.RepUpdateTime = dbo.f_GetDateTime2()
				FROM SabaWalletTicket swt 
				INNER JOIN #TransIds t ON swt.TransId = t.TransId
			END

		--Finance confirm Super
		IF EXISTS (SELECT TOP 1 1 FROM #TransIds WHERE RoleId = 4)
			BEGIN
				UPDATE swt WITH (ROWLOCK, UPDLOCK)
				SET swt.PaymentStatus |= POWER(2, t.RoleId - 1) --bit4
					,swt.HPaymentDate = @PaymentDate
					,swt.RefNo = t.RefNo
					,swt.RepUpdateTime = dbo.f_GetDateTime2()
				FROM SabaWalletTicket swt 
				INNER JOIN #TransIds t ON swt.TransId = t.TransId
			END

	END

	SELECT @EndRun = GETDATE()
	SELECT @Duration = DATEDIFF(MILLISECOND,@StartRun,@EndRun)
	-- =========================
	-- Write Log
	-- =========================
	SELECT @PaymentLog = (
							SELECT
									IIF(@SubAccID = 0, @Creator, @SubAccId) AS UserID
									, t.DownlineId AS CustID
									, @SPName AS SPName
									, @ActionID AS ActionID
									, '<' + @SPName + ' CustId="'+ COALESCE(CAST(@Creator AS VARCHAR(50)),SPACE(1)) + '" ' +
									'DownlineId="'+ COALESCE(CAST(t.DownlineId AS VARCHAR(50)),SPACE(1)) + '" ' +
									'SubAccName="'+ COALESCE(@SubAccName,SPACE(1)) + '" ' +
									'ProgramId="'+ COALESCE(t.ProgramId,SPACE(1)) + '" ' +
									'Amount="'+ COALESCE(CAST(t.Amount AS VARCHAR(50)),SPACE(1)) + '" ' +
									'PaymentStatus="1" ' +
									'PaymentDate="'+ COALESCE(CAST(@PaymentDate AS VARCHAR(50)),SPACE(1)) + '" ' +
									'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" />'
									AS TrackingValue
									,'<' + @SPName + ' CustId="'+ COALESCE(CAST(@Creator AS VARCHAR(50)),SPACE(1)) + '" ' +
									'DownlineId="'+ COALESCE(CAST(t.DownlineId AS VARCHAR(50)),SPACE(1)) + '" ' +
									'SubAccName="'+ COALESCE(@SubAccName,SPACE(1)) + '" ' +
									'ProgramId="'+ COALESCE(t.ProgramId,SPACE(1)) + '" ' +
									'Amount="'+ COALESCE(CAST(t.Amount AS VARCHAR(50)),SPACE(1)) + '" ' +
									'PaymentStatus="0" ' +
									'PaymentDate="'+ COALESCE(CAST(@PaymentDate AS VARCHAR(50)),SPACE(1)) + '" ' +
									'IP="'+ COALESCE(CAST(@IP AS VARCHAR(20)),SPACE(1)) + '" />'
									AS TrackingValue2
									, @Duration AS Duration
							FROM
								(
									SELECT
											A.DownlineId
											,STRING_AGG(CAST(A.ProgramId AS NVARCHAR(MAX)),',') ProgramId
											,SUM(A.Amount) Amount
									FROM
										(
											 SELECT 
													t.DownlineId
													,t.ProgramId
													,SUM(Amount) Amount
											FROM #TransIds t
											GROUP BY t.DownlineId
													,t.ProgramId
										) A	 
									GROUP BY A.DownlineId
								 ) t
							FOR XML RAW
						 )
	DROP TABLE #tmpData
	DROP TABLE #TransIds
END
GO
