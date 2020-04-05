/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_CustomerInsMember_CloneSetting_ExtraPT]
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
	
	DECLARE @EffectiveDate DATETIME = '', @GroupName VARCHAR(50) = '', @Today DATE = GETDATE()	    
		
	----- 1. check existing GroupName of existing Super	(current group)
	SELECT 	@EffectiveDate= MIN(FromDate) , @GroupName = GroupName 			 
	FROM 	dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
	WHERE 	SuperId = @ExistingCustid
			AND @Today BETWEEN FromDate AND ToDate 
	GROUP BY GroupName	

	IF ISNULL(@GroupName,'') <> '' 
	BEGIN 
 
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
		BEGIN
			SELECT
				@ErrCode = 102,
				@ErrMsg = N'This Customer does not belong to this group:' + @GroupName
			RETURN
		END


		-- Update table Acc_GroupExtraPTSetting
		EXEC dbo.Acc_GroupExtraPTSetting_Upd
			@CustID = @CustID,
			@GroupName = @GroupName,
			@EffectiveDate = @Today,
			@UserID = @Creator,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN			
	END
	 
	-- Write log 
	SELECT  @LogData = '<EAS_CustomerInsMember_CloneSetting_ExtraPT CustID="' + CONVERT(NVARCHAR(20), @CustID)
						+ '" GroupName="' + @GroupName
						+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), @Today, 120)
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
	
	
	---------2. check existing GroupName of existing Super (Future group)
	SELECT 	@EffectiveDate= MIN(FromDate) , @GroupName = GroupName 			 
	FROM 	dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
	WHERE 	SuperId = @ExistingCustid
			AND @Today < FromDate
	GROUP BY GroupName
	
	IF ISNULL(@EffectiveDate,'') <> '' 
	BEGIN 
 
		IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.Acc_CustGroup WITH(NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
		BEGIN
			SELECT
				@ErrCode = 102,
				@ErrMsg = N'This Customer does not belong to this group:' + @GroupName
			RETURN
		END


		-- Update table Acc_GroupExtraPTSetting
		EXEC dbo.Acc_GroupExtraPTSetting_Upd
			@CustID = @CustID,
			@GroupName = @GroupName,
			@EffectiveDate = @Today,
			@UserID = @Creator,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN

	 
		-- Write log
		SELECT  @LogData = '<EAS_CustomerInsMember_CloneSetting_ExtraPT CustID="' + CONVERT(NVARCHAR(20), @CustID)
							+ '" GroupName="' + @GroupName
							+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), @EffectiveDate, 120)
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
	
END
GO