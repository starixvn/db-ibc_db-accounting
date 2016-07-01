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
                     SELECT TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd '+'" ProductID ="'+CONVERT( VARCHAR(20), @ProductId)+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId)+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId)+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId)+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @OldMaxWinLimit)+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @OldIsBlockedPlaceBet)+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @OldIsBlockedTransfer)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                     DECLARE @TrackingValue2 VARCHAR(500);
                     SELECT @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd '+'" ProductID ="'+CONVERT( VARCHAR(20), @ProductId)+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId)+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId)+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId)+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet)+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                     EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                          @UserID = @UserID,
                          @ActionID = 31201,
                          @TrackingValue = TrackingValue1,
                          @TrackingValue2 = TrackingValue2,
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
                     SELECT @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd '+'" ProductID ="'+CONVERT( VARCHAR(20), @ProductId)+'" BettypeID="'+CONVERT(VARCHAR(20), @BettypeId)+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId)+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId)+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet)+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
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