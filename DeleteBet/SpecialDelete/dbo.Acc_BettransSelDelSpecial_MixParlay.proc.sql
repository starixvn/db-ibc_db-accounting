 ALTER PROC [dbo].[Acc_BettransSelDelSpecial_MixParlay]
	@MatchID int,
	@bettype smallint = 0,
	@Type smallint = 0, 
	@livehomescore smallint = NULL,
	@liveawayscore smallint = NULL, 
	@FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@hdp smallmoney = 9999,   
	@bettypes varchar(128) = '',   
	@betteam1378 varchar(10) = 'ALL',  
	@betteam515 varchar(10) = 'ALL',  
	@betteam430 varchar(120) = '',  
	@betteam6 varchar(120) = '',  
	@betteam14 varchar(120) = '',  
	@betteam16 varchar(120) = '',  
	@Language NVARCHAR(2) = 'E'  
AS  
/*  
	Created by:   
	Date:   
	Task: Get transaction of mix parlay bet in bettrans  
	DB: DB053.BODB02  
	Original:   
   
	Revisions:   
		- 20091205: Henry get one more column: refno, get username in bettrans (instead of from customer)  
		- 20091208@Jamie: Edit MixParlay future, get currency from bettrans instead of exchange  
		- 20100526@Henry: Change to use StatusID instead of Status in WHERE statement  
		- 20100611@Henry: Change mix-parlay match from 0 to 9  
		- 20110824@Elly: apply new rule to delete parlay ticket  
		- 20110831@Elly: correct transid and return SubTransID more  
		- 20110906@Elly: include waiting status (=1)    
		- 20110912@Elly: add Group column for each database =>support web layer do paging  
		- 20110922@Tom: Add new bettypes 30, apply new bet type 1st correct score on Sport Books
					 Replace parameter input @betteam4 => @betteam430  
		- 20111006@Sophia: . Add new parametter @Type, @livehomescore, @liveawayscore to filter by livehomescore and liveawayscore
						 . Rename Group= from 'MHCEU' to 'MHC'
		- 20111115@Sophia: Add new parametter @transdate to filter by Live score
		- 20111223@Lukas: Add new param @bettype
		- 20120309@Sophia: Change param @transdate to @FromTransdate and @ToTransdate
		- 20120629@Sophia: Remove function f_GetOddsByBettype, f_ShowOddsByBettype, f_GetChoice for odds, Oddstype, betteam
		- 20120709@Dan: improve performance when getting data for system parlay and mixparlay at the same time (@bettype=0)
		- 20120711@Sophia: Add condition 'L' in betfrom to check Deposit
		- 20131210@Kathy: Using Dep_CustSuper table to find deposit ticket instead of betfrom in ('D', 'M', 'E', 'L') [Redmine:#9321]

	Param's Explanation:
			@Type
				0	Dead
				1	Live
				2	All
			@bettype:
				0	All
				9	MixParlay
				29	System parlay

*/  
BEGIN   
	SET NOCOUNT ON  

	CREATE TABLE #ParlayDelete (transid bigint  
        ,SubTransID bigint  
        ,refno bigint  
        ,username varchar(30)  
        ,custid int  
        ,transdate datetime  
        ,creator varchar(30)  
        ,stake money  
        ,winlost money  
        ,odds smallmoney  
        ,OddsType tinyint  
		,bettype smallint
        ,status nvarchar(10)  
        ,spositiontaking smallmoney  
        ,mpositiontaking smallmoney  
        ,apositiontaking smallmoney  
        ,currency tinyint  
        ,mrecommend int          
        ,IsDeposit bit  
        ,choice_Bettype int  
        ,choice_HomeID int  
        ,choice_AwayID int   
        ,choice_hdp1 smallmoney   
        ,choice_hdp2 smallmoney  
        ,choice_Odds smallmoney   
        ,choice_Betteam nvarchar(20)  
        ,choice_Livehomescore smallint  
        ,choice_Liveawayscore smallint  
        ,choice_Liveindicator bit  
        ,choice_LeagueID int  
        ,choice_Sporttype smallint  
        ,choice_isNeutral bit  
        ,choice_matchid int  
        ,choice_matchcode nvarchar(50)  
       )           
	CREATE TABLE #Ref (--id int identity(1,1) primary key clustered   
      refno bigint   
      ,transid bigint        
      ,Bettype int  
      ,hdp1 smallmoney  
      ,hdp2 smallmoney  
      ,odds smallmoney  
      ,betteam nvarchar(20)  
      ,livehomescore smallint  
      ,liveawayscore smallint  
      ,liveindicator bit        
      ,org_betteam nvarchar(10)       
      ,statusID int  
     )  
   
	INSERT INTO #Ref (  
     refno  
     ,transid  
     ,Bettype        
     ,hdp1  
     ,hdp2  
     ,odds  
     ,betteam  
     ,livehomescore  
     ,liveawayscore  
     ,liveindicator  
     ,org_betteam       
     ,statusID  
    )  
 SELECT refno  
  ,transid  
  ,Bettype     
  ,hdp1  
  ,hdp2  
  ,odds  
  ,betteam  
  ,livehomescore  
  ,liveawayscore  
  ,liveindicator  
  ,betteam    
  ,statusID  
 FROM dbo.bettransm AS b WITH(NOLOCK)    
 WHERE	matchid=@MatchID    
		AND CASE WHEN @Type = 2 THEN @Type ELSE b.liveindicator END = @Type
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @Type = 1 THEN @livehomescore ELSE livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @Type = 1 THEN @liveawayscore ELSE liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @Type = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @Type = 1 THEN @ToTransdate ELSE b.transdate END 
 
   
 CREATE CLUSTERED INDEX cl_Ref_refno ON #Ref(refno)  
 CREATE NONCLUSTERED INDEX nl_Ref_StatusID ON #Ref(StatusID)  
 CREATE NONCLUSTERED INDEX nl_Ref_bettype_betteam ON #Ref(bettype,org_betteam)  
   
 --REMOVE REDUNDANT item  
 DELETE #Ref  
 WHERE statusID NOT IN (0,1,103)  
   
 DELETE r  
 FROM #Ref AS r   
  LEFT JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
 WHERE bt.val IS NULL -- remove unselected bettypes  
    
 IF @betteam1378<>'All'  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype IN (1,3,7,8,2,12) AND (r.org_betteam<>@betteam1378)  
   
 IF @betteam515<>'All'  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype in (5,15) AND (r.org_betteam<>@betteam515)  
   
 IF @hdp <> 9999  
  DELETE r  
  FROM #Ref AS r   
   INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype  
  WHERE r.bettype IN (1,3,7,8) AND (hdp1<>@hdp-hdp2)  
     
    
 IF @betteam430=''   
  DELETE #Ref  
  WHERE bettype IN (4,30) 
 ELSE IF @betteam430<> 'All'  
  DELETE r  
  FROM #Ref AS r  
   LEFT JOIN dbo.strSplit(@betteam430,'^') AS b4 ON b4.val=r.org_betteam    
  WHERE (r.bettype IN (4,30) AND (b4.val IS NULL))     
   
 IF @betteam6=''  
  DELETE #Ref  
  WHERE bettype=6  
 ELSE IF @betteam6<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam6,'^') AS b6 ON b6.val=r.org_betteam    
  WHERE r.bettype=6 AND (b6.val IS NULL)  
   
 IF @betteam14=''  
  DELETE #Ref  
  WHERE bettype=14  
 ELSE IF @betteam14<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam14,'^') AS b14 ON b14.val=r.org_betteam    
  WHERE r.bettype=14 AND (b14.val IS NULL)  
   
 IF @betteam16=''  
  DELETE #Ref  
  WHERE bettype=16  
 ELSE IF @betteam16<>'All'   
  DELETE r  
  FROM #Ref AS r    
   LEFT JOIN dbo.strSplit(@betteam16,'^') AS b16 ON b16.val=r.org_betteam    
  WHERE r.bettype=16 AND (b16.val IS NULL)  
     
 INSERT INTO #ParlayDelete  
 SELECT   
   b.transid,  
   r.transid AS SubTransID,  
   r.refno,  
   b.username,  
   b.custid,  
   b.transdate,     
   cr.username as creator,   
   b.stake as StakePositiontaking,  
   b.winlost-b.actual_stake AS winlost,  
   b.odds,     
   b.OddsType,
   b.bettype,   
   b.status,  
   b.spositiontaking,  
   b.mpositiontaking,  
   b.apositiontaking,      
   b.currency,     
   b.mrecommend,   
   CASE WHEN b.srecommend in (SELECT custid FROM Dep_CustSuper with(NOLOCK)) THEN 1 ELSE 0 END as IsDeposit 
   --case when betfrom IN ('D', 'M', 'E', 'L') then 1 else 0 end as IsDeposit  
   ,r.bettype AS choice_bettype  
   ,m.homeid  
   ,m.awayid  
   ,r.hdp1 AS choice_hdp1  
   ,r.hdp2 AS choice_hdp2  
   ,r.odds AS choice_odds  
   ,r.betteam  
   ,r.livehomescore  
   ,r.liveawayscore  
   ,r.liveindicator  
   ,m.leagueid  
   ,m.sporttype  
   ,m.isNeutral  
   ,m.matchID  
   ,m.matchCode  
 FROM dbo.bettrans AS b with (NOLOCK)  
  INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno --AND b.matchid IN (9,29) AND b.bettype=9  
  INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID  
  --INNER JOIN dbo.customer AS ag with (NOLOCK) ON b.recommend = ag.custid  
  INNER JOIN dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator  
  WHERE --b.matchid = CASE WHEN @bettype = 0 THEN b.matchid ELSE @bettype END
	--AND b.bettype = CASE WHEN @bettype = 0 THEN b.bettype ELSE @bettype END	
	((@bettype = 0 and b.matchid in (9,29)) OR b.matchid = @bettype ) 
	AND ((@bettype = 0 AND b.bettype IN (9,29)) OR b.bettype = @bettype) 
	AND (b.betid = 0 OR b.betid IS NULL)
 
 --0. For Normal bets  
 SELECT *, [Group]='Normal'   
 FROM #ParlayDelete WITH (NOLOCK)    
 WHERE IsDeposit = 0  
  AND custid NOT IN (SELECT CustID FROM [f_GetBetDaqCustomer] (1))    
  AND username <> '12EU'  
  AND mrecommend not in (105181, 118473, 105183)  
 ORDER BY transid  
   
 --1. For Deposit bets  
 SELECT * ,[Group]='Deposit'  
 FROM #ParlayDelete WITH (NOLOCK)    
 WHERE IsDeposit = 1  
  AND custid NOT IN (SELECT CustID FROM [f_GetBetDaqCustomer] (1))    
  AND username <> '12EU'  
  AND mrecommend not in (105181, 118473, 105183)  
 ORDER BY transid  
   
 --2. For Special bets  
 SELECT * ,[Group]='BetDaq'  
 FROM #ParlayDelete WITH (NOLOCK)  
 WHERE custid IN (SELECT CustID FROM [f_GetBetDaqCustomer] (1))  
 ORDER BY IsDeposit DESC, transid  
  
 --3. For 12EU  
 SELECT * ,[Group]='12EU'  
 FROM #ParlayDelete WITH (NOLOCK)  
 WHERE username = '12EU'  
 ORDER BY IsDeposit DESC, transid  
  
 --4. For member of master: MHCEU (105181), MHCRM (118473), MHCUS(105183)  
 SELECT * ,[Group]='MHC'  
 FROM #ParlayDelete WITH (NOLOCK)  
 WHERE mrecommend in (105181, 118473, 105183)  
 ORDER BY IsDeposit DESC, transid  
   
 DROP TABLE #ParlayDelete  
 DROP TABLE #Ref  
     
     
 SET NOCOUNT OFF  
END





GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelDelSpecial_MixParlay] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelDelSpecial_MixParlay] TO [vnteam]