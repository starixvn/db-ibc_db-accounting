CREATE FUNCTION [dbo].[f_GetDummySuper]()
	
	RETURNS @tbDummySuper table (custId  int PRIMARY KEY)
AS

/*
Created: 
Task : Get Dummy Super
DB: DB02, DB05/2, DB06

Revisions:
	- 20100720@Shifu: Get dummy super
Param's Explanation:
	
*/


BEGIN

	Insert Into @tbDummySuper(custId)
	
	SELECT custid
	FROM customer WITH(NOLOCK)
	WHERE 
		roleid = 4
		AND
		(
		username LIKE '3rdSuper%'  
		OR username LIKE '12BETACCSuper%'
		OR username LIKE 'MS88ACCSuper%'
		OR username LIKE 'AB88ACCSuper%'
		OR username LIKE 'ALogACCSuper%'
		OR username LIKE 'STEST%' 
		)
		
		
	
	Return
END


GO
GRANT VIEW DEFINITION ON [dbo].[f_GetDummySuper] TO [vnteam]
GO
GRANT SELECT ON [dbo].[f_GetDummySuper] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[f_GetDummySuper] TO [bodbExtAccNet]