ALTER PROCEDURE [dbo].[ExecRep_07]	
AS

if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
	RETURN
END

DECLARE @Count int, @MaxCustID int, @Step int

select @MaxCustID = 1600000,
        @Count = 0,
        @Step = 1000 

DELETE from custSetting where bettype in (41,42) and sporttype = 151 

DELETE from custoverride where bettype in (41,42,31,32) and sporttype = 151

WHILE 1 + @Step*@count < @MaxCustID
BEGIN
  
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
    where bettype in (31,32) and sporttype = 151 and custid between 1 + @Step*@count and @Step*(@count + 1)
    
    INSERT INTO CustOverride
           (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    select  custid, bettype + 30, 151, 0, 0.5, 0, 0
    from CustOverride cs with (nolock)
    where bettype in (1,2) and sporttype = 1 and custid between 1 + @Step*@count and @Step*(@count + 1)
    
    INSERT INTO CustOverride
           (custid, bettype, sporttype, minpositiontaking, maxpositiontaking, minlivepositiontaking, maxlivepositiontaking)
    select  custid, bettype + 40, 151, 0, 0.5, 0, 0
    from CustOverride cs with (nolock)
    where bettype in (1,2) and sporttype = 1 and custid between 1 + @Step*@count and @Step*(@count + 1)
             
    /*
    DELETE from custSetting where bettype in (41,42) and sporttype = 151 and custid between 1 + @Step*@count and @Step*(@count + 1)

    DELETE from custoverride where bettype in (41,42) and sporttype = 151 and custid between 1 + @Step*@count and @Step*(@count + 1)
    */
    
    select @count = @count + 1    
END


GO