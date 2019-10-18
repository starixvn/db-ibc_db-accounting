/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Dot_Member_GetExtraPT]
	@Srecommend			INT
	,@ProductId			TINYINT
	,@SubProduct		VARCHAR(500)
	,@epositiontaking	SMALLMONEY OUTPUT
AS
/*
	Created: 20191014@Sophia
	DB: DBCUST.CustDB
	Task: Get ExtraPT(epositiontaking) by ProductID and SubProduct [Redmine: #122071]
*/


BEGIN 
	SET NOCOUNT ON

	DECLARE @Sporttype SMALLINT = 0, 
			@Date DATETIME = CONVERT(DATE,CURRENT_TIMESTAMP)

	IF @SubProduct = 'Muay Thai' 
	BEGIN 
		SELECT @Sporttype = 44, @SubProduct = ''
	END 	
	 	
	SELECT  @epositiontaking = SUM(ISNULL(ExtraPT,0)) ---- (because of BC group)
	FROM	dbo.Acc_GroupExtraPTSetting WITH (NOLOCK)
	WHERE	ProductId = @ProductId
			AND Sporttype = @Sporttype 
			AND SubProduct = @SubProduct
			AND SuperID = @Srecommend
			AND @Date BETWEEN FromDate AND ToDate

	IF @epositiontaking IS NULL 
	BEGIN 	
		SELECT @epositiontaking = 0
    END
 
END
GO
 

