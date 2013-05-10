ALTER PROCEDURE [dbo].[Acc_NewsDel]
	@NewsID	int,		
	@AppID	smallint,		
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output

AS
/*
Created: 20110215@Bobby
Task : Delete News item in Accounting site
DB: DB06.bodb_Maintenance
Original:

Param's Explanation:	
*/
SET NOCOUNT ON

UPDATE dbo.Acc_News WITH (ROWLOCK, UPDLOCK)
SET Feature=-1
WHERE NewsID = @NewsID AND AppID = @AppID

IF @@Error <> 0
BEGIN			
	SELECT @ErrMsg = 'Error! Error when deleting News ;', @ErrCode = 10103			
	RETURN
END

GO
GRANT EXECUTE ON [dbo].[Acc_NewsDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsDel] TO [VNTeam]
GO
