ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckEnable]
 @username	nvarchar(50)=null
,@custid	int = 0 
,@ErrCode	int = 0 output
,@ErrMsg	nvarchar(200) ='' output 	
AS
/*
Created: 20101203@Henry
Task: check enable of a customer
DB: DB05.bodb02
Original: 

Revisions:
	20120516@Dom: add username to error message
*/
BEGIN
SET NOCOUNT ON
declare @isEnable bit

if @custid =0
begin
	select @isEnable = isnull(enabled,0) from custinfo with (nolock)
	where username =@username 
end 
else if @username is null 
begin
	select @isEnable = isnull(enabled,0), @username = username from custinfo with (nolock)
	where custid = @custid 
end

if @isEnable = 0 or @@rowcount =0
begin
	select @ErrMsg = 'Account '+@username+' was disabled!'
		, @ErrCode = 600
	return
end
END 

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCheckEnable] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckEnable] TO [bodbDownlineNetView]
