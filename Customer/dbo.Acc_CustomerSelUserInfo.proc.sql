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
	- 20140519@Logan:   1.Retrieve remark for SAg, MAg, Ag from CustSuper, CustMaster & CustAgent
	                    2.Code aligning
*/	
SET NOCOUNT ON

declare @roleid tinyint
declare @remark nvarchar(300) = ''
select @roleid = roleid
  from Customer with(nolock)
 where custid = @CustID
 
if @roleid = 1
begin
    select @remark = remark
      from customer with(nolock)
     where custid = @CustID
end
if @roleid = 2
begin
    select @remark = creationRemark
      from CustAgent with(nolock)
     where custid = @CustID
end
if @roleid = 3
begin
    select @remark = creationRemark
      from CustMaster with(nolock)
     where custid = @CustID
end
if @roleid = 4
begin
    select @remark = creationRemark
      from CustSuper with(nolock)
     where custid = @CustID
end

select c.custid,
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
	   @remark as remark,
	   isnull(important,0) as important,
	   ci.synccasino,
	   ci.disablecasino,
	   c.currency as exchangeid
  from customer c with(NOLOCK) inner join custinfo ci with(NOLOCK)
    on c.custid = ci.custid  
-- left outer join exchange e with (nolock) on c.currency = e.exchangeid  
 where c.custid = @CustID

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserInfo] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUserInfo] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUserInfo] TO [vnteam]