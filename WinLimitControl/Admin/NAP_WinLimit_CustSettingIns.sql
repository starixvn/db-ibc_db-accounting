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
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns_xtest] @CustId            INT,
                                                           @ProductId         INT,
                                                           @BetTypeId         INT,
                                                           @SiteId            INT,
                                                           @CurrencyId        INT,
                                                           @OrangeMaxWinLimit MONEY,
                                                           @YellowMaxWinLimit MONEY,
                                                           @RedMaxWinLimit    MONEY,
                                                           @UserID            INT         = 0,
                                                           @IP                VARCHAR(20) = ''
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/CustDB
	
	Revisions:
	
	Parameters Explanation:	
	EXEC [NAP_WinLimit_CustSettingIns_xtest] 
	   @CustId = 662531, 
	   @ProductId =22,
	   @BetTypeId=4001,
	   @SiteId=16,
	   @CurrencyId=1,
	   @OrangeMaxWinLimit=1000,
	   @YellowMaxWinLimit=1000, 
	   @RedMaxWinLimit=1000, 
	   @UserId=1, 
	   IP='127.0.0.1'
	
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
     SELECT @StartRun = GETDATE();
     SELECT @OrangeMaxWinLimit = ISNULL(@OrangeMaxWinLimit, 0),
            @YellowMaxWinLimit = ISNULL(@YellowMaxWinLimit, 0),
            @RedMaxWinLimit = ISNULL(@RedMaxWinLimit, 0);
     BEGIN -- @InsertingSettings
         DECLARE @InsertingSettings TABLE
         (LevelId     INT,
          MaxWinLimit MONEY
         );
         INSERT INTO @InsertingSettings
         VALUES
         (1,
          @OrangeMaxWinLimit
         ),
         (2,
          @YellowMaxWinLimit
         ),
         (3,
          @RedMaxWinLimit
         );
     END;
     BEGIN -- VALIDATE
         IF(@OrangeMaxWinLimit > 0 --Check if @OrangeMaxWinLimit < @YellowMaxWinLimit
            AND @YellowMaxWinLimit > 0
            AND @OrangeMaxWinLimit >= @YellowMaxWinLimit)
             BEGIN
                 SELECT 1 AS ErrorCode,
                        'Orange max limit must less than yellow max limit.' AS ErrorMessage;
                 RETURN;
             END;
         IF(@YellowMaxWinLimit > 0 --Check if @YellowMaxWinLimit < @RedMaxWinLimit
            AND @RedMaxWinLimit > 0
            AND @YellowMaxWinLimit >= @RedMaxWinLimit)
             BEGIN
                 SELECT 1 AS ErrorCode,
                        'Yellow max limit must less than red max limit.' AS ErrorMessage;
                 RETURN;
             END;
         IF EXISTS -- Check if setting existed
         (
             SELECT 1
             FROM dbo.WinLimit_CustGameSetting
             WHERE CustID = @CustId
                   AND ProductID = @ProductId
                   AND BetTypeId = @BetTypeId
         )
             BEGIN
                 SELECT 2 AS ErrorCode,
                        'This setting already existed.' AS ErrorMessage;
                 RETURN;
             END;         
     END;
     BEGIN -- INSERT
         BEGIN TRY
             INSERT INTO dbo.WinLimit_CustGameSetting
             (CustID,
              ProductID,
              BetTypeID,
              LevelID,
              MaxWinLimit
             )
                    SELECT @CustId,
                           @ProductId,
                           @BetTypeId,
                           s.LevelId,
                           s.MaxWinLimit
                    FROM @InsertingSettings s;
         END TRY
         BEGIN CATCH
             SELECT 5 AS ErrorCode,
                    'This setting cannot be inserted because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     BEGIN --LOG
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SELECT @LogSPData = '<NAP_WinLimit_CustSettingIns '+'"CustId ="'+CONVERT( VARCHAR(20), @CustId)+'" ProductId ="'+CONVERT(VARCHAR(20), @ProductId)+'" BetTypeId ="'+CONVERT(VARCHAR(20), @BetTypeId)+'" SiteId ="'+CONVERT(VARCHAR(20), @SiteId)+'" CurrencyId ="'+CONVERT(VARCHAR(20), @CurrencyId)+'" @OrangeMaxWinLimit ="'+CONVERT(VARCHAR(20), @OrangeMaxWinLimit)+'" @YellowMaxWinLimit ="'+CONVERT(VARCHAR(20), @YellowMaxWinLimit)+'" @RedMaxWinLimit ="'+CONVERT(VARCHAR(20), @RedMaxWinLimit)+'" UserID ="'+CONVERT(VARCHAR(20), @UserID)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
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