ALTER PROCEDURE [dbo].[DBA_Casino_BetIns_CorrectMissingTickets]   
 @custid    int,     
------------------------Casino  
 @CS_Turnover   money = 0,  
 @CS_Winlost    money = 0,  
 @CS_swinlost   money = 0,  
 @CS_mwinlost   money = 0,  
 @CS_awinlost   money = 0,  
 @CS_scomm    money = 0,  
 @CS_mcomm    money = 0,  
 @CS_acomm    money = 0,  
 @CS_playercomm   money = 0,  
 @CS_pendingAmount  money = 0,  
 @CS_sposition   smallmoney = 0,  
 @CS_mposition   smallmoney = 0,  
 @CS_aposition   smallmoney = 0,  
   
 @refno    bigint,   
 @sessionId   bigint = 0,  
 @transdesc   nvarchar(300)='',   
 @ip     nvarchar(15)='',  
 @ErrCode   int = 0 OUTPUT,  
 @ErrMsg    nvarchar(200) = '' OUTPUT  
AS  
/*  
Creator : Phuong Dao  
Date : 2010-08-27  
Task : Insert missing Casino Bet tickets  
DB: DBTRANS.bodb02  
Revision:
	- 20110513@Henry: change bettype to new range
	- 20120405@Hurri: Exclude bettypes of P2P
	- 20130704@Kathy: update matchid for RnG Casino (71)
Param's Explanation:  
  
• Full structure of Dummy accounts:  
  --ACC Super  3rdSuperUUS  3rdSuperEURO    other currencies...  
  --ACC Master CasUS$   CasEURO  
  --ACC Agent  CasUS$01  CasEURO01  
  --ACC Member CasBetUS$  CasBetEURO  
  
• @casinoTurnover: always positive   
• @casinoWinlost: casinoWinlost = casinoTurnover + member's winlost   
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
   
• @ErrMsg: Error description.  
  
*/  
  
SET NOCOUNT ON  
  
DECLARE @roleid    tinyint,  
  @username   varchar(30),  
  @recommend   int,   
  @mrecommend   int,   
  @srecommend   int,   
  @actualrate   float,   
  @cs_mem_status  nvarchar(10),  
  @cs_mem_statusID int, 
  @currency   tinyint,   
  @currencyName  nvarchar(5),   
  @transdate   datetime,   
  @winlostdate  datetime,  
  @dummy_username  nvarchar(15),  
  @dummy_custid  int,  
  @dummy_recommend int,  
  @dummy_mrecommend int,  
  @dummy_srecommend int  
  
SELECT  @ErrCode = 0, @ErrMsg = ''   
  
IF @cs_Turnover < 0 OR @cs_Winlost < 0
BEGIN  
 SELECT @ErrMsg = 'Sorry, amount is invalid.', @ErrCode = 101   
 RETURN    
END  
  
SELECT @username= ci.username,  
  @roleid = isnull(ci.roleid,0),   
  @recommend = ci.recommend,  
  @mrecommend = ci.mrecommend,   
  @srecommend = ci.srecommend,  
  @currency = ci.currency,   
  @currencyName = e.currency,   
  @actualrate = e.actualrate  
  
FROM custinfo ci WITH (NOLOCK)   
  INNER JOIN exchange e WITH (NOLOCK) on ci.currency = e.exchangeid  
WHERE   ci.custid = @custid   
  
IF @roleid <> 1  
BEGIN  
 SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102    
 RETURN  
END  
  
  
SELECT @cs_mem_status = CASE WHEN @cs_Winlost > @cs_Turnover THEN 'WON'  
        WHEN @cs_Winlost < @cs_Turnover THEN 'LOSE'  
        ELSE 'DRAW' END   
          
SELECT @cs_mem_statusID = CASE WHEN @cs_Winlost > @cs_Turnover THEN 112  
        WHEN @cs_Winlost < @cs_Turnover THEN 113  
        ELSE 111 END            
  
SELECT @dummy_custid = c.custid,  
  @dummy_username = c.username,  
  @dummy_recommend = c.recommend,  
  @dummy_mrecommend = c.mrecommend,  
  @dummy_srecommend = c.srecommend  
FROM custinfo c WITH (NOLOCK)   
WHERE c.username = 'CasBet' + @currencyName AND c.roleid = 1   
  
IF isnull(@dummy_custid, 0) = 0  
BEGIN  
 SELECT @ErrMsg = 'Invalid Dummy account or Account is not existed!', @ErrCode = 106    
 RETURN  
END  
  
------------------Insert trans into DB---------------------------------------------------------------  
SELECT @transdesc = 'Casino Betting' + CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc ELSE '' END  
  
SELECT @transdate = CURRENT_TIMESTAMP , @winlostdate = CONVERT(nvarchar(10), CURRENT_TIMESTAMP, 120)  
  
IF (@CS_Turnover > 0 or @CS_Winlost > 0)  
BEGIN  
---INSERT CASINO BET TICKET   
 INSERT INTO bettrans   
 (custid, username, refno, transdate, matchid, bettype, transdesc, winlost, stake, actual_stake,   
  awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, winlostdate, creator,   
  recommend, mrecommend, srecommend, playerdiscount, discount, adiscount, sdiscount,   
  apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, currency, actualrate, currencyName,   
  ruben, status,statusID,ip,betid)  
 VALUES   
 (@CustID, @username, @refno, @transdate, 71, 71, @transdesc, @cs_Winlost, @cs_Turnover, @cs_Turnover,  
  @cs_awinlost, @cs_mwinlost, @cs_swinlost, @cs_playercomm, @cs_acomm, @cs_mcomm, @cs_scomm, @winlostdate,   
  @CustID, @Recommend, @MRecommend, @SRecommend, 0, 0, 0, 0, @CS_aposition, @CS_mposition, @CS_sposition, @CS_aposition +@CS_mposition + @CS_sposition,   
  @Currency, @actualrate, @currencyName, 1, @cs_mem_status,@cs_mem_statusID, @ip,@sessionId)  
  
 IF @@ERROR <> 0  
 BEGIN     
  SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107   
  RETURN  
 END   
END  
  
IF (@CS_Turnover > 0 or @CS_Winlost > 0)  
BEGIN  
 --INSERT CASINO DUMMY TICKET  
 INSERT INTO bettrans   
  (custid, username, refno, transdate, matchid, bettype, transdesc, winlost, stake, actual_stake,   
   awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, winlostdate, creator,   
   recommend, mrecommend, srecommend, playerdiscount, discount, adiscount, sdiscount,   
   apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,  
   currency, actualrate, currencyName, ruben, status,statusID,ip,betid)  
 VALUES   
  (@dummy_custID, @dummy_username, @refno, @transdate, 71, 71, @transdesc, @cs_Turnover, @cs_Winlost,@cs_Winlost,  
   -@cs_awinlost, -@cs_mwinlost, -@cs_swinlost, -@cs_playercomm, -@cs_acomm, -@cs_mcomm, -@cs_scomm, @winlostdate, @dummy_custID,   
   @dummy_recommend, @dummy_mrecommend, @dummy_srecommend, 0, 0, 0, 0, 0, 0, 0, 0,   
   @Currency, @actualrate, @currencyName, 1, 'DONE',121, @ip,@sessionId)  
  
 IF @@ERROR <> 0  
 BEGIN     
  SELECT @ErrMsg = 'Insert transaction failed.', @ErrCode = 107   
  DELETE FROM bettrans WHERE refNo = @refno AND bettype in (71,23002) and matchid IN (0, 71)  
  RETURN  
 END  
END  
   
--UPDATE MEMBER TRANS   
UPDATE bettrans WITH (ROWLOCK, UPDLOCK)  
    SET status = 'Completed',statusID=131, ruben = 1, winlost = actual_stake  
WHERE custid=@custid and refno = @refno and bettype = 23001 and matchid = 0  
  
IF @@ERROR <> 0  
BEGIN     
 SELECT @ErrMsg = 'Update transaction failed.', @ErrCode = 108   
 --delete all trans of current session  
 DELETE FROM bettrans WHERE refNo = @refno AND bettype in (71,23002) and matchid IN (0, 71) 
 RETURN  
END  
  
  
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_Casino_BetIns_CorrectMissingTickets] TO [vnteam]