ALTER PROCEDURE [dbo].[Acc_CustomerSelFITransferStatus]
    @FromCustId INT,
    @ToUser        VARCHAR(50),
    @IsTransfer BIT OUTPUT,
    @errcode    INT = 0 OUTPUT,
    @errmsg        VARCHAR(200) = '' OUTPUT
   
AS
SET NOCOUNT ON
/*
Created:
Task : Check status acc when transfer (from Betting Acc to Finance Acc or contrary)
DB: DB06.bodb02
Original:

Revisions:
    -
Param's Explanation:
   
*/
BEGIN

	SELECT @IsTransfer = 0

    IF not exists(SELECT 1 FROM custinfo(nolock) WHERE custid = @FromCustId and RoleId<=4)
    BEGIN
        SELECT @errcode = 100, @errmsg = 'Invalid Account'
		 RETURN
    END
       
    IF not exists(SELECT 1 FROM custinfo(nolock) WHERE username = @ToUser and RoleId<=4)
    BEGIN
        SELECT @errcode = 100, @errmsg = 'Invalid Account'
        RETURN
    END

    IF exists(SELECT 1 FROM custinfo(nolock) WHERE custid = @FromCustId and closed = 1)
    BEGIN
        SELECT @errcode = 101, @errmsg = 'The account ' + username + ' was closed, so you can not transfer.' from custinfo (nolock) where custid = @FromCustId
        RETURN
    END

    IF exists(SELECT 1 FROM custinfo(nolock) WHERE username = @ToUser and closed = 1)
    BEGIN
        SELECT @errcode = 101, @errmsg = 'The account ' + @ToUser + ' was closed, so you can not transfer.'
        RETURN
    END

    SELECT @IsTransfer = 1
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFITransferStatus] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFITransferStatus] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFITransferStatus] TO [vnteam]