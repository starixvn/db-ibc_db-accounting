USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_BettransSelBet_BatchMsg]    Script Date: 06/15/2015 09:09:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_BettransSelBet_BatchMsg]  
 @transids varchar(4000)  
AS  
/*  
    Created by: Daniel  
 Date:   
 Original: DBA_SelBet_BatchMsg  
 Task: Select batch msg  
 DB: DBACC/BODB02  
  
 History:  
  - 20100823@Khoa: add more @transids  
  - 20101007@Henry: Change column transid from INT to BIGINT  
  - 20140224@Elodie: Apply LAS system [Redmine:#10701]  
  - 20150403@Kathy: Support uploading msg for ticket has been moved in bettrans14
  - 20150615@Dominic: Exclude 3 sub-tickets of BetTrade (901,902,903)  
  - 20150625@Dominic: Add ticket from translog/translog14 [Redmine:#38200]  
 Explanation's Param:  
  
*/  
BEGIN  
  
 SET NOCOUNT ON  
 DECLARE @BetDelete TABLE (transid bigint,refno bigint,bettype smallint, custid int, recommend int, mrecommend int, srecommend int, betfrom nvarchar(1))  
 DECLARE @TransIdsLAS VARCHAR(MAX), @strLASAgent VARCHAR(500) 
 DECLARE @tblInvalidTransIds TABLE(transid VARCHAR(20))
 DECLARE @tblTransLAS TABLE(transid VARCHAR(20))  
 DECLARE @LASCust TABLE (custid INT)  
 DECLARE @AgentUpline TABLE (TransID BIGINT,TargetID INT,TargetName VARCHAR(50),IsAgent BIT)  
  
 create table #transid (transid BIGINT )  
 INSERT INTO #transid  
 SELECT distinct (convert(varchar,val)) FROM dbo.strSplit(@transids,',')  
   
	INSERT INTO @BetDelete (transid, refno, bettype, custid, recommend, mrecommend, srecommend, betfrom)   
	SELECT transid, refno, bettype, custid, recommend, mrecommend, srecommend, betfrom  
	FROM bettrans b with (nolock)  
	WHERE b.transid  in ( SELECT transid from #transid )
		AND b.Bettype NOT IN (801,803,804,805,806,901,902,903)
	UNION ALL
	SELECT transid, refno, bettype, custid, recommend, mrecommend, srecommend, betfrom  
	FROM bettrans b with (nolock)  
	WHERE b.refno IN ( SELECT transid from #transid )
		AND b.Bettype IN (801,803,804,805,806) 
	UNION ALL  
	SELECT transid, refno,bettype,custid, recommend, mrecommend, srecommend, betfrom  
	FROM bettrans14 b14 with (nolock)  
	WHERE b14.transid in ( SELECT transid from #transid ) 
		AND b14.Bettype NOT IN (801,803,804,805,806,901,902,903)
	UNION ALL
	SELECT transid, refno,bettype,custid, recommend, mrecommend, srecommend, betfrom  
	FROM bettrans14 b14 with (nolock)  
	WHERE b14.refno in ( SELECT transid from #transid ) 
		AND b14.Bettype IN (801,803,804,805,806)
	UNION ALL  
	SELECT translogid, translogid, gameid, ts.custid, ts.recommend, ts.mrecommend, ts.srecommend, ts.betfrom  
	FROM translog ts with (nolock)  
	LEFT JOIN bettrans b WITH(nolock) ON ts.gameid = b.bettype AND b.matchid = ts.eventid AND b.custid = ts.Custid AND ts.translogid = b.refno
	WHERE translogid in ( SELECT transid from #transid ) 
	AND ts.GameID IN (801,803,804,805,806)  AND b.refno IS NULL
	UNION ALL  
	SELECT translogid, translogid, gameid, ts14.custid, ts14.recommend, ts14.mrecommend, ts14.srecommend, ts14.betfrom  
	FROM translog14 ts14 with (nolock)  
	LEFT JOIN bettrans14 b14 WITH(nolock) ON ts14.gameid = b14.bettype AND b14.matchid = ts14.eventid AND b14.custid = ts14.Custid AND ts14.translogid = b14.refno
	WHERE translogid in ( SELECT transid from #transid ) 
	AND ts14.GameID IN (801,803,804,805,806)  AND b14.refno IS NULL
  
 exec DBLAS.LASDB.dbo.Las_Get_recommend @StringRec = @strLASAgent output  
  
 INSERT INTO @LASCust  
 SELECT CONVERT(INT, val) FROM dbo.strSplit(ISNULL(@strLASAgent, ''), '^')  
   
 INSERT INTO @tblTransLAS(transid)  
 SELECT cast(b.transid as varchar(20))  
 FROM @BetDelete b   
 WHERE b.recommend IN (SELECT custid FROM @LASCust)  
  
 ;with tmp as  
 (Select stuff(  
   (  
   Select '^ ' + T2.transid  
   From @tblTransLAS As T2  
   Order By T2.transid  
   For Xml Path(''), type  
   ).value('.', 'varchar(max)'), 1, 2, '') As val  
 From @tblTransLAS As T1  
 )  
 SELECT @TransIdsLAS = val + ',' from tmp  
  
 select CASE WHEN bettype IN (801,803,804,805,806) THEN refno ELSE transid END transid,   
  bd.custid, mem.UserName     as CustUserName,  
  bd.recommend, ag.UserName as AgUserName,  
  bd.mrecommend, mag.UserName as MagUserName,  
  bd.srecommend, sag.Username as SagUserName   
 from   
  @BetDelete bd   
  INNER JOIN custinfo mem (nolock) on bd.custid     = mem.custid  
  INNER JOIN custinfo ag  (nolock) on bd.recommend  = ag.custid  
  INNER JOIN custinfo mag (nolock) on bd.mrecommend = mag.custid  
  INNER JOIN custinfo sag (nolock) on bd.srecommend = sag.custid  
   
 IF @TransIdsLAS IS NOT NULL  
 BEGIN  
  BEGIN TRY  
   EXEC DBLAS.LASDB.dbo.LAS_BettransSelBet_BatchMsg @transids= @transids  
   SELECT '' AS TransIDFail  
  END TRY  
  BEGIN CATCH  
   SELECT TransID, TargetID, TargetName, IsAgent FROM @AgentUpline  
   SELECT @TransIdsLAS AS TransIDFail  
   RETURN  
  END CATCH  
 END  
 ELSE  
 BEGIN  
  SELECT TransID, TargetID, TargetName, IsAgent FROM @AgentUpline  
  SELECT '' AS TransIDFail  
 END  
 
 --Gte invalid transids
 INSERT INTO @tblInvalidTransIds(transid)  
 SELECT CAST(b.transid as varchar(20))  
 FROM #transid b   
 WHERE b.transid NOT IN (SELECT CASE WHEN bettype IN (801,803,804,805,806) THEN refno ELSE transid END FROM @BetDelete)

 
 SELECT STUFF((SELECT distinct '^' + p1.transid
 FROM @tblInvalidTransIds p1
		FOR XML PATH(''), TYPE
		).value('.', 'NVARCHAR(MAX)')
	,1,1,'') AS InvalidTransID
 
END  
GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [vnteam] AS [dbo]