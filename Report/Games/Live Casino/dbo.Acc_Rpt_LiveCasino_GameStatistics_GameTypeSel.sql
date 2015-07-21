ALTER PROCEDURE [dbo].[Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel]
	@ProductID TINYINT = 0  
AS
SET NOCOUNT ON
/*
	Created by: Daniel
	Date: 2012-02-17
	Task : Retrieve Live Casino Bettypes and Gold Deluxe
	DB: DBACC/bodb02
	Original:

	Revisions:
		- 20150601@Sophia: Apply Gold Deluxe
	
	Parameters Explanation:
		- @ProductID = 0 : All
					 = 4 : Live Casino
					 = 12: Gold Deluxe

*/
SET NOCOUNT ON

	----Get Sport Bettype Matrix------
	DECLARE @SportBettype TABLE(ProductID INT, Bettype INT,EventType INT)
	INSERT INTO @SportBettype
	EXEC bodb02.dbo.Acc_SportBettypeMatrix_Sel @mode = 4 

	DELETE @SportBettype 
	WHERE ProductID NOT IN (4,12)


	SELECT	b.typeID, b.typenamee 
	FROM	bettype b WITH (NOLOCK) 
		INNER JOIN @SportBettype s 
			ON s.Bettype = b.typeid
	WHERE	s.ProductId = @ProductID OR @ProductID = 0
	ORDER BY b.typeID ASC

 

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_LiveCasino_GameStatistics_GameTypeSel] TO [vnteam]