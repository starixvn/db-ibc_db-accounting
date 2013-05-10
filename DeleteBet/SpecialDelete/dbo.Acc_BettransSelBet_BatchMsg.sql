ALTER PROCEDURE [dbo].[Acc_BettransSelBet_BatchMsg]
@transids varchar(4000)
AS
SET NOCOUNT ON
/*
    Created by: Daniel
	Date: 
	Original: DBA_SelBet_BatchMsg
	Task: Select batch msg
	DB: DB06.BODB02

	History:
		- 20100823@Khoa: add more @transids
		- 20101007@Henry: Change column transid from INT to BIGINT
	Explanation's Param:

*/

DECLARE @BetDelete TABLE (transid bigint, custid int, recommend int, mrecommend int, srecommend int, betfrom nvarchar(1))

INSERT INTO @BetDelete (transid, custid, recommend, mrecommend, srecommend, betfrom)	
SELECT distinct transid, custid, recommend, mrecommend, srecommend, betfrom
FROM bettrans b with (nolock)
WHERE transid in ( SELECT convert(varchar,val) FROM dbo.strSplit(@transids,',') )

select transid, 
	bd.custid, mem.UserName	    as CustUserName,
	bd.recommend, ag.UserName	as AgUserName,
	bd.mrecommend, mag.UserName as MagUserName,
	bd.srecommend, sag.Username as SagUserName 
from 
	@BetDelete bd 
	INNER JOIN custinfo mem (nolock) on bd.custid     = mem.custid
	INNER JOIN custinfo ag  (nolock) on bd.recommend  = ag.custid
	INNER JOIN custinfo mag (nolock) on bd.mrecommend = mag.custid
	INNER JOIN custinfo sag (nolock) on bd.srecommend = sag.custid
GO
GRANT EXECUTE ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BettransSelBet_BatchMsg] TO [VNTeam]

