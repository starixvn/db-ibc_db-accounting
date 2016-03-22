USE [bodb02]
GO
 
ALTER PROCEDURE [dbo].[Acc_Rpt_WinlostCF_Details14]
	@WinlostDate	DATETIME,
	@Arena		    VARCHAR(240)
AS 
/*	
	Creator:20160229@Jim
	Task: Report 2a for Cock Fighting
	DB:  DBACC/bodb02
	Original: 
	
	Revisions :
			 
	Explanation's Param:

*/
	SET NOCOUNT ON
	
	DECLARE @ArenaID INT
	SELECT @ArenaID = leagueid
	FROM dbo.League WITH (NOLOCK)
	WHERE leaguename=@Arena
	
	DECLARE @tblBettype AS TABLE (bettypeID INT)
	INSERT INTO @tblBettype (bettypeID )
	SELECT bettype
	FROM dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductID=19
	
	;WITH cte_Fight
	AS
		(
		SELECT  EventInfo3rdId
				,ArenaID
				,FightNo
				,EventDate
				,CONVERT (VARCHAR(512),HomeOwner) +'-vs-'+CONVERT(VARCHAR(512),AwayOwner) AS [Match]
				,AwayOwner
		FROM dbo.EventInfo3rd WITH (NOLOCK)	
		WHERE ArenaID = @ArenaID		
		)
	SELECT 
		 c.FightNo
		 ,c.[Match] 
		 ,ISNULL(SUM ((winlost - actual_stake) * b.actualrate), 0) winlost
		 ,ISNULL(SUM ((awinlost + mwinlost + swinlost) * b.actualrate), 0) pos
		 ,ISNULL(SUM (scomm * b.actualrate), 0) comm
		 ,ISNULL(SUM (scomm*virtualrate), 0) VirtualComm
		 ,ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*actualrate),0)as LineTotal
		 ,ISNULL(sum((winlost-actual_stake + awinlost+mwinlost+swinlost + scomm)*virtualrate),0) as VirtualLineTotal
		 ,ISNULL(sum((1-tpositiontaking)*abs(stake)*actualrate),0) as IBCTurnover
	FROM dbo.bettrans14 b WITH (NOLOCK)
		INNER JOIN cte_Fight c ON b.betcheck = c.ArenaID
		INNER JOIN @tblBettype bet ON b.bettype = bet.bettypeID
	WHERE b.Winlostdate = @WinlostDate
		  AND b.ruben = 1
		  AND b.statusID NOT IN (101, 102, 121)
	GROUP BY  c.FightNo
			 ,c.[Match] 	  
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlostCF_Details14] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_WinlostCF_Details14] TO [VNTeam]
GO		 