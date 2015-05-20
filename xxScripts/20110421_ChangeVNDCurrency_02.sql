--Deposit_DB
WHILE (1=1)
BEGIN
	UPDATE TOP(2000) Deposit_Customer WITH (ROWLOCK, UPDLOCK)
	set IBCusername = replace (IBCusername, 'Q', 'INH')
	where IBCUsername like '%Q%'
	
	IF @@ROWCOUNT < 2000
		BREAK
END

--mansion88
WHILE (1=1)
BEGIN
	UPDATE TOP(2000) Mansion88_Customer WITH (ROWLOCK, UPDLOCK)
	set IBCusername = replace (IBCusername, 'Q', 'INH')
	where IBCUsername like '%Q%'
	
	IF @@ROWCOUNT < 2000
		BREAK
END	
---
--bodb_licensee
update licenseeCust set currencyname = 'INH' where Currency =51 