/*<info serverAlias="DBPRO-bodb02" executers="Dot_Member,Dot_Intg" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_GetProduct_CN88]
	@Bettype	SMALLINT
	,@Sporttype	SMALLINT
	,@ProductId	TINYINT OUTPUT
	,@SubProduct VARCHAR(500) OUTPUT
AS
/*
	Created: 20191014@Sophia
	DB: DBPRO.bodb02
	Task: Get ProductID and SubProduct by Sporttype and bettype  
	
	Revisions:
		- 20191014@Sophia: initial SP [Redmine: #122071]
*/

BEGIN 
	SET NOCOUNT ON
	
	SELECT 	TOP 1 @ProductId = ProductId, 
			@SubProduct = CASE	WHEN @Sporttype = 44 THEN 'Muay Thai'  
								WHEN SubProduct IN ('MG-SuperLive', 'Bet Builder') THEN SubProduct 
								ELSE ''								
						  END  
	FROM 	dbo.CS_SportBettypeMatrix WITH (NOLOCK)
	WHERE   Sporttype = @Sporttype
			AND Bettype = @Bettype

	IF @ProductId IS NULL 
	BEGIN 
		SELECT @ProductId = 0
	END

	IF @SubProduct IS NULL 
	BEGIN 
		SELECT @SubProduct = ''
	END
	
END
GO
  