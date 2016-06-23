USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingDel_xtest]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel_xtest];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingDel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel_xtest] @CustID    INT,
                                                           @ProductID TINYINT,
                                                           @UserID    INT         = 0,
                                                           @IP        VARCHAR(20) = ''
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
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT;
     DECLARE @MaxWinLimitOld1 MONEY, @MaxWinLimitOld2 MONEY, @MaxWinLimitOld3 MONEY;
     DECLARE @ErrCode INT= 0, @ErrMsg NVARCHAR(200)= '';
     SELECT @StartRun = GETDATE();
     BEGIN -- Save Old State
         SELECT @MaxWinLimitOld1 = MaxWinLimit
         FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND LevelID = 1;
         SELECT @MaxWinLimitOld2 = MaxWinLimit
         FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND LevelID = 2;
         SELECT @MaxWinLimitOld3 = MaxWinLimit
         FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND LevelID = 3;
     END;
     BEGIN -- Delete
         BEGIN TRY
             DELETE dbo.WinLimit_CustGameSetting
             WHERE CustID = @CustID
                   AND ProductID = @ProductID;
         END TRY
         BEGIN CATCH
             SELECT 2 AS ErrorCode,
                    'This setting cannot be deleted because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     BEGIN -- Log
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         DECLARE @LogSPData VARCHAR(300);
         SELECT @LogSPData = '<NAP_WinLimit_CustSettingDel '+'" CustID ="'+CONVERT( VARCHAR(20), @CustID)+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID)+'" OrangeMaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimitOld1)+'" YellowMaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimitOld2)+'" RedMaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimitOld3)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31206,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT @ErrCode AS ErrorCode,
            @ErrMsg AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingDel_xtest] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingDel_xtest] TO [vnteam];
GO