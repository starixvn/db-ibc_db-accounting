USE [bodb02]

/****** Object:  StoredProcedure [dbo].[ExecRep_07]    Script Date: 04/08/2009 00:09:22 ******/
SET ANSI_NULLS ON

SET QUOTED_IDENTIFIER ON


ALTER PROCEDURE [dbo].[ExecRep_07]	

AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

if NOT exists (select * from dbo.sysobjects where name = 'custoverride')
BEGIN
	RETURN
END


update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1 and 100000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 100001 and 200000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 200001 and 300000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 300001 and 400000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 400001 and 500000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 500001 and 600000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 600001 and 700000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 700001 and 800000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 800001 and 900000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 900001 and 1000000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1000001 and 1100000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1100001 and 1200000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1200001 and 1300000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1300001 and 1400000

WAITFOR DELAY '000:00:3'

update custsetting set	
    apositiontaking=0,
    mpositiontaking=0,
    spositiontaking=0,
    alivepositiontaking=0,
    mlivepositiontaking=0,
    slivepositiontaking=0,
    autopositiontaking=0,
    autolivepositiontaking=0,
    isautopositiontaking=0,
    isautolivepositiontaking=0,
    minbet=0,
    maxbet=0,
	sdiscount = 0,
	playerdiscount = 0, 
	discount =0 ,
	adiscount=0,	
	groupa = 0,
	groupb = 0,
	groupc = 0,
	groupd = 0,
	groupe = 0,
	groupf = 0
where sporttype = 201 and bettype = 3 and custid between 1400001 and 1500000


-----------------
------------------------------------------------------------------------------
--Update CustOverride
------------------------------------------------------------------------------

-----------------
------------------------------------------------------------------------------
--Update CustOverride
------------------------------------------------------------------------------

update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1 and 100000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 100001 and 200000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 200001 and 300000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 300001 and 400000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 400001 and 500000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 500001 and 600000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 600001 and 700000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 700001 and 800000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 800001 and 900000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 900001 and 1000000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1000001 and 1100000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1100001 and 1200000

WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1200001 and 1300000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1300001 and 1400000
WAITFOR DELAY '000:00:3'

--------------------------------------------------------------------------------------------------------------------------------
update custoverride set 
	minpositiontaking = 0, 
	maxpositiontaking = 0, 
	minlivepositiontaking = 0, 
	maxlivepositiontaking = 0
where sporttype = 201 and bettype = 3 and custid between 1400001 and 1500000

--------------------------

--Maxpermatch
update custinfo set	
	maxpermatch201 = 0
where custid between 1 and 100000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 100001 and 200000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 200001 and 300000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 300001 and 400000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 400001 and 500000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 500001 and 600000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 600001 and 700000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 700001 and 800000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 800001 and 900000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 900001 and 1000000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 1000001 and 1100000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 1100001 and 1200000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 1200001 and 1300000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 1300001 and 1400000

WAITFOR DELAY '000:00:3'

update custinfo set	
	maxpermatch201 = 0
where custid between 1400001 and 1500000