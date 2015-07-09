ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @srecommend int
AS
--This SP is reserved for DBA (Thien)'s usage
/*
- Scope: affect all 12Bet members under all currencies
- Details:
        + Set PT value 83% at Agent level (I.e. PT for House will be 17%)
        + Update for all Sportsbooks' sports.
        + NO touch the setting of 3rd-party products like Horse Racing, Financial Betting and Casino.
*/
--1015419,1015427,791081,836212,1813575,836218,836226,1752415,836203,791080,916498
if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
BEGIN
    RETURN
END

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
    RETURN
END

Declare  @ptVALUE smallmoney
SELECT @ptVALUE = 0.83

--Update Member
UPDATE CustSetting
SET apositiontaking = @ptVALUE,
    alivepositiontaking = case when sporttype = 1 and bettype IN(1,3,7,8) then @ptVALUE else 0 end       
WHERE CustID in (select custid from custinfo with (nolock) where srecommend = @srecommend and roleid=1)

/*
Exec Acc_ExecRep_09 1015419
GO
Exec Acc_ExecRep_09 1015427
GO
Exec Acc_ExecRep_09 791081
GO
Exec Acc_ExecRep_09 836212
GO
Exec Acc_ExecRep_09 1813575
GO
Exec Acc_ExecRep_09 836218
GO
Exec Acc_ExecRep_09 836226
GO
Exec Acc_ExecRep_09 1752415
GO
Exec Acc_ExecRep_09 836203
GO
Exec Acc_ExecRep_09 791080
GO
Exec Acc_ExecRep_09 916498
*/
/*
--Verify data
select c.username, cs.* from custsetting cs with (nolock)
	inner join custinfo c with (nolock) on cs.custid = c.custid
where bettype = 1 and sporttype = 1
	and cs.custid in (select custid from custinfo with (nolock)
				where srecommend in (1015419,1015427,791081,836212,1813575,836218,836226,1752415,836203,791080,916498) and roleid = 1)
	and (apositiontaking > 0 or mpositiontaking >0 or spositiontaking >0)
*/