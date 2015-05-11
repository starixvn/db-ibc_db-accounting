ALTER PROCEDURE [dbo].[Acc_ExecRep_09] 
AS

IF NOT EXISTS  (SELECT COUNT(*) FROM dbo.sysobjects
                WHERE name in ('custsetting3rd','custoverride3rd')
                    and xtype = 'U'
                HAVING COUNT(*) = 2)
BEGIN
    RETURN
END

--List custid
Declare @CustIDs table(custid int)
Insert into @CustIDs(custid)
select distinct cssa.custid
from custsetting3rd cssa (nolock) inner join custsetting3rd csuk on cssa.custid = csuk.custid 
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 32 and csuk.bettype = 42
	and 
		(
			cssa.apositiontaking <> csuk.apositiontaking
			or cssa.mpositiontaking <> csuk.mpositiontaking
			or cssa.spositiontaking <> csuk.spositiontaking
			or cssa.isautopositiontaking <> csuk.isautopositiontaking
			or cssa.autopositiontaking <> csuk.autopositiontaking
			or cssa.autompositiontaking <> csuk.autompositiontaking
			or cssa.isautompositiontaking <> csuk.isautompositiontaking
		)
union select distinct cssa.custid
from custsetting3rd cssa (nolock) inner join custsetting3rd csuk on cssa.custid = csuk.custid 
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 31 and csuk.bettype = 41
	and 
		(
			cssa.apositiontaking <> csuk.apositiontaking
			or cssa.mpositiontaking <> csuk.mpositiontaking
			or cssa.spositiontaking <> csuk.spositiontaking
			or cssa.isautopositiontaking <> csuk.isautopositiontaking
			or cssa.autopositiontaking <> csuk.autopositiontaking
			or cssa.autompositiontaking <> csuk.autompositiontaking
			or cssa.isautompositiontaking <> csuk.isautompositiontaking
		)

/*
--testing
delete from @CustIDs where custid in (select custid from custinfo (nolock) where srecommend =2428789)
*/

-- Update
-- Win
--CustSetting3rd
update csuk with(rowlock, updlock)
	set 
		apositiontaking = cssa.apositiontaking,
		mpositiontaking = cssa.mpositiontaking,
		spositiontaking = cssa.spositiontaking,
		isautopositiontaking = cssa.isautopositiontaking,
		autopositiontaking = cssa.autopositiontaking,
		autompositiontaking = cssa.autompositiontaking,
		isautompositiontaking = cssa.isautompositiontaking
from custsetting3rd cssa (nolock) 
	inner join custsetting3rd csuk on cssa.custid = csuk.custid
	inner join @CustIDs c on csuk.custid = c.custid
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 31 and csuk.bettype = 41
--CustOverride3rd	
update csuk with(rowlock, updlock)
	set 
		minpositiontaking = cssa.minpositiontaking,
		maxpositiontaking = cssa.maxpositiontaking
from CustOverride3rd cssa (nolock) 
	inner join CustOverride3rd csuk on cssa.custid = csuk.custid
	inner join @CustIDs c on csuk.custid = c.custid
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 31 and csuk.bettype = 41
	
-- Update
-- Place
-- CustSetting3rd
update csuk with(rowlock, updlock)
	set 
		apositiontaking = cssa.apositiontaking,
		mpositiontaking = cssa.mpositiontaking,
		spositiontaking = cssa.spositiontaking,
		isautopositiontaking = cssa.isautopositiontaking,
		autopositiontaking = cssa.autopositiontaking,
		autompositiontaking = cssa.autompositiontaking,
		isautompositiontaking = cssa.isautompositiontaking
from custsetting3rd cssa (nolock) 
	inner join custsetting3rd csuk on cssa.custid = csuk.custid 
	inner join @CustIDs c on csuk.custid = c.custid
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 32 and csuk.bettype = 42
-- CustOverride3rd
update csuk with(rowlock, updlock)
	set 
		minpositiontaking = cssa.minpositiontaking,
		maxpositiontaking = cssa.maxpositiontaking
from CustOverride3rd cssa (nolock) 
	inner join CustOverride3rd csuk on cssa.custid = csuk.custid 
	inner join @CustIDs c on csuk.custid = c.custid
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 32 and csuk.bettype = 42
