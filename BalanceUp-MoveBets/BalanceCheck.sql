ALTER PROCEDURE [dbo].[BalanceCheck]
	@winlostdate smalldatetime = NULL,
	@step tinyint = NULL
AS
/*
	Revision: 
		-- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, Exchange by link database)
*/
IF @winlostdate IS NULL
BEGIN
	SELECT 0,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
	from bettrans with (nolock) inner join CustDB.dbo.exchange e with (nolock) ON bettrans.currency=e.exchangeid
	where ruben=1

	SELECT 1,
		SUM(e.actualrate * IsNull(bal,0)) bal,
		SUM( IsNull(bal,0)) bal2
	FROM CustDB.dbo.custinfo c (nolock)
	LEFT OUTER JOIN (
	SELECT srecommend,
	  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
	+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
	+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
	+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Bal
	FROM bettrans (nolock) GROUP BY bettrans.srecommend
	) bal ON c.custid = bal.srecommend
	INNER JOIN CustDB.dbo.exchange e (nolock) ON c.currency = e.exchangeid
	WHERE c.roleid = 4
END
ELSE
BEGIN
	INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
	--exec companybalance2
	SELECT @step, @winlostdate, 0,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)*e.actualrate) totalamt,
		sum((winlost-actual_stake+awinlost+mwinlost+swinlost +scomm)) TotalSUM
	from bettrans with (rowlock) inner join CustDB.dbo.exchange e with (nolock) ON bettrans.currency=e.exchangeid
	where ruben=1 AND winlostdate <= @winlostdate

	INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
	--exec admin_rpt_sabalance
	SELECT @step+1, @winlostdate, 1,
		SUM(e.actualrate * IsNull(bal,0)) bal,
		SUM( IsNull(bal,0)) bal2
	FROM CustDB.dbo.custinfo c (nolock)
	LEFT OUTER JOIN (
	SELECT srecommend,
	  IsNull(sum(case when custid=srecommend then winlost-actual_stake else swinlost+scomm-acomm end),0)
	+ IsNull(sum(case when custid=mrecommend then winlost-actual_stake else mwinlost+acomm-comm end),0)
	+ IsNull(sum(case when custid=recommend  then winlost-actual_stake else awinlost+comm-playercomm end),0)
	+ IsNull(sum(case when custid <> recommend and custid <> mrecommend and custid <> srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end),0) Bal
	FROM bettrans (rowlock) WHERE winlostdate <= @winlostdate GROUP BY bettrans.srecommend
	) bal ON c.custid = bal.srecommend
	INNER JOIN CustDB.dbo.exchange e (nolock) ON c.currency = e.exchangeid
	WHERE c.roleid = 4
END