USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Acc_FinanceAccountByCustId]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Acc_FinanceAccountByCustId]
GO

CREATE PROCEDURE [dbo].[Acc_FinanceAccountByCustId]
     @Username varchar(30) = null
    ,@isInternal bit output
AS
 /*
	Created by: 20120912@Don
	Task: Get finance account by customer's ID
	DB: DB06.bodb02 
	
	Revisions:

    Param's Explanation:
        
 */

SET NOCOUNT ON

SET @isInternal = 0

DECLARE @_Username AS VARCHAR(30)
SET @_Username = @Username

DECLARE @CustID int
SELECT @CustID = custid FROM dbo.Customer (NOLOCK) WHERE username LIKE @_Username

IF EXISTS( 
        SELECT * 
        FROM dbo.Customer c (NOLOCK) 
            INNER JOIN dbo.custAgent a (NOLOCK) ON c.recommend = a.custid AND c.roleid = 1
        WHERE a.isInternal = 1 AND c.custid = @CustID )
BEGIN
    SET @isInternal = 1
    RETURN;
END

IF EXISTS( SELECT * FROM dbo.custAgent a (NOLOCK) WHERE a.isInternal = 1 AND a.custid = @CustID )
BEGIN
    SET @isInternal = 1
    RETURN;
END
    
IF EXISTS( SELECT * FROM dbo.CustMaster m (NOLOCK) WHERE m.isInternal = 1 AND m.custid = @CustID )
BEGIN
    SET @isInternal = 1
    RETURN;
END
    
IF EXISTS( SELECT * FROM dbo.CustSuper s (NOLOCK) WHERE s.isInternal = 1 AND s.custid = @CustID )
BEGIN
    SET @isInternal = 1
    RETURN;
END



GO
GRANT EXECUTE ON [dbo].[Acc_FinanceAccountByCustId] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_FinanceAccountByCustId] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_FinanceAccountByCustId] TO [vnteam]