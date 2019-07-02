/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
USE [CustDB]
GO
ALTER PROCEDURE [dbo].[CS_GroupExtraPT_Upd]
	@CustID				INT,
	@ExtraPTSetting		VARCHAR(MAX),	
	@EffectiveDate 		DATE, 	
	@UserID				INT,
	@IP					VARCHAR(15)='',
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(1000) = '' OUTPUT
AS

/*
	Creator: 20190620@Sophia	
	Task: CN88 - Edit ExtraPT Setting For Super 
	DB: DBCUST.CustDB 
	
	Revisions:
		- 20190620@Sophia: initial SP[RedmineID: #114912] 
		 
	Original: Acc_GroupExtraPTSetting_Upd
	Param's Explanation:
		- @EffectiveDate		
			
		- @ExtraPTSetting:	<ROOT>
								<ExtraPT ProductId="1" ExtraPT="0.02"/>
								<ExtraPT ProductId="3" ExtraPT="0.03"/>
							</ROOT>	
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun DATETIME , @endRun DATETIME , @duration INT, @TrackingValue2 NVARCHAR(MAX), @TrackingValue NVARCHAR(MAX)	
	SELECT @startRun = GETDATE()	
	
	DECLARE @today DATETIME, @EndDate DATETIME, @FromDate DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE()), @EndDate = '9999-12-31'
	DECLARE @GroupId INT, @GroupName VARCHAR(50), @HeadlineId INT,  @HeadlineUsername	VARCHAR(30)			

	DECLARE @ExtraPTTmp	TABLE(ProductId INT, ExtraPT MONEY) 	
		
	IF @EffectiveDate < @today
	BEGIN			 
		SELECT
			@ErrCode = 101,
			@ErrMsg = N'Invalid effective date.'
		RETURN		 
	END	
		
	-- get Rate
	DECLARE @DocHandler INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @ExtraPTSetting
		
		INSERT INTO @ExtraPTTmp (ProductId, ExtraPT)
		SELECT ProductId, ExtraPT
		FROM OPENXML(@DocHandler, '/ROOT/ExtraPT', 1) WITH (ProductId INT, ExtraPT MONEY) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END TRY
	BEGIN CATCH
		SELECT ErrCode = 100
			,ErrMsg = N'Paramter invalid.'
		RETURN
		
	END CATCH;
	
	--- get group extraPT			
	SELECT @GroupName = GroupName, @GroupId = GroupId
	FROM dbo.Acc_GroupExtraPT_Product a WITH (NOLOCK) 
		INNER JOIN @ExtraPTTmp e 
			ON  e.ProductID = a.ProductID
				AND e.ExtraPT = a.ExtraPT
	WHERE  	@today BETWEEN a.FromDate AND a.ToDate
			AND a.ProductID IN (1, 3)
			AND Sporttype = 0 AND SubProduct = ''
			AND GroupID BETWEEN 27 AND 42
	GROUP BY GroupName, GroupId
	HAVING COUNT(GroupId) = 2 
	
	IF @GroupName IS NULL OR @GroupID IS NULL
	BEGIN			 
		SELECT
			@ErrCode = 102,
			@ErrMsg = N'Invalid rates.'
		RETURN		 
	END
	 
	---- Check already existed		
	SELECT  @FromDate = MIN(FromDate) 
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
	WHERE SuperId = @CustID 
		AND GroupId = @GroupId 
		AND @EffectiveDate BETWEEN FromDate AND ToDate 
		AND FromDate <= @today
	
	IF @FromDate IS NOT NULL
	BEGIN
		IF NOT EXISTS (
			SELECT TOP 1 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
			WHERE SuperId = @CustID 
				AND GroupId <> @GroupId
				AND FromDate > @today
		)
		BEGIN
			SELECT
				@ErrCode = 103,
				@ErrMsg = N'There is no change to be updated.'
			RETURN
		END
	END	
	
	---- Log before update
		
	SELECT @HeadlineId = UplineId
	FROM dbo.CustSuper WITH (NOLOCK) 
	WHERE CustID = @CustID	
	
	SELECT @HeadlineUsername = username FROM dbo.CustInfo WITH (NOLOCK) WHERE CustID = @HeadlineId AND roleid = 0

	SELECT  TOP 1 @TrackingValue2 =  '<R Headline="'+ @HeadlineUsername
					+ '" GroupName="' + GroupName 
					+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), FromDate, 120)
					+ '" />'				
	FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
	WHERE SuperId = @CustID AND @Today BETWEEN FromDate AND ToDate  
	

	---- delete and update lated rows if any
	DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
	WHERE SuperId = @CustID AND FromDate > @Today
		AND ToDate >= @today

	UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
	SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
	WHERE SuperId = @CustID AND FromDate <= @EffectiveDate
		AND ToDate >= @today
	 
	----- Insert new setting PT		
	INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
	SELECT @CustId, @GroupId, @GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
		CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
		CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate
	FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
	WHERE GroupId = @GroupId
		  AND @EffectiveDate <= ToDate	
		  
	
	--- Log after update	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (millisecond,@startRun,@endRun)	
		  
	SELECT  @TrackingValue = '<R Headline="'+ @HeadlineUsername 
					+ '" GroupName="' + @GroupName 
					+ '" EffectiveDate="' + CONVERT(NVARCHAR(10), @EffectiveDate, 120)
					+ '" IP="' + @IP + '" />'

	EXEC CS_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 160009,
		@TrackingValue = @TrackingValue,
		@TrackingValue2 = @TrackingValue2,
		@Duration = @Duration
	
END
GO