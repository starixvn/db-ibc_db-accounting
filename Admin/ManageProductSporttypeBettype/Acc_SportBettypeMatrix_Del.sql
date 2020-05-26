/*<info serverAlias="DBPRO-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  dbo.Acc_SportBettypeMatrix_Del
	@SportType   SMALLINT,
	@BetType     SMALLINT,
	@Islive      BIT,
	@ErrCode     INT = 0 OUTPUT,
	@ErrMsg      NVARCHAR(MAX) = '' OUTPUT,
	@UserID      INT,
	@LoginIP     VARCHAR(20) = ''
AS

/*
Created: 20200416@Malcolm
Task :  NAP Manage Products/Sporttype/Bettype
DB: DBPRO/bodb02
Original:

	Revisions:
		- 20200416@Malcolm: NAP Manage Products/Sporttype/Bettype [Redmine: #131241]
		
*/

BEGIN
    SET NOCOUNT ON
	
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)

	BEGIN TRY
		DELETE m
		FROM dbo.SportBettypeMatrix m
		WHERE m.SportType = @SportType AND m.BetType = @BetType AND m.IsLive = @Islive
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	SELECT @LogSPData = '<R SportType="'+ COALESCE(CAST(@SportType AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'BetType="' + COALESCE(CAST(@BetType  AS VARCHAR(6)), SPACE(1)) + '" ' +
		                    'IsLive="' + COALESCE(CAST(@Islive   AS VARCHAR(2)), SPACE(1)) + '" ' +																		
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

	SET @endRun = GETDATE()
    SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@ActionID = 95015,
			@TrackingValue = @LogSPData,
			@duration = @duration
	
END

