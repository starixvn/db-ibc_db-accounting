


ALTER PROCEDURE Acc_Set_ParlayWaitingSel
AS
/*
	Created: 20130611@Lukas
	Task: get parlay settlement status for a match
	DB: DBTXN/BODB02
	
	Revision:
	
*/
BEGIN
	SELECT matchid, isCalculating AS CalcMP
	FROM Parlay_WaitingList WITH(NOLOCK)
	
END
GO
GRANT EXECUTE ON Acc_Set_ParlayWaitingSel TO bodbadminNet
GO
GRANT view DEFINITION ON Acc_Set_ParlayWaitingSel TO vnteam
