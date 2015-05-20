ALTER PROCEDURE [dbo].[Task_VerifyBettype]
AS
/*
	Created by: Jamie@20110524
	Task: Checking bet type out of ranges
	DB: DB052.BODB02

*/
BEGIN

	IF EXISTS (SELECT TOP 1 1 FROM Bettrans WITH (NOLOCK) WHERE bettype BETWEEN 99 AND 118 AND matchID = 0)
	BEGIN
		RAISERROR ('FAILED: Existing bettype between 99 and 118', 16, 1)
		RETURN
	END

END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_VerifyBettype] TO [vnteam] 