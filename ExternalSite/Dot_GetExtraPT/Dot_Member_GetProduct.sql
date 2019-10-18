/*<info serverAlias="DBPRO-bodb02" executers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Dot_Member_GetProduct]
	@Bettype	SMALLINT
	,@Sporttype	SMALLINT
	,@ProductId	TINYINT OUTPUT
	,@SubProduct VARCHAR(500) OUTPUT
AS
/*
	Created: 20191014@Sophia
	DB: DBPRO.bodb02
	Task: Get ProductID and SubProduct by Sporttype and bettype [Redmine: #122071]
*/

BEGIN 
	SET NOCOUNT ON
	
	SELECT 	DISTINCT @ProductId = ProductId, 
			@SubProduct = CASE	WHEN @Sporttype = 44 THEN 'Muay Thai'  
								WHEN SubProduct IN ('MG-SuperLive', 'Bet Builder') THEN SubProduct 
								ELSE ''								
						  END  
	FROM 	dbo.SportBettypeMatrix WITH (NOLOCK)
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
  