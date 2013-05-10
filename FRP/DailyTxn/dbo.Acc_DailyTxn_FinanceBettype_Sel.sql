ALTER PROCEDURE [dbo].[Acc_DailyTxn_FinanceBettype_Sel]  
AS  
/*
Created by: Kiet Mai
Date: Nov 24 2010
Task: daily finance transaction	
DB: DB06.BODB02 
	Revision:
		- 20101225@Lukas: Re-arrange bettype
		- 20120405@Hurri: Add bettype 23102 (P2P Pending) into condition
*/ 
BEGIN
	SET NOCOUNT ON 

	SELECT typeid, typenamee 
	FROM bettype WITH(NOLOCK)
	WHERE	typeid > 20000
			AND typeID NOT IN (23001,23002,23101,23102,23201,23202) ---(112,113,114,117,118) --Transfer to Casino/Bingo/P2P
END


GO
GRANT EXECUTE ON [dbo].[Acc_DailyTxn_FinanceBettype_Sel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_DailyTxn_FinanceBettype_Sel] TO [vnteam]
GO 