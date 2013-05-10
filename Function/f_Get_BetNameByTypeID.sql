 ALTER FUNCTION [dbo].[f_Get_BetNameByTypeID]
(
	@typeid INT,
	@language VARCHAR(2) = 'E'
)
RETURNS NVARCHAR(500) AS  
/*
	Created: 20110727:TOM
	Task : Get Bet Name by TypeID
	DB: DBTrans.bodb02
	
	Revisions:
		- 20120723@Johnson: change column for Chinese Tranditional langue
		- 20130124@Elodie: Insert case @language = 'VI
*/
BEGIN 
DECLARE @typename NVARCHAR(500)

SELECT	@typename = CASE @Language	WHEN 'E'	THEN typenamee 
									WHEN 'CS'	THEN typenamecn
									WHEN 'CT'	THEN typenamec_uni
									WHEN 'TH'	THEN typenameth
									WHEN 'J'	THEN typenamej
									WHEN 'KO'	THEN typenameko
									WHEN 'ES'	THEN typenameES
									WHEN 'VI'	THEN typenameVN
									ELSE typenamee END 
										
FROM	bettype WITH (NOLOCK)
WHERE	typeid = @typeid
	
IF (@typename = '' or @typename IS NULL)
	SELECT	@typename = typenamee 
	FROM	bettype WITH (NOLOCK)
	WHERE	typeid = @typeid	
	
RETURN @typename
END

GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_BetNameByTypeID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_BetNameByTypeID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_BetNameByTypeID] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_BetNameByTypeID] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_BetNameByTypeID] TO [bodbDownlineNetView]