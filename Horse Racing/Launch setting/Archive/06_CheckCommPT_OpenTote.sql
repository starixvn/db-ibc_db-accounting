 --Check PT different between SA and UK
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

--Check Min/Max bet, comm different between SA and UK

select distinct cssa.custid
from custsetting3rd cssa (nolock) inner join custsetting3rd csuk on cssa.custid = csuk.custid 
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 32 and csuk.bettype = 42
	and 
		(
			cssa.minbet <> csuk.minbet
			or cssa.maxbet <> csuk.maxbet
			or cssa.sdiscount <> csuk.sdiscount
			or cssa.adiscount <> csuk.adiscount
			or cssa.discount <> csuk.discount
			or cssa.playerdiscount <> csuk.playerdiscount
		)
union select distinct cssa.custid
from custsetting3rd cssa (nolock) inner join custsetting3rd csuk on cssa.custid = csuk.custid 
where cssa.sporttype = 151 and csuk.sporttype = 151 
	and cssa.bettype = 31 and csuk.bettype = 41
	and 
		(
			cssa.minbet <> csuk.minbet
			or cssa.maxbet <> csuk.maxbet
			or cssa.sdiscount <> csuk.sdiscount
			or cssa.adiscount <> csuk.adiscount
			or cssa.discount <> csuk.discount
			or cssa.playerdiscount <> csuk.playerdiscount
		)