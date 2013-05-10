ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckAllowedDownlines]  
@custid int = 0   
,@roleid int = 0  
,@isExecRep bit = 0  
,@Language varchar(2) = 'E'  
,@ErrCode int = 0 output  
,@ErrMsg nvarchar(200) = '' output    
AS  
  
/*  
Created by: Scott        
Date: 2012-12-06        
Task : Check Allowed downlines during peak hour at weekend    
DB: DB053.bodb02        
Original SP:         
Revisions:        
*/  
  
BEGIN  
  
SET NOCOUNT ON  
  
DECLARE @LimitDownlinesMin int,   
  @LimitDownlinesMax int,  
  @LimitDownlines int,  
  @TotalDownlines int  
  
  
SET @LimitDownlinesMin = 5000  
SET @LimitDownlinesMax = 20000  
   
IF @isExecRep = 1  
BEGIN  
 SET @LimitDownlinesMin = 50000  
 SET @LimitDownlinesMax = 200000  
END  
  
--GET TOTALDOWNLINE  
set @TotalDownlines=1  
  
IF @roleid = 4   
BEGIN  
 SELECT  @TotalDownlines = count(1)   
 FROM Custinfo WITH (NOLOCK)  
 WHERE srecommend=@custID  
END  
IF @roleid = 3   
BEGIN  
 SELECT  @TotalDownlines = count(1)   
 FROM Custinfo WITH (NOLOCK)  
 WHERE mrecommend=@custID  
END  
IF @roleid = 2   
BEGIN  
 SELECT  @TotalDownlines = count(1)   
 FROM Custinfo WITH (NOLOCK)  
 WHERE recommend=@custID  
END  
  
  
  
SELECT  @LimitDownlines = CASE WHEN datename(weekday, getdate()) in ('Saturday','Sunday') and   
          datepart(hour, getdate()) between 7 and  14 --Weekend's peak hour, from 7PM - 2AM (GMT+8)  
        THEN  @LimitDownlinesMin  
       ELSE @LimitDownlinesMax  END   
  
IF @TotalDownlines >  @LimitDownlines  
BEGIN     
	
	DECLARE  @MsgID INT
	SET  @MsgID = 90010
	EXEC @ErrMsg = DBLOG.[bodb_customerLog].[dbo].[f_Get_MsgNamebyMsgID] @MsgID,@Language    
	   
	SELECT @ErrCode = 113 
     
END   
   
  
END   
  