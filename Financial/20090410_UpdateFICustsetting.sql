ALTER PROCEDURE [dbo].[ExecRep_07]
	@custid int	
AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

Update cs1 set 
           apositiontaking = cs2.apositiontaking
           ,mpositiontaking = cs2.mpositiontaking
           ,spositiontaking = cs2.spositiontaking
           ,alivepositiontaking = cs2.alivepositiontaking
           ,mlivepositiontaking = cs2.mlivepositiontaking
           ,slivepositiontaking = cs2.slivepositiontaking
           ,playerdiscount = cs2.playerdiscount
           ,discount = cs2.discount
           ,adiscount = cs2.adiscount
           ,sdiscount = cs2.sdiscount
           ,groupa = cs2.groupa
           ,groupb = cs2.groupb
           ,groupc = cs2.groupc
           ,groupd = cs2.groupd
           ,groupe = cs2.groupe
           ,groupf = cs2.groupf
           ,minbet = cs2.minbet
           ,maxbet = cs2.maxbet
           ,autopositiontaking = cs2.autopositiontaking
           ,autolivepositiontaking = cs2.autolivepositiontaking
           ,isautopositiontaking = cs2.isautopositiontaking
           ,isautolivepositiontaking = cs2.isautolivepositiontaking
 from custsetting cs1 
    inner join custsetting cs2 with (nolock) on cs1.custid = cs2.custid and  cs2.sporttype = 2 and cs2.bettype = 1
 where cs1.sporttype = 201 and cs1.bettype in (2,3) and cs1.custid in (select custid from custinfo with (nolock) where srecommend = @custid)





GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [ITVivi]


Declare @custid int
select @custid = 20

update custsetting  set	
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
 where custsetting.sporttype = 201 and custsetting.bettype in (2,3) and custsetting.custid in (select custid from custinfo with (nolock) where srecommend = @custid)