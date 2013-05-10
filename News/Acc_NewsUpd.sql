ALTER PROCEDURE [dbo].[Acc_NewsUpd]
	@NewsID	int,	
	@Title nvarchar(200),
	@NewsContent nvarchar(4000),
	@Date smalldatetime,	
	@Func nvarchar(100),	
	@AppID smallint,	
	@Feature smallint,
	@Thumbnail nvarchar(200),
	@OwnerID int =0,	
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output

AS
/*
Created: 20110215@Bobby
Task : Update News item on Accounting site
DB: DB06.bodb_Maintenance
Original:
	
Param's Explanation:	
	@Feature: 0 - normal, 1 - is feature, -1 - deleted	
*/
SET NOCOUNT ON
IF @Feature=1
BEGIN
	EXEC dbo.Acc_NewsResetFeature @AppID, @ErrCode OUTPUT
	IF @ErrCode<>0
	BEGIN
		SELECT @ErrMsg = 'Error! Error when reset feature News ;', @ErrCode = 10102			
		RETURN
	END
END
IF @ErrCode=0
BEGIN
	UPDATE dbo.Acc_News WITH (ROWLOCK, UPDLOCK)
	SET
		  Title=@Title,
		  NewsContent = @NewsContent ,
		  Date = @Date,     
		  Func = @Func,
		  Feature = @Feature,
		  Thumbnail = @Thumbnail,
		  OwnerID = @OwnerID
	WHERE NewsID = @NewsID AND AppID = @AppID

	IF @@Error <> 0
	BEGIN			
		SELECT @ErrMsg = 'Error! Error when updating News ;', @ErrCode = 10102			
		RETURN
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_NewsUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsUpd] TO [VNTeam]
GO
