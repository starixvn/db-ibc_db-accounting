USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingUpd]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd] @ProductId         INT,
                                                         @BettypeId         INT,
                                                         @CurrencyId        INT,
                                                         @SiteId            INT,
                                                         @LevelId           INT,
                                                         @MaxWinLimit       MONEY         = 0,
                                                         @IsBlockedPlaceBet BIT           = 0,
                                                         @IsBlockedTransfer BIT           = 0,
                                                         @UserID            INT           = 0,
                                                         @IP                VARCHAR(20)   = '',
                                                         @ErrorCode         INT           = 0 OUTPUT,
                                                         @ErrorMessage      NVARCHAR(500) = '' OUTPUT
AS

/*
    Created: Phillip	
    Date: 2015-06-26
    Task: #38608 - Implement function to control Player's Win Limit on specific Product

    DB: DBCUST/CustDB

    Revisions:
    20160616@Franklin: Implement Game Win Limit Control phase2 [#57722].

    Parameters Explanation:	
	   @ProductId: Product ID.
	   @BettypeId: Bettype ID.
	   @CurrencyId: Currency ID.
	   @SiteId: Site or Licensee ID.
	   @LevelId: Level ID.
	   @MaxWinLimit: Max Win Limit amount.
	   @IsBlockedPlaceBet: Is block place bet.
	   @IsBlockedTransfer: Is block transfer.
	   @UserID: User making this action.
	   @IP: IP of the machine making this action.
	   @ErrorCode: Error Code.
	   @ErrorMessage: Error Message.
*/

     BEGIN
         SET NOCOUNT ON;
         DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @TrackingValue1 VARCHAR(500);
         SELECT @StartRun = GETDATE();
         IF @MaxWinLimit <= 0
             BEGIN
                 SELECT @MaxWinLimit = 0;
             END;
         IF EXISTS
         (
             SELECT 1
             FROM dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK)
             WHERE wlpsd.ProductID = @ProductId
                   AND wlpsd.BettypeID = @BettypeId
                   AND wlpsd.ExchangeID = @CurrencyId
                   AND wlpsd.SiteID = @SiteId
                   AND wlpsd.LevelID = @LevelId
         )
             BEGIN -- Update
                 DECLARE @OldMaxWinLimit MONEY, @OldIsBlockedPlaceBet BIT, @OldIsBlockedTransfer BIT;
                 SELECT @OldMaxWinLimit = wlpsd.MaxWinLimit,
                        @OldIsBlockedPlaceBet = wlpsd.IsBlockedPlaceBet,
                        @OldIsBlockedTransfer = wlpsd.IsBlockedTransfer
                 FROM dbo.WinLimit_ProductSettingDetail wlpsd WITH (NOLOCK)
                 WHERE wlpsd.ProductID = @ProductId
                       AND wlpsd.BettypeID = @BettypeId
                       AND wlpsd.ExchangeID = @CurrencyId
                       AND wlpsd.SiteID = @SiteId
                       AND wlpsd.LevelID = @LevelId;
                 IF(@MaxWinLimit = @OldMaxWinLimit
                    AND @IsBlockedPlaceBet = @OldIsBlockedPlaceBet
                    AND @IsBlockedTransfer = @OldIsBlockedTransfer)
                     BEGIN
                         SELECT @ErrorCode = 0,
                                @ErrorMessage = 'There is no data to update.';
                         RETURN;
                     END;
                 ELSE
                     BEGIN TRY
                         UPDATE wlpsd
                           SET
                               wlpsd.MaxWinLimit = @MaxWinLimit,
                               wlpsd.IsBlockedPlaceBet = @IsBlockedPlaceBet,
                               wlpsd.IsBlockedTransfer = @IsBlockedTransfer
                         FROM dbo.WinLimit_ProductSettingDetail wlpsd WITH (ROWLOCK)
                         WHERE wlpsd.ProductID = @ProductId
                               AND wlpsd.BettypeID = @BettypeId
                               AND wlpsd.ExchangeID = @CurrencyId
                               AND wlpsd.SiteID = @SiteId
                               AND wlpsd.LevelID = @LevelId;
                     END TRY
                     BEGIN CATCH
                         IF @@ERROR <> 0
                             BEGIN
                                 SELECT @ErrorCode = 500,
                                        @ErrorMessage = 'There is an error while processing, please try again!';
                                 RETURN;
                             END;
                     END CATCH;
                 BEGIN -- Write Log
                     SELECT @EndRun = GETDATE(),
                            @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
                     SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
                     SET @TrackingValue1 = @TrackingValue1+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                     SET @TrackingValue1 = @TrackingValue1+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId);
                     SET @TrackingValue1 = @TrackingValue1+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                     SET @TrackingValue1 = @TrackingValue1+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                     SET @TrackingValue1 = @TrackingValue1+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                     SET @TrackingValue1 = @TrackingValue1+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @OldMaxWinLimit);
                     SET @TrackingValue1 = @TrackingValue1+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @OldIsBlockedPlaceBet);
                     SET @TrackingValue1 = @TrackingValue1+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @OldIsBlockedTransfer);
                     SET @TrackingValue1 = @TrackingValue1+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                     SET @TrackingValue1 = @TrackingValue1+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                     DECLARE @TrackingValue2 VARCHAR(500);
                     SET @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd ';
                     SET @TrackingValue2 = @TrackingValue2+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                     SET @TrackingValue2 = @TrackingValue2+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId);
                     SET @TrackingValue2 = @TrackingValue2+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                     SET @TrackingValue2 = @TrackingValue2+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                     SET @TrackingValue2 = @TrackingValue2+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                     SET @TrackingValue2 = @TrackingValue2+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit);
                     SET @TrackingValue2 = @TrackingValue2+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
                     SET @TrackingValue2 = @TrackingValue2+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer);
                     SET @TrackingValue2 = @TrackingValue2+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                     SET @TrackingValue2 = @TrackingValue2+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                     EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                          @UserID = @UserID,
                          @ActionID = 31201,
                          @TrackingValue = @TrackingValue1,
                          @TrackingValue2 = @TrackingValue2,
                          @Duration = @Duration;
                 END;
             END;
         ELSE
             BEGIN -- Insert data
                 BEGIN TRY
                     INSERT INTO dbo.WinLimit_ProductSettingDetail
                     (ProductID,
                      BettypeID,
                      ExchangeID,
                      SiteID,
                      LevelID,
                      MaxWinLimit,
                      IsBlockedPlaceBet,
                      IsBlockedTransfer
                     )
                     VALUES
                     (@ProductId,
                      @BettypeId,
                      @CurrencyId,
                      @SiteId,
                      @LevelId,
                      @MaxWinLimit,
                      @IsBlockedPlaceBet,
                      @IsBlockedTransfer
                     );
                 END TRY
                 BEGIN CATCH
                     IF @@ERROR <> 0
                         BEGIN
                             SELECT @ErrorCode = 500,
                                    @ErrorMessage = 'There is an error while processing, please try again!';
                             RETURN;
                         END;
                 END CATCH;
                 BEGIN -- Write log
                     SELECT @EndRun = GETDATE(),
                            @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
                     SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
                     SET @TrackingValue1 = @TrackingValue1+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                     SET @TrackingValue1 = @TrackingValue1+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId);
                     SET @TrackingValue1 = @TrackingValue1+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                     SET @TrackingValue1 = @TrackingValue1+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                     SET @TrackingValue1 = @TrackingValue1+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                     SET @TrackingValue1 = @TrackingValue1+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit);
                     SET @TrackingValue1 = @TrackingValue1+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
                     SET @TrackingValue1 = @TrackingValue1+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer);
                     SET @TrackingValue1 = @TrackingValue1+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                     SET @TrackingValue1 = @TrackingValue1+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                     EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                          @UserID = @UserID,
                          @ActionID = 31201,
                          @TrackingValue = @TrackingValue1,
                          @Duration = @Duration;
                 END;
             END;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [vnteam];
GO