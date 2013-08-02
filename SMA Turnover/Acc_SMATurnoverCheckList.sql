ALTER PROCEDURE [dbo].[Acc_SMATurnoverCheckList]   
 @UserID INT,  
 @ListSMA XML,    
 @ErrCode INT = 0 OUTPUT,  
 @ErrMsg NVARCHAR(80) = '' OUTPUT  
AS  
/*  
 Creator: Elodie  
 Task : Check list SMA valid or invalid  
 DB: DBAGE/bodb02  
 Original:   
  
 Revisions:    
  
*/  
BEGIN  
SET NOCOUNT ON  
     
 --Check permission   
 EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SMATurnoverManagement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT  
 IF @ErrCode <> 0  
  RETURN  
  
 DECLARE @tblCust TABLE (  
  Seq INT,  
  SMAName VARCHAR(30),  
  CustID INT,  
  MatchID INT,  
  MaxTurnover VARCHAR(50)    
 )  
   
 DECLARE @tblSucc TABLE (  
  Seq INT,  
  SMAName VARCHAR(30),  
  CustID INT,  
  MatchID INT,  
  MaxTurnover MONEY  
 )  
  
 DECLARE @tblFail TABLE (  
  Seq INT,  
  SMAName VARCHAR(30),  
  CustID INT,  
  MatchID INT,  
  MaxTurnover VARCHAR(50),  
  Reason NVARCHAR(100)  
 )  
   
 INSERT INTO @tblCust(Seq, SMAName, MatchID, MaxTurnover)      
 SELECT T.C.value('./@Seq', 'int'),  
   T.C.value('./@SMAName', 'varchar(30)'),  
   T.C.value('./@MatchID', 'int'),  
   T.C.value('./@MaxTurnover', 'varchar(50)')  
 FROM @ListSMA.nodes('/ListSMA/SMA') AS T(C)  
   
 UPDATE @tblCust  
 SET MaxTurnover = replace(MaxTurnover,',','')  
   
 UPDATE @tblCust  
 SET CustID = c.custid  
 FROM DBACC.bodb02.dbo.customer c WITH (NOLOCK) --use index in DBACC server  
 WHERE username = SMAName  
   
 DECLARE @tmpDuplicateCust TABLE (CustID INT)  
   
 INSERT INTO @tmpDuplicateCust(CustID)   
 SELECT CustID   
 FROM @tblCust  
 GROUP BY CustID, MatchID  
 HAVING count(1) >=2  
   
 --Validate transaction  
 INSERT INTO @tblSucc(Seq, SMAName, CustID, MatchID, MaxTurnover)  
 SELECT Seq, SMAName, CustID, MatchID, cast(cast(MaxTurnover AS FLOAT) AS MONEY)  
 FROM @tblCust as t  
 WHERE ISNUMERIC(MaxTurnover)=1 and cast(MaxTurnover AS FLOAT) <= 999999999999 and cast(MaxTurnover AS FLOAT) >= 0 and round(MaxTurnover,0) = MaxTurnover  
  AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE roleid = 4 and custInfo.custid = t.CustID)  
  AND NOT EXISTS (SELECT 1 FROM DownlineTurnOver_Setting ds WITH (NOLOCK) WHERE t.CustID = ds.custid and t.MatchID = ds.matchid)  
  AND CustID NOT IN (SELECT CustID FROM @tmpDuplicateCust where CustID IS NOT NULL)       
   
 --Failed Transaction  
 INSERT INTO @tblFail(Seq, SMAName, CustID, MatchID, MaxTurnover, Reason)  
 SELECT Seq, SMAName, CustID, MatchID, MaxTurnover,    
   CASE WHEN ISNUMERIC(MaxTurnover)=0 or (ISNUMERIC(MaxTurnover)=1 and (cast(MaxTurnover AS FLOAT) < 0 or cast(MaxTurnover AS FLOAT) > 999999999999)) or round(MaxTurnover,0) <> MaxTurnover THEN 'Invalid Max Turnover.'  
     WHEN NOT EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE roleid = 4 and custInfo.custid = t.CustID) THEN 'Invalid SMA Name.'   
     WHEN EXISTS (SELECT 1 FROM DownlineTurnOver_Setting ds WITH (NOLOCK) WHERE t.CustID = ds.custid and t.MatchID = ds.matchid) THEN 'The SMA already exists in match: ' + cast(t.MatchID AS VARCHAR(10)) + '.'  
     WHEN CustID IN (SELECT CustID FROM @tmpDuplicateCust where CustID IS NOT NULL) THEN 'Duplicate SMA Name.'  
   END AS Reason    
 FROM (SELECT * FROM @tblCust WHERE Seq not in (SELECT Seq FROM @tblSucc)) AS t        
         
 SELECT t.SMAName, t.CustID, m.matchid, t.MaxTurnover, eventdate, homeid, awayid  
 FROM @tblSucc t  
  INNER JOIN match m WITH (NOLOCK) on m.matchid = t.MatchID  
 ORDER BY MatchID, SMAName  
  
 SELECT SMAName, CustID, MaxTurnover, Reason  
 FROM @tblFail   
 GROUP BY SMAName, CustID, MaxTurnover, Reason  
 ORDER BY SMAName, Reason  
  
END  
  