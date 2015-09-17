USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_9]    Script Date: 09/17/2015 13:27:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_9] 
	@strXML VARCHAR(MAX) = '' OUTPUT
	,@statusID TINYINT = 0
	,@winlostdate SMALLDATETIME = NULL
AS
/*
	Created by: Kathy
	Task: Calculate Mix Parlay 
	DB: DBTRANS.BODB02
	Original : [Admin_Calculate_9]
	
	Revision:
		- 20150914@Kathy: Change settlement flow (Remove NAP_Task_Calculate_Parlay job) [Redmine:#43566]
		
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

	
	DECLARE @odds SMALLMONEY, @commWinRate SMALLMONEY ,@commLostRate SMALLMONEY

	DECLARE @xml XML
	DECLARE @transIDs as TABLE (transid bigint, modds SMALLMONEY)
	
	SET @xml = CONVERT(XML, N'<root><r t="' + REPLACE(REPLACE(@strXML, '|', '" m="'), ',', '"/><r t="') + '"/></root>')
	
	INSERT INTO @transIDs(transid, modds)
	SELECT T.C.value('./@t', 'bigint'), ISNULL(T.C.value('./@m', 'smallmoney'), 0)
	FROM @xml.nodes('/root/r') AS T(C)
	OPTION (OPTIMIZE FOR (@xml = NULL ))	

	declare @matchid INT
	select top (1) @matchid = bm.matchid
	from dbo.bettransM bm with(nolock)
		inner join bettrans b with(nolock) on b.refno = bm.refno
	where b.transid in (select top 1 transid from @transIDs)
	
	UPDATE b WITH(ROWLOCK, UPDLOCK)
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
			,@odds = b.modds = CASE WHEN @statusId = 0 THEN 0 ELSE t.modds END		
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
			,winlost = stake * @odds
			,awinlost = CASE 
				WHEN @statusID = 113 AND @odds = 0 THEN stake * apositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * apositiontaking * (@odds - 1)
				ELSE 0
				END
			,mwinlost = CASE 
				WHEN @statusID = 113 AND @odds = 0 THEN stake * mpositiontaking
				WHEN @statusID IN (112, 113) THEN - stake * mpositiontaking * (@odds - 1)
				ELSE 0
				END
			,swinlost = CASE 
				WHEN @statusID = 113 AND @odds = 0 THEN stake * spositiontaking
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
		FROM bettrans b
			INNER JOIN @transIDs t 
				ON b.transid = t.transid
				
END










GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_9] TO [vnteam] AS [dbo]