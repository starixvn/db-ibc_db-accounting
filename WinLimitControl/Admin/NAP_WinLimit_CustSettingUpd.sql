USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].NAP_WinLimit_CustSettingUpd_xtest')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].NAP_WinLimit_CustSettingUpd_xtest;
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].NAP_WinLimit_CustSettingUpd_xtest    Script Date: 07/07/2015 16:09:49 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].NAP_WinLimit_CustSettingUpd_xtest @CustID      INT,
                                                         @ProductID   INT,
                                                         @BetTypeID   INT,
                                                         @LevelID     INT,
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
	
	EXEC [NAP_WinLimit_CustNotConfigProductCheck_xtest] @Username = '166HK488' , @ExcludeTestData = 0
	
*/


     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @MaxWinLimitOld MONEY;
     SELECT @StartRun = GETDATE();
     BEGIN -- Save State

         SELECT @MaxWinLimitOld = MaxWinLimit
         FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND BetTypeId = @BetTypeId
               AND LevelId = @LevelId;
     END;
     IF(@MaxWinLimitOld IS NULL)
         BEGIN
             SELECT 2 AS ErrorCode,
                    'This setting does not exist.' AS ErrorMessage;
             RETURN;
         END;
     BEGIN -- @CurrencyId, @SiteId
         DECLARE @SiteId INT, @SiteName VARCHAR(50), @AgentId INT, @CurrencyId INT;
         SELECT @CurrencyId = c.currency,
                @AgentId = c.recommend
         FROM dbo.Customer c WITH (NOLOCK)
         WHERE CustId = @CustId;
         SELECT @SiteId = s.siteid
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON c.site = s.site
         WHERE CustId = @AgentId;
     END;
     BEGIN --Validate player win limit < currency win limit

         DECLARE @CurrencyWinLimit MONEY;
         SELECT @CurrencyWinLimit = ISNULL(MaxWinLimit, 0)
         FROM dbo.WinLimit_ProductSettingDetail WITH (NOLOCK)
         WHERE ProductID = @ProductID
               AND BetTypeId = @BetTypeId
               AND LevelId = @LevelId
               AND ExchangeId = @CurrencyId
               AND SiteId = @SiteId;
         IF @CurrencyWinLimit < @MaxWinLimit
            AND @CurrencyWinLimit > 0
             BEGIN
                 SELECT 3 AS ErrorCode,
                        'Player WinLimit cannot greater than Currency WinLimit.' AS ErrorMessage;
                 RETURN;
             END;
     END;
     BEGIN -- UPDATE

         BEGIN TRY
             UPDATE dbo.WinLimit_CustGameSetting WITH(ROWLOCK, UPDLOCK)
               SET
                   MaxWinLimit = @MaxWinLimit
             WHERE CustID = @CustID
                   AND ProductID = @ProductID
                   AND BetTypeId = @BetTypeId
                   AND LevelId = @LevelId;
         END TRY
         BEGIN CATCH
             SELECT 4 AS ErrorCode,
                    'This setting cannot be inserted because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     BEGIN -- Log
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         DECLARE @TrackingValue VARCHAR(300), @TrackingValue2 VARCHAR(300);
         SELECT @TrackingValue = '<NAP_WinLimit_CustSettingUpd '+'" CustID ="'+CONVERT( VARCHAR(20), @CustID)+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID)+'" BetTypeID="'+CONVERT(VARCHAR(20), @BetTypeID)+'" LevelID="'+CONVERT(VARCHAR(20), @LevelID)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         SELECT @TrackingValue2 = '<NAP_WinLimit_CustSettingUpd '+'" CustID ="'+CONVERT( VARCHAR(20), @CustID)+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID)+'" BetTypeID="'+CONVERT(VARCHAR(20), @BetTypeID)+'" LevelID="'+CONVERT(VARCHAR(20), @LevelID)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimitOld)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31204,
                  @TrackingValue = @TrackingValue,
                  @TrackingValue2 = @TrackingValue2,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
GO
GRANT EXECUTE ON [dbo].NAP_WinLimit_CustSettingUpd_xtest TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].NAP_WinLimit_CustSettingUpd_xtest TO [vnteam];
GO