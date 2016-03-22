USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_WinlostCF_xtest]    Script Date: 03/22/2016 13:46:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostCF]
	@WinlostDate	DATETIME 
AS 
/*	
	Creator:20160229@Jim
	Task: Report 2a for CockFighting
	DB:  DBACC/bodb02
	Original: 
	
	Revisions :
			 
	Explanation's Param:

*/
	SET NOCOUNT ON
 
	
	DECLARE @tblBettype AS TABLE (bettypeID INT)
	INSERT INTO @tblBettype (bettypeID )
	SELECT bettype
	FROM dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductID=19
	
	SELECT 
		e.ArenaID
		,l.leaguename  
		,ISNULL(SUM ((winlost - actual_stake) * b.actualrate), 0) winlost  
	   ,ISNULL(SUM ((awinlost + mwinlost + swinlost) * b.actualrate), 0) pos  
	   ,ISNULL(SUM (scomm * b.actualrate), 0) comm  
	   ,ISNULL(SUM (scomm*virtualrate), 0) VirtualComm  
	   ,ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*actualrate),0)as LineTotal  
	   ,ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*virtualrate),0) as VirtualLineTotal  
	   ,ISNULL(sum((1-tpositiontaking)*abs(stake)*actualrate),0) as IBCTurnover  
 FROM dbo.bettrans b WITH (NOLOCK)  
	  INNER JOIN dbo.EventInfo3rd e WITH (NOLOCK) ON e.ArenaID = b.betcheck
	  INNER JOIN dbo.league l WITH (NOLOCK) ON e.ArenaID = l.leagueid  
	  INNER JOIN  @tblBettype bet ON b.bettype = bet.bettypeID  
 WHERE    
    b.Winlostdate = @WinlostDate  
    AND b.ruben = 1  
    AND b.statusID NOT IN (101, 102, 121)  
 GROUP BY e.ArenaID,l.leaguename  
 ORDER BY l.leaguename  

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostCF] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinlostCF] TO [VNTeam]
GO