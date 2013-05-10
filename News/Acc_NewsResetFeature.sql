ALTER PROCEDURE [dbo].[Acc_NewsResetFeature] 
	@AppID smallint,
	@ErrCode int = 0 Output
AS

SET NOCOUNT ON;
/*
Created: 20110215@Bobby
Task : Reset News feature item on Accounting site
DB: DB06.bodb_Maintenance
Original:
	
Param's Explanation:	
*/
UPDATE dbo.Acc_News WITH(ROWLOCK, UPDLOCK)
SET 
	Feature = 0
WHERE AppID = @AppID AND Feature=1
IF @@Error <> 0
BEGIN			
	SELECT @ErrCode = 10102			
	RETURN
END

GO
GRANT EXECUTE ON [dbo].[Acc_NewsResetFeature] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsResetFeature] TO [VNTeam]
GO