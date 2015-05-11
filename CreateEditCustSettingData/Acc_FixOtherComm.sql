if exists (select 1
				from custsetting
				where custid = 2
					and bettype =4
					and sporttype = 1
					and sdiscount = 0.05)
BEGIN
	Update custsetting set
		playerdiscount = playerdiscount/20, discount = discount/20, adiscount = adiscount/20,
		sdiscount = sdiscount/20
	where bettype in (4,5,6,9,10,20,21,22)
END

---------------------
--SPs: Acc_CustomerSelCEditCustomer
if exists (select 1
				from custsetting
				where custid = 2
					and bettype = 4
					and sporttype = 1
					and sdiscount = 0.0025)
BEGIN
	Update custsetting set
		playerdiscount = playerdiscount*4, discount = discount*4, adiscount = adiscount*4,
		sdiscount = sdiscount*4
	where bettype in (4,5,6,9,10,20,21,22)
END

--------------------------
---Disable trigger custsetting_history first

EXEC dbo.ExecRep_07 @Sporttype = 1, @Bettype = 4
GO
EXEC dbo.ExecRep_07 @Sporttype = 1, @Bettype = 5
GO
EXEC dbo.ExecRep_07 @Sporttype = 1, @Bettype = 6
GO
EXEC dbo.ExecRep_07 @Sporttype = 1, @Bettype = 9
GO
EXEC dbo.ExecRep_07 @Sporttype = 1, @Bettype = 10
GO
--------
EXEC dbo.ExecRep_07 @Sporttype = 2, @Bettype = 9
GO
EXEC dbo.ExecRep_07 @Sporttype = 2, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 3, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 5, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 8, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 10, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 11, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 99, @Bettype = 20
GO
EXEC dbo.ExecRep_07 @Sporttype = 12, @Bettype = 21
GO
EXEC dbo.ExecRep_07 @Sporttype = 12, @Bettype = 22