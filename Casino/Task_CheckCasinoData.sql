CREATE PROCEDURE [dbo].[Task_CheckCasinoData]
AS
/*
Created: 20100721@Ken
Task : Check Casino data
DB: DB05.bodb02

Param's Explanation:
• @UserName customer id.   
*/
SET NOCOUNT ON

DECLARE @ErrCode int, @ErrMsg nvarchar(3000)
SELECT @ErrCode = 0, @ErrMsg = ''

IF EXISTS (
	SELECT 1 
	FROM CustInfo WITH (nolock)
	WHERE Custid not in (SELECT isnull(IBCCustid,0) FROM DBCasino.CasinoAdmin.dbo.Customer WITH (nolock))
		and SyncCasino=1
		and currency<>20
		and enabled=1
) 
BEGIN
	SELECT @ErrMsg = @ErrMsg + '+ SyncCasino=1 in IBC DB and does not exist in Casino DB<br />'
	SELECT @ErrCode = 101
END

IF EXISTS (
	SELECT 1 FROM CustInfo ibc WITH (nolock)
		INNER join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
		ON ibc.custid = cas.IBCCustID
	WHERE ibc.enabled=1
		and ibc.currency<>20
		and ibc.DisableCasino=0
		and ibc.SyncCasino=1
		and cas.EnableCasino=0
) 
BEGIN
	SELECT @ErrMsg = @ErrMsg + '+ Enable in IBC DB but Disable in Casino DB<br />'
	SELECT @ErrCode = 101
END


IF EXISTS (
	SELECT 1 FROM CustInfo ibc WITH (nolock)
	INNER join DBCasino.CasinoAdmin.dbo.Customer cas WITH (nolock)
	ON ibc.custid = cas.IBCCustID
	WHERE ibc.enabled=1
	and ibc.currency<>20
	and ibc.DisableCasino = 1
	and ibc.SyncCasino = 1
	and cas.EnableCasino=1
) 
BEGIN
	SELECT @ErrMsg = @ErrMsg + '+ Disable in IBC DB but Enable in Casino DB<br />'
	SELECT @ErrCode = 101
END

IF EXISTS (
	SELECT 1 FROM custinfo ibc WITH (nolock)
		INNER join DBCASINO.CasinoAdmin.dbo.customer cas WITH (nolock) ON ibc.custid = cas.ibccustid
	WHERE ibc.closed = 0
		and cas.isfrozen=1
		and ibc.synccasino=1
		and ibc.enabled=1
		and ibc.currency <> 20
) 
BEGIN
	SELECT @ErrMsg = @ErrMsg + '+ Opened in IBC DB but Closed in Casino DB<br />'
	SELECT @ErrCode = 101
END

--select @ErrCode, @ErrMsg
IF @ErrCode <> 0
RAISERROR(@ErrMsg,16,1)

GO
GRANT VIEW DEFINITION ON [dbo].[Task_CheckCasinoData] TO [vnteam]