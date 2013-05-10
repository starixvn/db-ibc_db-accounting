ALTER PROCEDURE [dbo].[Acc_GetNumberGameResults]
	@matchid int
AS
/*
	Created by:[Viet]
	Date:[20111219]
	Task: get result of a numbergame match
	DB: DB052.bodb02
	
	Revisions:
		
*/
BEGIN
	SELECT matchid, seq, number
	FROM Bingoball WITH(NOLOCK)
	WHERE matchid = @matchid
END

GO
GRANT EXECUTE ON [dbo].[Acc_GetNumberGameResults] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_GetNumberGameResults] TO [vnteam]