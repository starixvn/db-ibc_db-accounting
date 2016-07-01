USE [bodb02];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_Winlimit_DepositGameReset]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_Winlimit_DepositGameReset];
GO
USE [bodb02];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_Winlimit_DepositGameReset] @CustId    INT,
                                                     @BetTypeId INT
AS
	
/*
	Created: Jacob	
	Date: 2016-06-30
	Task: #38608 - Implement function to control Player's Win Limit on specific Product
	
	DB: DBCust/bodb02
	
	Revisions:
	
	Parameters Explanation:	
	EXEC [NAP_Winlimit_DepositGameReset] 
	   @CustId = 662531, 
	   @BetTypeId=4001
	
*/

     SET NOCOUNT ON;
     BEGIN -- ATE
         BEGIN TRY
             UPDATE cg
               SET
                   cg.WinLost = 0
             FROM dbo.WinLimit_DepositGame cg WITH (ROWLOCK, UPDLOCK)
             WHERE cg.CustId = @CustId
                   AND cg.BetType = @BetTypeId;
         END TRY
         BEGIN CATCH
             SELECT 1 AS ErrorCode,
                    'The deposit win limit cannot be reseted because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     SELECT 0 AS ErrorCode,
            '' AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_Winlimit_DepositGameReset] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Winlimit_DepositGameReset] TO [vnteam];
GO