DECLARE @date1 smalldatetime
SELECT @date1 = '7 Dec 2009'

--------------
SELECT r.*, username
FROM Custinfo c with(nolock) 
INNER JOIN (
		select r1.custid, closingbalance, openingbalance, currency
		FROM
		( 
		select custid, isnull(closingbalance,0) closingbalance, currency
		from bodb_report.dbo.rptdepwinlost with(nolock)
		where winlostdate = @date1
		) r1
		INNER JOIN
		(
		select custid, isnull(openingbalance,0) openingbalance
		from bodb_report.dbo.rptdepwinlost with(nolock)
		where winlostdate = dateadd(dd,1,@date1)
		) r2 on r1.custid = r2.custid 
		where r1.closingbalance <> r2.openingbalance
	) r on c.CustID = r.CustID
ORDER BY username