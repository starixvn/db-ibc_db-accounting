/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerInsMember_CloneSetting_ExtraPT]
	@CustID				INT,
	@ExistingCustid		INT,	
	@Creator			INT,
	@IP					VARCHAR(20),
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(1000) = '' OUTPUT
AS

/*
	Creator: 20200405@Sophia 
	Task: Clone setting ExtraPT from existing Super [redmineId: #130647]
	DB: DBCUST-CUSTDB

	Revisions:
		- 20200405@Sophia: Clone setting ExtraPT from existing Super [redmineId: #130647]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogData NVARCHAR(MAX)
	SELECT  @StartRun = GETDATE()
	
	DECLARE @EffectiveDate DATETIME = '',  @Today DATE = GETDATE(), @GroupName VARCHAR(1000) = '', @EffectiveDates VARCHAR(1000) = ''  
		
 		
	SELECT @EffectiveDate= @Today	
	
	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_GroupExtraPTSetting WITH (NOLOCK) WHERE SuperID = @Custid AND ToDate > = @EffectiveDate)
	BEGIN 
		INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct,
												ExtraPT, FromDate, ToDate, UplineId)
		SELECT @CustId, GroupId, GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
			CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
			ToDate,	UplineId
		FROM Acc_GroupExtraPTSetting WITH (NOLOCK)
		WHERE SuperId = @ExistingCustid
			  AND ToDate >= @EffectiveDate			  
	END
	ELSE
	BEGIN 
			SELECT
				@ErrCode = 101,
				@ErrMsg = N'This CustID ' + CONVERT(VARCHAR(10), @CustID) + ' had had ExtraPT group.'
			RETURN
	END 
				
	SELECT	DISTINCT GroupName, FromDate  
	INTO	#GroupName
	FROM	dbo.Acc_GroupExtraPTSetting WITH (NOLOCK) 
	WHERE	SuperID = @Custid AND ToDate > = @EffectiveDate

	SELECT  @GroupName = COALESCE (@GroupName, ', ','') + GroupName,
			@EffectiveDates = COALESCE (@EffectiveDates, ', ','') + FromDate
	FROM   #GroupName
	
		-- Write log 
		SELECT  @LogData = '<EAS_CustomerInsMember_CloneSetting_ExtraPT CustID="' + CONVERT(NVARCHAR(20), @CustID)
							+ '" GroupName="' + @GroupName						
							+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), @EffectiveDates, 120)
							+ '" IP="' + @IP
							+ '" ErrCode="' + CONVERT(NVARCHAR(4), @ErrCode)
							+ '" ErrMsg="' + @ErrMsg + '" />'
							
	
							
		SELECT @EndRun = GETDATE()
		SELECT @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
			
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @Creator,
				@CustID = @CustID,
				@ActionID = 95010,
				@TrackingValue = @LogData,
				@Duration = @Duration 
	  
	
END
GO