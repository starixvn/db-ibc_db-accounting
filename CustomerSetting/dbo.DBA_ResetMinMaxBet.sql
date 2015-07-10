CREATE PROCEDURE [dbo].[DBA_ResetMinMaxBet]  
 @UserName varchar(50)  
AS  

/*
	Created by: 
	Date:	
	Task: Reset Min/MaxBet
	DB: DBTRANS.BODB02
	Revisions:
		- 20101111@Henry: new fields for custinfo [MaxPerBall161]
*/	
  
Declare @CustID int, @RoleID tinyint  
select @CustID = CustID, @RoleID = RoleID from customer with (nolock) where username = @UserName  
  
if @RoleID = 3   
BEGIN  
 Update custsetting set MinBet = 0, MaxBet = 0  
 where custid in (select custid from customer with (nolock) where mrecommend = @CustID)   
 Update custinfo set maxpermatch = 0,  
    maxpermatch2 = 0,  
    maxpermatch3 = 0,  
    maxpermatch5 = 0,  
    maxpermatch8 = 0,  
    maxpermatch10 = 0,  
    maxpermatch11 = 0,  
    maxpermatch12 = 0,  
    maxpermatch99 = 0, 
    maxpermatch151 = 0,
    maxpermatch201 = 0, 
    maxpermatch161 = 0,
    maxpermatch99MP = 0,
    maxperball161 = 0
 where custid in (select custid from customer with (nolock) where mrecommend = @CustID)   
  
 Return  
END  
  
if @RoleID = 4  
BEGIN  
 Update custsetting set MinBet = 0, MaxBet = 0  
 where custid in (select custid from customer with (nolock) where srecommend = @CustID)  
  
 Update custinfo set maxpermatch = 0,  
     maxpermatch2 = 0,  
    maxpermatch3 = 0,  
    maxpermatch5 = 0,  
    maxpermatch8 = 0,  
    maxpermatch10 = 0,  
    maxpermatch11 = 0,  
    maxpermatch12 = 0,  
    maxpermatch99 = 0, 
    maxpermatch151 = 0,
    maxpermatch201 = 0, 
    maxpermatch161 = 0,
    maxpermatch99MP = 0,
    maxperball161 = 0
 where custid in (select custid from customer with (nolock) where srecommend = @CustID)  
  
 RETURN  
END  