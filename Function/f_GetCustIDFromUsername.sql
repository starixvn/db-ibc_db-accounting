ALTER FUNCTION [dbo].[f_GetCustIDFromUsername]
(
	@Username varchar(30)
)
RETURNS int
AS
/*
Created: Thien
Task : Get CustID from username. Note that DB06.bodb02 got index on Customer.username and username2
DB: DB06.bodb02
Original:Accounting site
*/
BEGIN
	declare @custID int
	
	select @custid = custid
	from customer with (nolock)
	where username = RTRIM(LTRIM(@username))

	if (@custid IS NULL)
		select @custid = custid
		from customer with (nolock)
		where username2 = RTRIM(LTRIM(@username))
	
	return @custID
		
END

GO
GRANT EXECUTE ON [dbo].[f_GetCustIDFromUsername] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[f_GetCustIDFromUsername] TO [vnteam]