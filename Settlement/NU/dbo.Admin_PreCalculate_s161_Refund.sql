CREATE PROCEDURE [Admin_PreCalculate_s161_Refund] @matchid INT
	,@action VARCHAR(10) = 'Refund-FT' -- Refund / Refund-FT
AS
/*
	Created by:[Viet]
	Date:[20131208]
	Task: Settlement (Refund) 
	Original SP: Admin_Calculate_s161_Refund
	DB: DBTXN/BODB02		

	Revisions:		
		- 20140509@Kathy: insert settled command into LAS queue [Redmine:#14286]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IgnoreList VARCHAR(200)
	SET @IgnoreList = 'DB04,DB042,DB043,DB044'

	DECLARE @_xml XML, @_sXML VARCHAR(MAX)
		,@LASCommand NVARCHAR(max),@createdDate DATETIME, @Remark varchar(500)

	SELECT @LASCommand = '',
		@Remark = ''

	SET @_xml = '<root><r matchid="'+ CONVERT(VARCHAR(12), @matchid) +'" action="'+ @action +'" /></root>'

	SELECT @_sXML = CONVERT(VARCHAR(max), @_xml)

	EXEC dbo.Bet_ExecRep_05 @IgnoreList = @IgnoreList
		,@updatetype = 4 --refund NG
		,@_sXML = @_sXML		

	--- LAS settlement 
	SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_s161_Refund] @_sXML = ''' + @_sXML + ''''
				,@createdDate = GETDATE()

	BEGIN TRY
			EXEC DBLAS.LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_s161_Refund'
				,@SQLCommand = @LASCommand
				,@CreatedDate = @createdDate
				,@StatusID = 0 -- waiting
				,@MatchID = @matchid
				,@Bettype = NULL
				,@Status = 'waiting'
				,@BetCount = NULL
		END TRY
		BEGIN CATCH			
			SELECT @Remark = '@matchid = ' + @matchid + ', @action = ''' + @action + ''''

			BEGIN TRY			
				EXEC DBLOG.bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
								@UserID = NULL, 
								@Matchid = @matchid, 
								@ActionID = 40015, 
								@Remark = @Remark
			END TRY
			BEGIN CATCH
				EXEC bodb_CustomerLog.dbo.LAS_WriteLog_UserLog_RunSP
								@UserID = NULL, 
								@Matchid = @matchid, 
								@ActionID = 40015, 
								@Remark = @Remark
			END CATCH
		END CATCH

END

GO

GRANT VIEW DEFINITION ON [Admin_PreCalculate_s161_Refund] TO [vnteam] AS [dbo]
GO


