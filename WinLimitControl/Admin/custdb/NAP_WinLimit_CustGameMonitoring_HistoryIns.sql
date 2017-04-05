USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns] @CustId       INT,
                                                                          @ProductId    INT,
                                                                          @GroupId      INT,
                                                                          @ActionId     INT,
                                                                          @UserId       INT,
                                                                          @ErrorCode    INT           = 0 OUTPUT,
                                                                          @ErrorMessage NVARCHAR(500) = '' OUTPUT
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/CustDB

Revisions:
20170321@Jacob: Risk & Control - Phase 3A [#72604].  
Parameters Explanation:	
EXEC [NAP_WinLimit_CustGameMonitoring_HistoryIns] 
   @CustId = 662531, 
   @ProductId =22,
   @BetTypeId=4001,  
   @ActionId =2,
   @UserId=1
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
     SELECT @StartRun = GETDATE();
    BEGIN TRY
        INSERT INTO dbo.WinLimit_CustGameMonitoring_History
        (CustID,
         ProductID,
         GroupId,
         BettypeID,
         WinlostDate,
         LevelID,
         MaxWinLimit,
         MaxWinLimitSetting,
         TotalWinAmt,
         TotalWinAmt_RM,
         WinAmt,
         ActionID,
         ModifiedDate,
         IsNotified,
         ModifiedBy,
         CreatedBy
        )
               SELECT TOP 1 CustID,
                            ProductID,
                            GroupId,
                            0,
                            WinlostDate,
                            LevelID,
                            MaxWinLimit,
                            MaxWinLimitSetting,
                            TotalWinAmt,
                            TotalWinAmt_RM,
                            WinAmt,
                            @ActionId,
                            GETDATE(),
                            IsNotified,
                            @UserId,
                            @UserId
               FROM dbo.WinLimit_CustGameMonitoring WITH(NOLOCK)
               WHERE CustId = @CustId
                     AND ProductId = @ProductId
                     AND GroupId = @GroupId
               ORDER BY ModifiedDate DESC;
    END TRY
    BEGIN CATCH
        SELECT @ErrorCode = 1,
               @ErrorMessage = 'The monitoring history cannot be inserted because of an database internal error.';
        RETURN;
    END CATCH;
     SELECT @ErrorCode = 0,
            @ErrorMessage = '';
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns] TO [vnteam];
GO