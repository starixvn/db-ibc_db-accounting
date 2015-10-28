

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_Rpt_RNGCasinoAutomail_Recent    Script Date: 10/15/2015 3:59:16 PM ******/
 
CREATE PROCEDURE [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent]
 @amount MONEY = 5000,
 @fromdate DATETIME,
 @todate DATETIME
 
AS

--declare
-- @amount MONEY ,
-- @fromdate DATETIME,
-- @todate DATETIME
 
--select
-- @amount = 1,
-- @fromdate = '2015-08-01',
-- @todate = '2015-08-31'

/*
 Created: Robert
 Date: 20151001
 Task :#41479 - Big Win/Loss Members on RnG product
 DB: DBACC.bodb02
 Original:
    
 Revisions:
    -20151015@Robert: revise sp
  
 Param's Explanation:
 
*/
IF ISNULL(@amount,0)=0
    RETURN;
ELSE 
 BEGIN
      SELECT username,
             recommend,
             currency,
             DATEADD( Hour, DATEDIFF(Hour , 0, transdate), 0) AS [Truncate],
             SUM((winlost-actual_stake)*actualrate) AS winlost_rm,
             SUM(winlost-actual_stake) AS winlost
             INTO #temp
      FROM dbo.bettrans WITH (NOLOCK)
      WHERE transdate BETWEEN @FromDate and @ToDate
           AND bettype = 71 
           AND matchid = 0
           AND statusID IN (112,113) 
           AND srecommend NOT IN (SELECT custid FROM dbo.Dep_CustSuper WITH (NOLOCK))
       GROUP BY username
            ,recommend
            ,currency
            ,DATEADD( Hour, DATEDIFF(Hour , 0, transdate), 0)
      HAVING ABS(SUM((winlost-actual_stake)*actualrate)) >= @amount

      SELECT t.username  AS member
             ,ca.currency
             ,ca.username AS agent
             ,winlost
             ,winlost_rm
             ,COUNT(*) NumOfBets
             ,[Truncate]
      FROM #temp t
      INNER JOIN dbo.custInfo ca WITH (NOLOCK)  ON ca.custid = t.recommend
      GROUP BY t.username   
             ,ca.currency
             ,ca.username  
             ,winlost
             ,winlost_rm
             ,[Truncate]
      ORDER BY [Truncate] DESC
      DROP TABLE #temp
 END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_Rpt_RNGCasinoAutomail_Recent] TO [bodbAdminNet]
GO 


