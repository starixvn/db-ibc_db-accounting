ALTER PROCEDURE [NAP_Admin_Calculate_Parlay] @matchid INT = NULL
	,@matchids VARCHAR(2000) = NULL
	,@mode VARCHAR(15) = 'CAL'
	,@action VARCHAR(20) = 'ALL'
	,@fth INT = NULL
	,@fta INT = NULL
	,@hth INT = NULL
	,@hta INT = NULL
	,@matchdate DATETIME = NULL
	,@TennisTotal SMALLINT = NULL
	,@statusID TINYINT = NULL
	,@winlostdate SMALLDATETIME = NULL
	,@strXML VARCHAR(MAX) = NULL
	,@CalledByBrokerService BIT = 0
AS
/*
	Created: Kathy
	Task : Covered SP for settlement (Parlay)
	Original SP: 
	DB: EXECREP SP (DBTrans_Bet)

	Revisions:

	Param's Explanation:
		@action			@mode
		
*/
BEGIN
	SET NOCOUNT ON;

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054', 'DB06', 'DB231', 'DB232') AND @CalledByBrokerService = 0
	BEGIN
		-- DB052/DB053/DB054/DB06: got servicebroker, then just send a message to service broker and then let it to handle the rest.
		DECLARE @sMessage NVARCHAR(MAX)

		SET @sMessage = 'EXEC dbo.NAP_Admin_Calculate_Parlay @matchid = ' + CASE 
				WHEN @matchid IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @matchid)
				END + '
			,@matchids = ' + CASE 
				WHEN @matchids IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(2000), @matchids) + ''''
				END + '
			,@mode = ' + CASE 
				WHEN @mode IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @mode) + ''''
				END + '
			,@action = ' + CASE 
				WHEN @action IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @action) + ''''
				END + '
			,@fth = ' + CASE 
				WHEN @fth IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @fth)
				END + '
			,@fta = ' + CASE 
				WHEN @fta IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @fta)
				END + '
			,@hth = ' + CASE 
				WHEN @hth IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @hth)
				END + '
			,@hta = ' + CASE 
				WHEN @hta IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @hta)
				END + '
			,@matchdate = ' + CASE 
				WHEN @matchdate IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @matchdate) + ''''
				END + '
			,@TennisTotal = ' + CASE 
				WHEN @TennisTotal IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TennisTotal)
				END + '
			,@statusID = ' + CASE 
				WHEN @statusID IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @statusID)
				END + '
			,@winlostdate = ' + CASE 
				WHEN @winlostdate IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @winlostdate) + ''''
				END + '
			,@strXML = ' + CASE 
				WHEN @strXML IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(max), @strXML) + ''''
				END + '
			,@CalledByBrokerService = 1'

		EXEC [sb].[SBInputMessage] @fromService = N'//Service/Calculation_send'
			,@toService = N'//Service/Calculation_receive'
			,@onContract = N'//Contract/Calculation'
			,@messageType = N'//Message/Calculation'
			,@messageBody = @sMessage

		RETURN
	END
	ELSE
	BEGIN
		IF @mode = 'ALL'
		BEGIN
			--if REFUND-FT or REFUND-HT called, do 'CAL' first, before do 'REFUND-FT'
			BEGIN TRANSACTION

			IF @action IN ('REFUND-FT', 'REFUND-HT')
			BEGIN
				EXEC dbo.NAP_Admin_Calculate_9m @matchid = @matchid
					,@fth = @fth
					,@fta = @fta
					,@hth = @hth
					,@hta = @hta
					,@matchdate = @matchdate
					,@action = 'CAL'
					,@TennisTotal = @TennisTotal
			END

			COMMIT TRANSACTION

			BEGIN TRANSACTION

			EXEC dbo.NAP_Admin_Calculate_9m @matchid = @matchid
				,@fth = @fth
				,@fta = @fta
				,@hth = @hth
				,@hta = @hta
				,@matchdate = @matchdate
				,@action = @action
				,@TennisTotal = @TennisTotal

			COMMIT TRANSACTION
		END

		IF @mode = 'PRECAL-29'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_29_Precal @matchids
		END

		IF @mode = 'CAL-29'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_29 @matchids = @matchids
				,@matchdate = @matchdate
		END

		IF @mode = 'CAL-9'
		BEGIN
			EXEC dbo.NAP_Admin_Calculate_9 @statusID = @statusID
				,@winlostdate = @winlostdate
				,@strXML = @strXML
		END
	END
END


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_Parlay] TO [vnteam] AS [dbo]
GO


