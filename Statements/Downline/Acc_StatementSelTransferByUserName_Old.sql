
ALTER PROCEDURE [dbo].[Acc_StatementSelTransferByUserName_Old]
	@fromdate		SMALLDATETIME
	,@todate		SMALLDATETIME
	,@username		VARCHAR(30)
AS
/* 
Created: [Cody]
Date: 20150129
Task : downline statement - transfer details [#27002]
DB: DBARC.bodb02
Original:
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @custid	INT
			
	SELECT @custid = custid
	FROM bodb02.dbo.Customer WITH(NOLOCK)
	WHERE username = @UserName
	
	IF @custid IS NULL
	BEGIN
		PRINT 'Invalid username!'
		RETURN
	END
	
	SELECT 
		transdate AS Transdate
		,bt.typenamee AS Transtype
		,transdesc AS Transdesc
		,credit - debit AS Amount
		,NULL AS Exrate
	FROM 
		dbo.transfer_bk tbk WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Bettype bt WITH(NOLOCK) ON (tbk.bettype = bt.typeid) 
	WHERE
		 winlostdate BETWEEN @fromdate AND @todate 
		AND custid = @custid
	ORDER BY TransDate
END

GRANT EXECUTE ON [dbo].[Acc_StatementSelTransferByUserName_Old] TO [BODBDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_StatementSelTransferByUserName_Old] TO [BODBExtAccNet]

