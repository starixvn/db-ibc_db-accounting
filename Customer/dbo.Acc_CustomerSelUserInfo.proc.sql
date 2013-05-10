ALTER PROCEDURE [dbo].[Acc_CustomerSelUserInfo]  
 @CustID int  
AS  
/*
Created: 
Task : Get User Information
DB: DB05.bodb02
Original:Accounting site

Revisions:
	- 20100109@Henry: No need to get currency Name from Exchange since it is not used
	- 20100414@Kiwi: Remove gender and answer
*/	
SET NOCOUNT ON  
select  
	 c.custid,  
	 c.username,  
	 firstname,  
	 lastname,  
	 username2,  
	 address,  
	 postal,  
	 city,  
	 state,  
	 country,  
	 phone,  
	 mobilephone,  
	 fax,  
	 email,  
	 isnull(birthday, '1990/01/01') as birthday,  
	 refcode1,  
	 refcode2,  
	 remark,  
	 isnull(important,0) as important,  
	 ci.synccasino,
	 ci.disablecasino,
	 c.currency as exchangeid
  
from customer c with (NOLOCK)   
-- left outer join exchange e with (nolock) on c.currency = e.exchangeid  
 inner join custinfo ci with (NOLOCK) on c.custid=ci.custid
where c.custid = @CustID  

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserInfo] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserInfo] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUserInfo] TO [vnteam]