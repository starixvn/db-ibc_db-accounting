ALTER PROCEDURE [dbo].[Acc_NewsIns]	
	@Title nvarchar(200),
	@NewsContent nvarchar(4000),	
	@Date	smalldatetime,	
	@Func nvarchar(100),
	@AppID smallint,
	@Feature smallint,
	@Thumbnail nvarchar(200),
	@OwnerID int =0,
	@NewsID int =0 output,
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(200) = '' Output
	
AS
/*
Created: 20110215@Bobby
Task : Insert News item to table Acc_News on Accounting site
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
	INSERT INTO dbo.Acc_News ([NewsContent],[Date],[Title], [Func], [AppID], [Feature], [Thumbnail], [OwnerID])
	VALUES (@NewsContent,@Date,@Title,@Func, @AppID, @Feature, @Thumbnail, @OwnerID)

	IF @@Error <> 0
	BEGIN			
		SELECT @ErrMsg = 'Error! Error when Inserting News ;', @ErrCode = 10101			
		RETURN
	END
	SELECT @NewsID = @@IDENTITY
END

GO
GRANT EXECUTE ON [dbo].[Acc_NewsIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_NewsIns] TO [VNTeam]
GO

