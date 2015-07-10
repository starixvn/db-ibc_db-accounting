
DECLARE @customers TABLE (custid INT, roleid INT)
INSERT INTO @customers
		SELECT custid, roleid
		FROM customer WITH(NOLOCK)
		WHERE srecommend IN (
								835299,    --- S51R
								406808,   --- TAS51S
								1349148,  --- S51H
								695131    --- S51SM
							)

DECLARE @sdiscount DECIMAL(9,8),
		@adiscount DECIMAL(9,8),
		@discount DECIMAL(9,8),
		@playerdiscount DECIMAL(9,8)

------  pass all comm to his master
SELECT	@sdiscount = 0.007,
		@adiscount = 0.007,
		@discount = 0,
		@playerdiscount = 0

-----  pass all comm to his downline
--SELECT	@sdiscount = 0.007,
--		@adiscount = 0.007,
--		@discount = 0.007,
--		@playerdiscount = 0.007

UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET sdiscount = @sdiscount
WHERE custid IN (835299,406808,1349148,695131)  ---- super
	AND sporttype = 162 AND bettype = 1101

WAITFOR DELAY '00:00:01'

UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET adiscount = @adiscount
WHERE custid IN (SELECT custid FROM @customers WHERE roleid = 3)  --- master
	AND sporttype = 162 AND bettype = 1101

WAITFOR DELAY '00:00:01'

UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET discount = @discount
WHERE custid IN (SELECT custid FROM @customers WHERE roleid = 2) --- agent
	AND sporttype = 162 AND bettype = 1101

WAITFOR DELAY '00:00:01'

UPDATE custsettingGame WITH(ROWLOCK,UPDLOCK)
SET sdiscount = @sdiscount,
	adiscount = @adiscount,
	discount  = @discount,
	playerdiscount = @playerdiscount
WHERE custid IN (SELECT custid FROM @customers WHERE roleid = 1)	--- member
	AND sporttype = 162 AND bettype = 1101




