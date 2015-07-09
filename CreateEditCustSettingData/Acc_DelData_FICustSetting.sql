ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

--Pay attention to deploy Aff_CustomerInsAffiliate_1 and Dot_Dep_CustomerInsMember_Ag

if NOT exists (select * from dbo.sysobjects where name = 'CustSetting3rd')
BEGIN
	RETURN
END

--select max(custid) from customer with (nolock)
--122569

delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 1 and 100000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 100001 and 200000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 200001 and 300000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 300001 and 400000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 400001 and 500000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 500001 and 600000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 600001 and 700000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 700001 and 800000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 800001 and 900000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 900001 and 1000000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 1000001 and 1100000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 1100001 and 1200000
WAITFOR DELAY '000:00:10'

--------------------------------------------------------------------------------------------------------------------------------
delete CustSetting3rd where  sporttype = 201 and bettype = 3 and custid between 1200001 and 1300000
WAITFOR DELAY '000:00:10'


GO