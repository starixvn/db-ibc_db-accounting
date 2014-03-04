CREATE PROCEDURE [NAP_Admin_Calculate_9]
	@strXML varchar(MAX) ='' OUTPUT,
	@statusID tinyint = 0,
	@winlostdate smalldatetime = NULL
AS
/*
	Created by: Kathy
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	Original : [Admin_Calculate_9]
	
	Revision:
		
*/
BEGIN 
	
	SET NOCOUNT ON 
	
	IF @@SERVERNAME IN ('DB043', 'DB044') RETURN

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052','DB054','DB231')
	BEGIN		

		DECLARE @LASCommand NVARCHAR(2000),
				@createdDate DATETIME

		SELECT	 @LASCommand = 'EXEC [dbo].[Admin_Calculate_9] @statusID = ' + CONVERT(NVARCHAR(10),@statusID) +
								', @strXML = ' + @strXML + 
								', @winlostdate = ''' + CONVERT(NVARCHAR(10),@winlostdate) + ''''
				,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand]	 @SPName		= 'Admin_Calculate_9'
															,@SQLCommand	= @LASCommand
															,@CreatedDate	= @createdDate
															,@StatusID		= 0 -- waiting
															,@MatchID		= 9
															,@Bettype		= 9
															,@Status		= 'waiting'
															,@BetCount		= 0

	END

	BEGIN
		Declare @odds smallmoney
		Declare @commWinRate smallmoney, @commLostRate smallmoney
		Declare @oldstatusID tinyint, @oldwinlost money, @winlost money
		Declare @xml XML

		-- get modds from XML string [edited by viet @ 20121213]
		SET @xml = convert(xml, @strXML)
 	
		declare @cal_modds as TABLE (transid bigint PRIMARY KEY, modds smallmoney, loseCnt tinyint)
		INSERT INTO @cal_modds (transid, modds, loseCnt)
		SELECT T.C.value('./@t', 'bigint'), -- transid
			isnull(T.C.value('./@m', 'smallmoney'),0), -- modds
			isnull(T.C.value('./@l', 'tinyint'),0) -- lostCnt
		from @xml.nodes('/root/r') as T(C)	


	UPDATE T
	SET
		statusID = @statusID,
		[status] = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 103 THEN 'Refund'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben = CASE @statusID
			WHEN 0 THEN 0
			ELSE 1
			END,
		winlostdate = @winlostdate,
		@odds = modds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
	
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN '0' THEN 1
		WHEN '1' THEN 0
		ELSE 1 END,
		@commLostRate = CASE comstatus
		WHEN '0' THEN 1
		WHEN '1' THEN 2
		ELSE 1 END,
	
		@winlost = winlost = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE stake*@odds
			END,
		awinlost = CASE 
			WHEN @statusID = 113 and loseCnt > 0  THEN  stake*apositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*apositiontaking*(@odds-1)
			ELSE 0
			END,
		mwinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*mpositiontaking
			WHEN @statusID IN (112, 113) THEN -stake*mpositiontaking*(@odds-1)		 
			ELSE 0
			END,
		swinlost = CASE
			WHEN @statusID = 113 and loseCnt > 0 THEN  stake*spositiontaking 
			WHEN @statusID IN (112, 113) THEN -stake*spositiontaking*(@odds-1)		
			ELSE 0
			END,

		playercomm	= CASE @statusID 
					WHEN 112 THEN @commWinRate  * stake*playerdiscount
					WHEN 113 THEN @commLostRate * stake*playerdiscount
					ELSE 0 END,
		comm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * discount*stake*(1-apositiontaking)
					WHEN 113 THEN @commLostRate * discount*stake*(1-apositiontaking)
					ELSE 0 END,  
		acomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * adiscount*stake*(1-apositiontaking-mpositiontaking)
					WHEN 113 THEN @commLostRate * adiscount*stake*(1-apositiontaking-mpositiontaking)
					ELSE 0 END,
		scomm		= CASE @statusID
					WHEN 112 THEN @commWinRate  * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					WHEN 113 THEN @commLostRate * sdiscount*stake*(1-apositiontaking-mpositiontaking-spositiontaking)
					ELSE 0 END

	FROM dbo.bettrans T 
			INNER JOIN @cal_modds m ON T.transid = m.transid
			


		RETURN
	END -- IF @mode = 1
END



GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_9] TO [vnteam] AS [dbo]
GO


