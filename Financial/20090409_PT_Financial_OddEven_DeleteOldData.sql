--Delete old data for financial odd/even
--Select * from custsetting (nolock) where sporttype = 201 and bettype = 2 
--Select * from custoverride (nolock) where sporttype = 201 and bettype = 2
--Select * from custsetting (nolock) where sporttype = 12 and bettype in(2,21,22)
--Select * from custoverride (nolock) where sporttype = 12 and bettype in(2,21,22)


----------------------------------------------------------------------------------------------------
-------------------------------   Delete Custsetting  ----------------------------------------------
----------------------------------------------------------------------------------------------------

Delete from [custSetting] 
WHERE custid between 1 and 100000 and sporttype in (12,201) and bettype in (2,21,22) 
WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 100001 and 200000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 200001 and 300000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 300001 and 400000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'
Delete from [custSetting] 
WHERE custid between 400001 and 500000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'
Delete from [custSetting] 
WHERE custid between 500001 and 600000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'
Delete from [custSetting] 
WHERE custid between 600001 and 700000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 700001 and 800000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 800001 and 900000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 900001 and 1000000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 1000001 and 1100000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 1100001 and 1200000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 1200001 and 1300000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 1300001 and 1400000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custSetting] 
WHERE custid between 1400001 and 1500000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'



----------------------------------------------------------------------------------------------------
-------------------------------   Delete Custoverride ----------------------------------------------
----------------------------------------------------------------------------------------------------

Delete from [custoverride] 
WHERE custid between 1 and 100000 and sporttype in (12,201) and bettype in (2,21,22)  

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 100001 and 200000  and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 200001 and 300000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 300001 and 400000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'
Delete from [custoverride] 
WHERE custid between 400001 and 500000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'
Delete from [custoverride] 
WHERE custid between 500001 and 600000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'
Delete from [custoverride] 
WHERE custid between 600001 and 700000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 700001 and 800000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 800001 and 900000 and sporttype in (12,201) and bettype in (2,21,22)

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 900001 and 1000000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 1000001 and 1100000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 1100001 and 1200000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 1200001 and 1300000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 1300001 and 1400000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'

Delete from [custoverride] 
WHERE custid between 1400001 and 1500000 and sporttype in (12,201) and bettype in (2,21,22) 

WAITFOR DELAY '000:00:3'
