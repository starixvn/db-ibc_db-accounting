USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingIns_xtest]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns_xtest];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns_xtest] @CustId      INT,
                                                           @ProductId   INT,
                                                           @BetTypeId   INT,
                                                           @LevelId     INT,
                                                           @ExchangeId  INT,
                                                           @SiteId      INT,
                                                           @MaxWinLimit MONEY,
                                                           @UserID      INT         = 0,
                                                           @IP          VARCHAR(20) = ''
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	
	
*/



     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
     SELECT @StartRun = GETDATE();
     DECLARE @ErrCode INT= 0, @ErrMsg NVARCHAR(200)= '';
     IF EXISTS
     (
         SELECT 1
         FROM dbo.WinLimit_CustGameSetting
         WHERE CustID = @CustId
               AND ProductID = @ProductId
               AND BetTypeId = @BetTypeId
               AND LevelId = @LevelId
     )
         BEGIN
             SELECT 1 AS ErrorCode,
                    'This setting already existed.' AS ErrorMessage;
             RETURN;
         END;
     ELSE
     IF EXISTS
     (
         SELECT 1
         FROM dbo.WinLimit_ProductSettingDetail
         WHERE ProductId = @ProductId
               AND BetTypeId = @BetTypeId
               AND ExchangeId = @ExchangeId
               AND SiteId = @SiteId
               AND LevelId = @LevelId
               AND MaxWinLimit < @MaxWinLimit
               AND MaxWinLimit > 0
     )
         BEGIN
             SELECT 2 AS ErrorCode,
                    'The player win litmit must not greater than the currency win limit.' AS ErrorMessage;
             RETURN;
         END;
     ELSE
         BEGIN -- INSERT
             BEGIN TRY
                 INSERT INTO dbo.WinLimit_CustGameSetting
                 (CustID,
                  ProductID,
                  BetTypeID,
                  LevelID,
                  MaxWinLimit
                 )
                 VALUES
                 (@CustId,
                  @ProductId,
                  @BetTypeId,
                  @LevelId,
                  @MaxWinLimit
                 );
             END TRY
             BEGIN CATCH
                 SELECT 3 AS ErrorCode,
                        'This setting cannot be inserted because of an database internal error.' AS ErrorMessage;
                 RETURN;
             END CATCH;
         END;;
     BEGIN --Log
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SELECT @LogSPData = '<NAP_WinLimit_CustSettingIns '+'"CustId ="'+CONVERT( VARCHAR(20), @CustId)+'" ProductId ="'+CONVERT(VARCHAR(20), @ProductId)+'" BetTypeId ="'+CONVERT(VARCHAR(20), @BetTypeId)+'" LevelId ="'+CONVERT(VARCHAR(20), @LevelId)+'" MaxWinLimit ="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" UserID ="'+CONVERT(VARCHAR(20), @UserID)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @UserID,
                  @ActionID = 31203,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT 0 AS ErrorCode,
            '' AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingIns_xtest] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingIns_xtest] TO [vnteam];
GO