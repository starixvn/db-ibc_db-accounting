/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[CS_GroupExtraPT_Ins]
	@CustID			INT,
	@HeadlineId		INT, 	
	@EffectiveDate	DATETIME ,
	@UserID			INT,
	@IP				VARCHAR(15)='',
	@IsRollBack		BIT = 0,
	@GroupName 		VARCHAR(50) OUTPUT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(1000) = '' OUTPUT
AS

/*
	Creator: 20190620@Sophia	
	Task: CN88 - Add setting ExtraPT when add new Super 
	DB: DBCUST.CustDB
	Original SP: CS_GroupExtraPTSetting_Upd, Acc_GroupExtraPTSetting_Upd
	
	Revisions:
		- 201900620@Sophia: initial SP, change name from CS_GroupExtraPTSetting_Upd [RedmineID: #114912] 
	 
	
	Param's Explanation:
		- @EffectiveDate
			+ IS NULL: remove @CustID from @GroupName
			+ NOT NULL: change @GroupName is Primary Extra PT Group of @CustID
*/

BEGIN
	SET NOCOUNT ON
	
		DECLARE @today DATETIME, @EndDate DATETIME, @FromDate DATETIME, @GroupId INT
		SELECT  @today = CONVERT(DATE, GETDATE()), @EndDate = '9999-12-31'	 
	
		IF @IsRollBack = 0 
		BEGIN
		
			IF @EffectiveDate < @today
			BEGIN 
				SELECT
					@ErrCode = 101,
					@ErrMsg = N'Invalid effective date.'
				RETURN	
			END
			
			--- get default group extraPT					
			SELECT @GroupId = GroupId
			FROM  dbo.CS_HeadlineExtraPTGroup WITH (NOLOCK) 
			WHERE HeadlineId = @HeadlineId
			
			SELECT TOP 1 @GroupName = GroupName 
			FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK) 
			WHERE GroupId = @GroupId

			IF @GroupName IS NULL OR @GroupID IS NULL
			BEGIN			 
				SELECT
					@ErrCode = 102,
					@ErrMsg = N'Invalid rates.'
				RETURN		 
			END
		
			---- Check already existed			
			SELECT @FromDate = MIN(FromDate) 
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
						@ErrMsg = N'The group ' + @GroupName + N' has already been the primary group since ' + CONVERT(NVARCHAR(10), @FromDate, 101)
					RETURN
				END
			END		
			-----
			
			BEGIN TRY
				--- delete and update lated rows if any
				DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				WHERE SuperId = @CustID 
					AND FromDate >= @EffectiveDate
					AND ToDate >= @today

				UPDATE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				SET ToDate = DATEADD(DAY, -1, @EffectiveDate)
				WHERE SuperId = @CustID 
					AND FromDate < @EffectiveDate
					AND ToDate >= @today
				-----
				
				----- Insert new setting PT						
				INSERT INTO dbo.Acc_GroupExtraPTSetting (SuperId, GroupId, GroupName, ProductId, Sporttype, SubProduct, ExtraPT, FromDate, ToDate)
				SELECT @CustId, @GroupId, @GroupName, ProductID, Sporttype, SubProduct, ExtraPT,
					CASE WHEN @EffectiveDate < FromDate THEN FromDate ELSE @EffectiveDate END AS FromDate,
					CASE WHEN @EndDate < ToDate THEN @EndDate ELSE ToDate END AS ToDate
				FROM dbo.Acc_GroupExtraPT_Product WITH(NOLOCK)
				WHERE GroupId = @GroupId
					AND @EffectiveDate <= ToDate		
										
			END TRY
			BEGIN CATCH			
				SELECT
					@ErrCode = 104,
					@ErrMsg = 'Error when insert/update/detete data.'	
				
				DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
				WHERE SuperId = @CustID 
					AND ToDate >= @today	
					
			END CATCH
			
		END
		ELSE   --- Rollback incase insert super fail
		BEGIN 			
			--- delete redundant data
			DELETE dbo.Acc_GroupExtraPTSetting WITH(ROWLOCK, UPDLOCK)
			WHERE SuperId = @CustID 
				 AND ToDate >= @today
		END
		
	

END
GO