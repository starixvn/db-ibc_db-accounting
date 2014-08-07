/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_9]    Script Date: 08/07/2014 14:06:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Admin_Calculate_9    Script Date: 2/26/2014 6:01:44 PM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9] @strXML VARCHAR(MAX) = '' OUTPUT
	,@statusID TINYINT = 0
	,@winlostdate SMALLDATETIME = NULL
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
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(4000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_9] @statusID = ' + CONVERT(NVARCHAR(10), @statusID) + ', @strXML = ''' + @strXML + '''' + ', @winlostdate = ''' + CONVERT(NVARCHAR(20), @winlostdate) + ''''
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_9'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = 9
			,@Bettype = 9
			,@Status = 'waiting'
			,@BetCount = 0
	END

	BEGIN
		DECLARE @odds SMALLMONEY
		DECLARE @commWinRate SMALLMONEY
			,@commLostRate SMALLMONEY
		DECLARE @oldstatusID TINYINT
			,@oldwinlost MONEY
			,@winlost MONEY
		DECLARE @xml XML

		-- get modds from XML string [edited by viet @ 20121213]
		SET @xml = convert(XML, @strXML)

		DECLARE @cal_modds AS TABLE (
			transid BIGINT PRIMARY KEY
			,modds SMALLMONEY
			,loseCnt TINYINT
			)

		INSERT INTO @cal_modds (
			transid
			,modds
			,loseCnt
			)
		SELECT T.C.value('./@t', 'bigint')
			,-- transid
			isnull(T.C.value('./@m', 'smallmoney'), 0)
			,-- modds
			isnull(T.C.value('./@l', 'tinyint'), 0) -- lostCnt
		FROM @xml.nodes('/root/r') AS T(C)

		UPDATE T
		SET statusID = @statusID
			,[status] = CASE @statusID
				WHEN 0 THEN 'running'
				WHEN 103 THEN 'Refund'
				WHEN 111 THEN 'DRAW'
				WHEN 112 THEN 'WON'
				WHEN 113 THEN 'LOSE'
				END
			,ruben = CASE @statusID
				WHEN 0 THEN 0
				ELSE 1
				END
			,winlostdate = @winlostdate
			,@odds = modds = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE m.modds
				END
			,@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
				WHEN '0' THEN 1
				WHEN '1' THEN 0
				ELSE 1
				END
			,@commLostRate = CASE comstatus
				WHEN '0' THEN 1
				WHEN '1' THEN 2
				ELSE 1
				END
			,@winlost = winlost = CASE 
				WHEN loseCnt > 0 THEN 0
				WHEN @statusID = 0 THEN 0
				ELSE stake * @odds
				END
			,awinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * apositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * apositiontaking * (@odds - 1)
				ELSE 0
				END
			,mwinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * mpositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * mpositiontaking * (@odds - 1)
				ELSE 0
				END
			,swinlost = CASE 
				WHEN @statusID = 113 AND loseCnt > 0 THEN stake * spositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * spositiontaking * (@odds - 1)
				ELSE 0
				END
			,playercomm = CASE @statusID
				WHEN 112 THEN @commWinRate * stake * playerdiscount
				WHEN 113 THEN @commLostRate * stake * playerdiscount
				ELSE 0
				END
			,comm = CASE @statusID
				WHEN 112 THEN @commWinRate * discount * stake * (1 - apositiontaking)
				WHEN 113 THEN @commLostRate * discount * stake * (1 - apositiontaking)
				ELSE 0
				END
			,acomm = CASE @statusID
				WHEN 112 THEN @commWinRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				WHEN 113 THEN @commLostRate * adiscount * stake * (1 - apositiontaking - mpositiontaking)
				ELSE 0
				END
			,scomm = CASE @statusID
				WHEN 112 THEN @commWinRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				WHEN 113 THEN @commLostRate * sdiscount * stake * (1 - apositiontaking - mpositiontaking - spositiontaking)
				ELSE 0
				END
		FROM dbo.bettrans T
			INNER JOIN @cal_modds m ON T.transid = m.transid

		RETURN
	END -- IF @mode = 1
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9] TO [vnteam] AS [dbo]