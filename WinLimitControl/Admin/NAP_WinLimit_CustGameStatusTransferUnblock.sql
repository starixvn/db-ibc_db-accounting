USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustGameStatusTransferUnblock]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] @CustId    INT,
                                                                    @ProductId INT,
                                                                    @BetTypeId INT,
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

    EXEC [NAP_WinLimit_CustGameStatusTransferUnblock]
    @CustId = 662531,
    @ProductId = 22,
    @BetTypeId = 4001,
    @UserId = 1,
    @IP = '127.0.0.1';
	
*/


     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300), @IsBlockedTransferOld BIT;
     SELECT @StartRun = GETDATE();
     BEGIN -- UPDATE
         BEGIN TRY
             UPDATE dbo.WinLimit_CustGameStatus
               SET
                   IsBlockedTransfer = 0,
                   ActionId = 4,
                   ModifiedDate = GETDATE()
             WHERE CustId = @CustId
                   AND ProductId = @ProductId
                   AND BetTypeId = @BetTypeId;
         END TRY
         BEGIN CATCH
             SELECT 1 AS ErrorCode,
                    'The setting of Transfer/Withdraw cannot be changed because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     BEGIN --LOG
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SET @LogSPData = '<NAP_WinLimit_CustGameStatusTransferUnblock ';
         SET @LogSPData = @LogSPData+'"CustId ="'+CONVERT(VARCHAR(20), @CustId);
         SET @LogSPData = @LogSPData+'" ProductId ="'+CONVERT(VARCHAR(20), @ProductId);
         SET @LogSPData = @LogSPData+'" BetTypeId ="'+CONVERT(VARCHAR(20), @BetTypeId);
         SET @LogSPData = @LogSPData+'" UserID ="'+CONVERT(VARCHAR(20), @UserID);
         SET @LogSPData = @LogSPData+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31207,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT 0 AS ErrorCode,
            '' AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] TO [vnteam];
GO