 ALTER TRIGGER [dbo].[balanceTable_tmp_delete] 
   ON  [dbo].[balanceTable_tmp]
   AFTER DELETE
AS 
/*
	Created by:  
	Date: 
	Task:  
	DB: DBTRANS.BODB02
	
	Revisions:
		-- 20100428@Henry: insert data to column statusID + upd status = balance of bettrans

*/

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
		insert into dbo.bettrans 
			(transdate, winlostdate, custid,
			winlost, actual_stake, 
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			bettype, matchid, status,statusID, transdesc, refno, creator, ruben,
			recommend, mrecommend, srecommend, currency,
			username, currencyname, actualrate, virtualrate)
		select 	winlostdate, winlostdate, custid, 
			(case when amount < 0 then 0 else amount end),
			(case when amount < 0 then abs(amount) else 0 end),
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			100, 0, 'Balance',141, 'OPENING BALANCE', 260000000000, 148, 1,
			recommend, mrecommend, srecommend, currency,
			UserName, CurrencyName, actualrate, actualrate
		from deleted

END