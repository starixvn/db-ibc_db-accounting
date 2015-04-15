USE [bodb02]
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Parlay] @matchid INT = NULL
	,@matchids VARCHAR(2000) = NULL
	,@mode VARCHAR(15) = 'CAL'
	,@action VARCHAR(20) = 'ALL'
	,@resultPS NVARCHAR(10) = NULL
	,@IsRefundHT BIT = 0
	,@fth INT = NULL
	,@fta INT = NULL
	,@hth INT = NULL
	,@hta INT = NULL
	,@matchdate DATETIME = NULL
	,@TennisTotal SMALLINT = NULL
	,@statusID TINYINT = NULL
	,@winlostdate SMALLDATETIME = NULL
	,@VoidTransID VARCHAR(2000) = NULL
	,@UserId INT = NULL
	,@strXML VARCHAR(MAX) = NULL
	,@SelectedSet			VARCHAR(50) = NULL 
	,@TotalGameMatch		INT = NULL
	,@TotalGameHomeMatch	INT = NULL
	,@TotalGameAwayMatch	INT	= NULL 
	,@TotalGameHomeSet1		INT	= NULL 
	,@TotalGameHomeSet2		INT = NULL 
	,@TotalGameHomeSet3		INT = NULL 
	,@TotalGameHomeSet4		INT = NULL 
	,@TotalGameHomeSet5		INT = NULL 
	,@TotalGameAwaySet1		INT = NULL 
	,@TotalGameAwaySet2		INT = NULL 
	,@TotalGameAwaySet3		INT = NULL 
	,@TotalGameAwaySet4		INT = NULL 
	,@TotalGameAwaySet5		INT = NULL 
	,@SetxGameyHomeWON		VARCHAR(MAX) = NULL 
	,@SetxGameyAwayWON		VARCHAR(MAX) = NULL 
	,@SetxGameyDRAW			VARCHAR(MAX) = NULL 
	,@SetxGameyFinishedGame	VARCHAR(MAX) = NULL 	
	,@SetxGameyREFUND		VARCHAR(MAX) = NULL 
	,@SelectedSetCAL		VARCHAR(50)  = NULL
	,@SelectedSetREFUND		VARCHAR(50)  = NULL 
	,@ResourceIDs			VARCHAR(MAX) = NULL
	,@CalledByBrokerService BIT = 0 
AS
/*
	Created: Kathy
	Task : Covered SP for settlement (Parlay)
	Original SP: 
	DB: EXECREP SP (DBTrans_Bet)

	Revisions:
		- 20140424@Lukas: add DBTP server 
		- 20140716@Kathy: Apply BetRadar [Redmine:#17142]
		- 20140720@Kathy: Apply BetRadar - PenaltyShootout(135) [Redmine:#17142]
		- 20140815@Kathy: add more mode for Special Delete function
		- 20150206@Jamie: Auto Settlement Betradar phase 2 [Redmine: #27212]

	Param's Explanation:
		@action			@mode
		
*/
BEGIN
	SET NOCOUNT ON;

	IF @@SERVERNAME IN ('DB052', 'DB053', 'DB054', 'DB06', 'DBTP', 'DB231', 'DB232','DB215') AND @CalledByBrokerService = 0
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
			,@resultPS = ' + CASE 
				WHEN @resultPS IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(50), @resultPS) + ''''
				END + '
			,@IsRefundHT = ' + CASE 
				WHEN @IsRefundHT IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @IsRefundHT)
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
			,@VoidTransID = ' + CASE 
				WHEN @VoidTransID IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(NVARCHAR(2000), @VoidTransID) + ''''
				END + '
			,@UserId = ' + CASE 
				WHEN @UserId IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @UserId)
				END + '
			,@strXML = ' + CASE 
				WHEN @strXML IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(max), @strXML) + ''''
				END + '
			,@SelectedSet = ' + CASE 
				WHEN @SelectedSet IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(50), @SelectedSet) + ''''
				END + '
			,@TotalGameMatch = ' + CASE 
				WHEN @TotalGameMatch IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameMatch)
				END + '
			,@TotalGameHomeMatch = ' + CASE 
				WHEN @TotalGameHomeMatch IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeMatch)
				END + '

			,@TotalGameAwayMatch = ' + CASE 
				WHEN @TotalGameAwayMatch IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwayMatch)
				END + '
			,@TotalGameHomeSet1 = ' + CASE 
				WHEN @TotalGameHomeSet1 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeSet1)
				END + '
			,@TotalGameHomeSet2 = ' + CASE 
				WHEN @TotalGameHomeSet2 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeSet2)
				END + '
			,@TotalGameHomeSet3 = ' + CASE 
				WHEN @TotalGameHomeSet3 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeSet3)
				END + '
			,@TotalGameHomeSet4 = ' + CASE 
				WHEN @TotalGameHomeSet4 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeSet4)
				END + '
			,@TotalGameHomeSet5 = ' + CASE 
				WHEN @TotalGameHomeSet5 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameHomeSet5)
				END + '
			,@TotalGameAwaySet1= ' + CASE 
				WHEN @TotalGameAwaySet1 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwaySet1)
				END + '
			,@TotalGameAwaySet2= ' + CASE 
				WHEN @TotalGameAwaySet2 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwaySet2)
				END + '
			,@TotalGameAwaySet3= ' + CASE 
				WHEN @TotalGameAwaySet3 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwaySet3)
				END + '
			,@TotalGameAwaySet4= ' + CASE 
				WHEN @TotalGameAwaySet4 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwaySet4)
				END + '
			,@TotalGameAwaySet5= ' + CASE 
				WHEN @TotalGameAwaySet5 IS NULL THEN 'NULL'
				ELSE CONVERT(NVARCHAR(50), @TotalGameAwaySet5)
				END + '
			,@SetxGameyHomeWON = ' + CASE 
				WHEN @SetxGameyHomeWON IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(MAX), @SetxGameyHomeWON) + ''''
				END + '
			,@SetxGameyAwayWON = ' + CASE 
				WHEN @SetxGameyAwayWON IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(MAX), @SetxGameyAwayWON) + ''''
				END + '
			,@SetxGameyDRAW = ' + CASE 
				WHEN @SetxGameyDRAW IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(MAX), @SetxGameyDRAW) + ''''
				END + '
			,@SetxGameyFinishedGame = ' + CASE 
				WHEN @SetxGameyFinishedGame IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(MAX), @SetxGameyFinishedGame) + ''''
				END + '		
			,@SetxGameyREFUND = ' + CASE 
				WHEN @SetxGameyREFUND IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(MAX), @SetxGameyREFUND) + ''''
				END + '
			,@SelectedSetCAL = ' + CASE 
				WHEN @SelectedSetCAL IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(50), @SelectedSetCAL) + ''''
				END + '
			,@SelectedSetREFUND = ' + CASE 
				WHEN @SelectedSetREFUND IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(50), @SelectedSetREFUND) + ''''
				END + '

			,@ResourceIDs = ' + CASE 
				WHEN @ResourceIDs IS NULL THEN 'NULL'
				ELSE '''' + CONVERT(VARCHAR(50), @ResourceIDs) + ''''
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
					,@resultPS = @resultPS
					,@IsRefundHT = @IsRefundHT
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
				,@resultPS = @resultPS
				,@IsRefundHT = @IsRefundHT
				,@TennisTotal	= @TennisTotal
				,@SelectedSet	= @SelectedSet
				,@ResourceIDs	= @ResourceIDs

			COMMIT TRANSACTION
		END

		IF @mode='CAL-SET'
		BEGIN
												EXEC dbo.NAP_Admin_Calculate_9m @matchid = @matchid
				,@fth = @fth
				,@fta = @fta
				,@hth = @hth
				,@hta = @hta
				,@matchdate = @matchdate
				,@action = 'REFUND'
				,@resultPS = @resultPS
				,@IsRefundHT = @IsRefundHT
				,@TennisTotal				= @TennisTotal
				,@SelectedSetCAL			= @SelectedSetCAL 
				,@SelectedSetREFUND			= @SelectedSetREFUND 

												EXEC dbo.NAP_Admin_Calculate_9m @matchid = @matchid
				,@fth = @fth
				,@fta = @fta
				,@hth = @hth
				,@hta = @hta
				,@matchdate = @matchdate
				,@action = 'CAL'
				,@resultPS = @resultPS
				,@IsRefundHT = @IsRefundHT
				,@TennisTotal				= @TennisTotal
				,@TotalGameMatch			= @TotalGameMatch 
				,@TotalGameHomeMatch		= @TotalGameHomeMatch 
				,@TotalGameAwayMatch		= @TotalGameAwayMatch 
				,@TotalGameHomeSet1			= @TotalGameHomeSet1 
				,@TotalGameHomeSet2			= @TotalGameHomeSet2 
				,@TotalGameHomeSet3			= @TotalGameHomeSet3 
				,@TotalGameHomeSet4			= @TotalGameHomeSet4 
				,@TotalGameHomeSet5			= @TotalGameHomeSet5 
				,@TotalGameAwaySet1			= @TotalGameAwaySet1 
				,@TotalGameAwaySet2			= @TotalGameAwaySet2 
				,@TotalGameAwaySet3			= @TotalGameAwaySet3 
				,@TotalGameAwaySet4			= @TotalGameAwaySet4 
				,@TotalGameAwaySet5			= @TotalGameAwaySet5 
				,@SetxGameyHomeWON			= @SetxGameyHomeWON 
				,@SetxGameyAwayWON			= @SetxGameyAwayWON 
				,@SetxGameyDRAW				= @SetxGameyDRAW 
				,@SetxGameyFinishedGame		= @SetxGameyFinishedGame 
				,@SetxGameyREFUND			= @SetxGameyREFUND 
				,@SelectedSetCAL			= @SelectedSetCAL 
				,@SelectedSetREFUND			= @SelectedSetREFUND 
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
		
		IF @mode = 'VOID'
		BEGIN
												EXEC dbo.NAP_Admin_Calculate_9m 
				@matchid	= @MatchID,
				@fth		= 0, 
				@fta		= 0,
				@hth		= 0,  
				@hta		= 0,
				@matchdate	= @matchdate,
				@action		= 'VOID',
				@VoidTransID= @VoidTransID,
				@UserId		= @UserId
		END
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Parlay] TO [vnteam] AS [dbo]