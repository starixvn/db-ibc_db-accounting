--==============================================================================
--SCRIPT TO DISABLE FINANCE ALL ACCOUNTS & ENABLE FINANCE FOR SOME TEST ACCOUNTS
--==============================================================================
 ------------------------------------------------------------------------------
--update custinfo disable Finance for all accounts
------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1 and 100000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 100001 and 200000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 200001 and 300000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 300001 and 400000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 400001 and 500000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 500001 and 600000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 600001 and 700000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 700001 and 800000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 800001 and 900000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 900001 and 1000000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1000001 and 1100000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1100001 and 1200000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1200001 and 1300000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1300001 and 1400000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------
update custinfo set DisableFinancial = 1 where custid between 1400001 and 1500000
WAITFOR DELAY '000:00:01'

--------------------------------------------------------------------------------------------------------------------------------

--=======================================================================================================================

------------------------------------------------------------------------------
--update custinfo Enable Finance for some accounts
------------------------------------------------------------------------------
--update upline:
update custinfo set DisableFinancial = 0
where custid IN(select srecommend from custinfo with (nolock) where username IN(
	'ahrh2',
	'ahrh3',
	'ahrh5',
	'ahrs1',
	'ahrs4',
	'ahrs5',
	'ahru1',
	'ahru2',
	'ahru3',
	'ahru4'
	)
)

update custinfo set DisableFinancial = 0
where custid IN(select mrecommend from custinfo with (nolock) where username IN(
	'ahrh2',
	'ahrh3',
	'ahrh5',
	'ahrs1',
	'ahrs4',
	'ahrs5',
	'ahru1',
	'ahru2',
	'ahru3',
	'ahru4'
	)
)

update custinfo set DisableFinancial = 0
where custid IN(select recommend from custinfo with (nolock) where username IN(
	'ahrh2',
	'ahrh3',
	'ahrh5',
	'ahrs1',
	'ahrs4',
	'ahrs5',
	'ahru1',
	'ahru2',
	'ahru3',
	'ahru4'
	)
)


--update specified members
update custinfo set DisableFinancial = 0
where username IN(
	'ahrh2',
	'ahrh3',
	'ahrh5',
	'ahrs1',
	'ahrs4',
	'ahrs5',
	'ahru1',
	'ahru2',
	'ahru3',
	'ahru4'
	)
	
update custinfo set DisableFinancial = 0 where srecommend in (20, 1338545)