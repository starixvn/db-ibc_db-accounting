ALTER FUNCTION [dbo].[f_GetBetDaqCustomer]
(
	@RoleID int = 1
)
	
	RETURNS @returntable table (CustID int, Username varchar(30))
AS

/*
Created: Henry
Date: 2010-10-01
Task :	Get BetDaq CustID by passing RoleID
		** Note: Not using this function for Settlement 
DB: DB02.BODB02, DB052.BODB02, DB06.BODB02

Revisions:

*/

BEGIN
	IF @RoleID = 1
	BEGIN
		INSERT @returntable (CustID, Username)
		SELECT 50057, 'BQUS888'
		UNION ALL SELECT 103873, 'BQUSNBA'
		UNION ALL SELECT 879241, 'BQUSMLB'
		UNION ALL SELECT 1077687, 'BFOS'
		UNION ALL SELECT 78761, 'ITibc101' --for testing
	END
	ELSE IF @RoleID = 2
	BEGIN
		INSERT @returntable (CustID, Username)
		SELECT 1688156, 'MTEST0101'
	END
	RETURN
END
GO
GRANT VIEW DEFINITION ON [dbo].[f_GetBetDaqCustomer] TO [vnteam]
GO
GRANT SELECT ON [dbo].[f_GetBetDaqCustomer] TO [bodbAdminNet]
