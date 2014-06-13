CREATE PROCEDURE [dbo].[Acc_Rpt_EnableDisableAccount_ByProduct]
	@ListCurrency	NVARCHAR(150)	= 'all', 
	@SportType		INT
AS  
/*  Created: Dominic 
	Date: 2014-06-02  
    Task : Total Credit Accounts Enabled/Disabled per Product
    DB: DBAGE/bodb02  
   
    Revisions:  
		
	Param's Explanation:  
	  + @ListCurrency: The specified date used as one of the filter criterias, if its value is 'all' then no need to be filtered by currency
	  + {251:Casino, 151:Racing,252:Bingo,161:Number Game,162:Live Casino,180:Virtual Sports,202:Keno}

  
*/  
BEGIN
	SET NOCOUNT ON

	
	--Table of real creadit super filter by currency
	CREATE TABLE #FiltedCreditSuper(
			CustID INT,
			SuperStatus BIT
			)
	DECLARE @DepositDummySuper TABLE  (
		CustID INT
		)
	DECLARE @DummyAcc TABLE  (
		CustID INT
		)
			
	--Table of Super/master/Member that belong to real super above	
	CREATE TABLE #FiltedDownlineAcc(
		SuperID		INT,
		CustID		INT,
		RoleID		INT,
		IsDisable	BIT
		)	
	
	
	INSERT INTO @DepositDummySuper
	SELECT custid FROM dbo.Dep_CustSuper
	UNION
	SELECT custid FROM dbo.Acc_CustDirect WHERE roleid = 4
	
	INSERT INTO @DummyAcc
	SELECT custid FROM dbo.Acc_CustDirect WHERE roleid IN (1,2,3)
	--Get real credit super filterd by currencies	
	INSERT INTO #FiltedCreditSuper(CustID,SuperStatus)
	SELECT ci.custid,
		CASE
			WHEN @sportType = 151 THEN (ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
			WHEN @sportType = 161 THEN ci.DisableNumber
			WHEN @sportType = 202 THEN CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
			WHEN @sportType = 162 THEN (~ci.SyncLiveCasino | ci.DisableLiveCasino)
			WHEN @sportType = 180 THEN ci.DisableVirtualSports
			WHEN @sportType = 251 THEN (~ci.SyncCasino |(ci.DisableCasino))
			WHEN @sportType = 252 THEN (~ci.SyncBingo | ci.DisableBingo)
		END
	FROM dbo.custInfo ci WITH(NOLOCK)
	JOIN dbo.CustSuper cs WITH(NOLOCK) ON ci.custid = cs.custid AND cs.IsInternal = 0
	WHERE ci.roleid=4 AND ci.Enabled = 1 AND ci.custid NOT IN ( SELECT custid
																FROM dep_custsuper WITH(NOLOCK))
		AND (@ListCurrency= 'all' OR ci.currency IN(SELECT val
                            FROM   dbo.strSplit (@ListCurrency, ','))) AND ci.currency NOT IN (20,27,28)
        AND ci.custid NOT IN (SELECT * FROM @DepositDummySuper)
	    
	--Get data for downline list 
    IF @sportType = 151
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3
		WHERE ci.Enabled = 1 
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc) 
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(ci.Disable151_AU & ci.Disable152_AU & ci.Disable152_UK & ci.Disable153_AU & ci.DisableHorseRacing & ci.DisableOpenTote)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1 
		WHERE ci.Enabled = 1                  
	END
	IF @sportType = 161
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableNumber
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3  
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableNumber
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableNumber
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.Enabled = 1                  
	END
	IF @sportType = 162
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3 
		WHERE ci.Enabled = 1   
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc) 
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncLiveCasino | ci.DisableLiveCasino)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1 
		WHERE ci.Enabled = 1            
	END
	IF @sportType = 180
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableVirtualSports
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableVirtualSports
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2  
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			ci.DisableVirtualSports
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.Enabled = 1             
	END
	IF @sportType = 251
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncCasino |(ci.DisableCasino))
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)   
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncCasino |(ci.DisableCasino))
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2  
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc) 
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncCasino |(ci.DisableCasino))
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1  
		WHERE ci.Enabled = 1       
	END
	IF @sportType = 252
    BEGIN            
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncBingo | ci.DisableBingo)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3 
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncBingo | ci.DisableBingo)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2
		WHERE ci.Enabled = 1
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			(~ci.SyncBingo | ci.DisableBingo)
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1 
		WHERE ci.Enabled = 1               
	END
	IF @sportType = 202
    BEGIN      
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustMaster cm WITH(NOLOCK) ON ci.custid = cm.custid AND cm.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 3
		WHERE ci.Enabled = 1 
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN dbo.CustAgent ca WITH(NOLOCK) ON ci.custid = ca.custid AND ca.IsInternal = 0
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 2
		WHERE ci.Enabled = 1 
		AND ci.custid NOT IN (SELECT * FROM @DummyAcc)
		
		INSERT INTO #FiltedDownlineAcc
		SELECT sup.CustID,
			ci.custid,
			ci.roleid,
			CASE WHEN EXISTS(SELECT TOP 1 1 FROM dbo.CustGameType gt WITH(NOLOCK,INDEX=PK_CustGameType)
																WHERE gt.CustID = ci.CustID AND gt.IsDisabled = 0 ) 
																THEN 0 
																ELSE 1 
																END
		FROM dbo.custInfo ci WITH(NOLOCK)
		JOIN #FiltedCreditSuper sup ON ci.srecommend = sup.CustID AND ci.roleid = 1
		WHERE ci.Enabled = 1              
	END
		

	--Return result
	SELECT cust.custid,cust.username,sp.SuperStatus as IsDisable,e.currency,
			ISNULL(rs.MasterEnabled,0)	MasterEnabled,
			ISNULL(rs.MasterDisabled,0) MasterDisabled,
			ISNULL(rs.AgentEnabled,0)	AgentEnabled,
			ISNULL(rs.AgentDisabled,0)	AgentDisabled,
			ISNULL(rs.MemberEnabled,0)	MemberEnabled,
			ISNULL(rs.MemberDisabled,0)	MemberDisabled
	FROM #FiltedCreditSuper sp
	JOIN dbo.Customer cust WITH(NOLOCK) ON cust.custid = sp.CustID 
	JOIN dbo.Exchange e WITH(NOLOCK) ON e.exchangeid = cust.currency
	LEFT JOIN
	(SELECT dl.SuperID,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 3 THEN 1 ELSE 0 END) MasterEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 3 THEN 1 ELSE 0 END) MasterDisabled,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 2 THEN 1 ELSE 0 END) AgentEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 2 THEN 1 ELSE 0 END) AgentDisabled,
		SUM(CASE WHEN dl.IsDisable = 0 AND dl.RoleID = 1 THEN 1 ELSE 0 END) MemberEnabled,
		SUM(CASE WHEN dl.IsDisable = 1 AND dl.RoleID = 1 THEN 1 ELSE 0 END) MemberDisabled
	FROM #FiltedDownlineAcc dl 
	GROUP BY dl.SuperID) rs ON sp.CustID = rs.SuperID
	ORDER BY cust.username,e.currency

	
	--Drop temp tables
	DROP TABLE #FiltedCreditSuper
	DROP TABLE #FiltedDownlineAcc
END
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_EnableDisableAccount_ByProduct] TO [bodbAdminNet]
