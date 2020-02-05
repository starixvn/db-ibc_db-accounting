/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet"  isFunction="0" isNested="0"></info>*/

USE [CustDB]
GO

CREATE PROCEDURE [dbo].[CS_ReportPermission_Upd]
      @CustID INT
	, @IsViewAllPeriod BIT
	, @UserID INT=0
	, @LoginIP VARCHAR(20)=''
	, @IsUpdated BIT = 1 OUTPUT
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
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX), @LogSPData2 NVARCHAR(MAX), @Old_IsViewAllPeriod BIT = 0
	SET @startRun = GETDATE();
	IF EXISTS(SELECT 1 FROM dbo.CS_ReportPermission WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN 
	     BEGIN TRY
			 UPDATE CS
			 SET CS.IsViewAllPeriod = @IsViewAllPeriod, @Old_IsViewAllPeriod = CS.IsViewAllPeriod
			 FROM dbo.CS_ReportPermission CS
			 WHERE CS.CustID = @CustID AND CS.IsViewAllPeriod <> @IsViewAllPeriod
			 IF @@ROWCOUNT = 0
				  SELECT @Old_IsViewAllPeriod =  @IsViewAllPeriod, @IsUpdated = 0
		 END TRY
		 BEGIN CATCH
		     SELECT @ErrCode =  ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE(), @IsUpdated = 0
		 END CATCH
	END
	ELSE 
	BEGIN
	    BEGIN TRY
			INSERT INTO dbo.CS_ReportPermission(CustID, IsViewAllPeriod)
	    	VALUES(@CustID, @IsViewAllPeriod)
		END TRY
		BEGIN CATCH
		      SELECT @ErrCode =  ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE(), @IsUpdated = 0
		END CATCH      
	END 
	IF @IsUpdated = 1
	BEGIN 
	     SELECT @LogSPData = '<R IsViewAllPeriod="'+ COALESCE(CAST(@IsViewAllPeriod AS VARCHAR(3)), SPACE(1)) + '" ' +
							'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

         SELECT @LogSPData2 = '<R IsViewAllPeriod="'+ COALESCE(CAST(@Old_IsViewAllPeriod AS VARCHAR(3)), SPACE(1)) + '" ' +
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
	
END
GO


