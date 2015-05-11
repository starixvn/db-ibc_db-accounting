ALTER PROCEDURE [dbo].[DBA_ExecRep_07]
	@username varchar(50)
AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

Declare @custid int, @roleid tinyint

select @custid = custid, @roleid = roleid
from custinfo with (nolock) where username = @username

if @roleid NOT in (4)
    RETURN
---------------------------------------------------------
DELETE from custSetting 
where bettype in (41,42) and sporttype = 151
    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)

DELETE from custoverride
where bettype in (31,32, 41,42) and sporttype = 151
    and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)


INSERT INTO custSetting
          (custid, bettype, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, 
          playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, 
          autolivepositiontaking, isautopositiontaking, isautolivepositiontaking
          --,autompositiontaking, autolivempositiontaking, isautompositiontaking, isautolivempositiontaking
          )
select custid, bettype + 10, sporttype, apositiontaking, mpositiontaking, spositiontaking, alivepositiontaking, mlivepositiontaking, slivepositiontaking, 
       playerdiscount, discount, adiscount, sdiscount, groupa, groupb, groupc, groupd, groupe, groupf, minbet, maxbet, autopositiontaking, 
       autolivepositiontaking, isautopositiontaking, isautolivepositiontaking
       --,autompositiontaking, autolivempositiontaking, isautompositiontaking, isautolivempositiontaking
from custsetting cs with (nolock)
where bettype in (31,32) and sporttype = 151 and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)


 INSERT INTO CustOverride
           (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    select  custid, bettype + 30, 151, 0, 0.5, 0, 0
    from CustOverride cs with (nolock)
    where bettype in (1,2) and sporttype = 1 and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
    
    INSERT INTO CustOverride
           (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    select  custid, bettype + 40, 151, 0, 0.5, 0, 0
    from CustOverride cs with (nolock)
    where bettype in (1,2) and sporttype = 1 and custid IN (select custid from custinfo with (nolock) where srecommend = @custid)
             


 GO
         
    