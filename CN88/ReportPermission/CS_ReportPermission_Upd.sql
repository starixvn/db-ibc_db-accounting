/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet"  isFunction="0" isNested="0"></info>*/

USE [CustDB]
GO

CREATE PROCEDURE [dbo].[CS_ReportPermission_Upd]
      @CustID INT
	, @IsViewAllPeriod BIT
	, @UserID INT=0
	, @LoginIP VARCHAR(20)=''
	, @IsUpdated BIT = 0 OUTPUT
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: Malcolm
	Date: 2020-01-21
	Task:   Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	DB: DBCUST/CustDB

	Revisions:
		- 20200121@Malcolm:  Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX), @OldIsView BIT = 0
	SET @startRun = GETDATE();
	SET @IsUpdated = 1
	IF EXISTS(SELECT 1 FROM dbo.CS_ReportPermission WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN 
	     UPDATE CS
		 SET CS.IsViewAllPeriod = @IsViewAllPeriod, @OldIsView = CS.IsViewAllPeriod
		 FROM dbo.CS_ReportPermission CS
		 WHERE CS.CustID = @CustID AND CS.IsViewAllPeriod <> @IsViewAllPeriod
		 IF @@ROWCOUNT = 0
		      SET @OldIsView =  @IsViewAllPeriod

	END
	ELSE 
	BEGIN
        INSERT INTO dbo.CS_ReportPermission(CustID, IsViewAllPeriod)
		VALUES(@CustID, @IsViewAllPeriod)
	END 

	SELECT @LogSPData =	'<R IsViewAllPeriod="'+ COALESCE(CAST(@OldIsView AS VARCHAR(30)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

	SELECT @LogSPData2 ='<R IsViewAllPeriod="'+ COALESCE(CAST(@IsViewAllPeriod AS VARCHAR(30)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)
	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @UserID, 
			@CustID = @CustId,
			@ActionID = 95002,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @LogSPData2,
			@duration = @duration
END
GO


