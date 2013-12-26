ALTER PROCEDURE [dbo].[Acc_CustomerUpdVirtualMultiplier]   
    @custid int,  
    @virtualmultiplier smallmoney,  
    @UserID int,  
    @IP varchar(15) = '',  
    @IsLicenseeUser bit = 0,  
    @ErrCode int = 0 OUTPUT,  
    @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
/*  
Created:   
Task : Update virtualmultiplier.  
DB: DBTXN/CustDB
Original:  
  
Revisions:  
    - 20090917@Phuc: Write log into dblog.  
    - 20091008@Kiwi: Remove WriteLog_UserLog  
    - 20100107@Lewin: Change LogSPData format, write log by new function  
    - 20101021@Henry: Record execution time  
    - 20110907@Sophia: Change Linked Server from DB052 to DB053  
    - 20110914@Henry: Allow Licensee user to change Virtual-rate when turn on/off BA  
    - 20121126@Lukas: do not allow run this function during peak hour at weekend  
    - 20121126@Thien: revise Lukas's version, to put restriction in all days with different limitation  
    - 20121126@Thien: revise again, to put into ExecRep (Acc_ExecRep_04)  
    - 20121206@Scott : Check Allowed downlines during peak hour at weekend  
    - 20120306@Lukas: change linked-server alias  
    - 20131108@Elodie: Splitting bodb02 into CustDB (call Acc_ExecRep_Cust_04 instead of Acc_ExecRep_04)
    
Param's Explanation:  
• @ErrCode:  
    = 0: update successfully.  
    > 0: Specific Error.  
    
• @ErrMsg: Error description.  
*/  
  
SET NOCOUNT ON  
  
declare @startRun datetime  
declare @endRun datetime  
declare @duration int  
set @startRun = getdate()  
  
IF @IsLicenseeUser = 0 --accounting admin (licensee user will be ignored from this check)  
BEGIN  
    --Check permission for account site: @phuc20080213  
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[VirtualRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
    If @ErrCode <> 0  
        RETURN  
END  
  
--end  
  
--Check disable user  
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
if @ErrCode <>0 return  
--end  
  
declare @roleid tinyint,  
        @OldValue smallmoney  
  
select @OldValue = virtualmultiplier, @roleid = roleid from custinfo with (nolock) where custid = @custid  
select @virtualmultiplier = round(@virtualmultiplier, 2)  
  
  
  
--Check Allowed downlines during peak hour at weekend      
EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckAllowedDownlines    @custid=@custid,  
                                    @roleid=@roleid,  
                                    @isExecRep=1,  
                                    @Language='E',  
                                    @ErrMsg=@ErrMsg output,  
                                    @ErrCode=@ErrCode output  
IF @ErrCode <>0 RETURN  
  
--END      
  
  
if @virtualmultiplier > 1.6 or @virtualmultiplier < 0.2  
BEGIN  
    select @ErrMsg    = N'Invalid virtual rate.', @ErrCode = 101  
    return  
END  
/*  
IF @currency <> 20 AND @UserID not IN (  
        1274,    --steven  
        2433,    --WAN  
        44919,    --WONG  
        55421,    --MELVIN  
        25520,    --joe  
        360418    --dbaThien  
)  
BEGIN  
    select @ErrMsg    = N'You are not authorized to edit this value.', @ErrCode = 102  
    return  
END  
*/  
  
  
EXEC dbo.Acc_ExecRep_Cust_04   
        @custid = @custid,  
        @roleid = @roleid,  
        @action = 'VirtualMultiplier',  
        @virtualmultiplier = @virtualmultiplier  
  
Declare @LogSPData varchar(2000)  
Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
                    'NewValue="'+ cast(@virtualmultiplier as varchar(50))+ '" ' +  
                    'OldValue="'+ cast(@OldValue as varchar(50))+ '" ' +  
                    'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
                    'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
                    'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+  
                    'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
  
set @endRun = getdate()  
set @duration  = datediff (millisecond,@startRun,@endRun)  
  
IF @IsLicenseeUser=0  --For accounting admin  
BEGIN  
    /*801 Acc_CustomerUpdVirtualMultiplier Update Virtual Rate */  
    BEGIN TRY  
        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
            @UserID = @UserID,  
            @CustID = @CustID,  
            @ActionID = 801,  
            @TrackingValue = @LogSPData,  
            @duration = @duration  
    END TRY  
    BEGIN CATCH  
        Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
                    'NewValue="'+ cast(@virtualmultiplier as varchar(50))+ '" ' +  
                    'OldValue="'+ cast(@OldValue as varchar(50))+ '" ' +  
                    'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
                    'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
                    'ErrMsg="'+ cast(ERROR_MESSAGE() as varchar(50)) + '" '+  
                    'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
                      
        EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
            @UserID = @UserID,  
            @CustID = @CustID,  
            @ActionID = 801,  
            @TrackingValue = @LogSPData,  
            @duration = @duration  
    END CATCH  
END  
ELSE -- For Licensee user  
BEGIN  
    BEGIN TRY  
        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
            @UserID = @UserID,  
            @CustID = @CustID,  
            @ActionID = 2800,  
            @TrackingValue = @LogSPData,  
            @duration = @duration  
    END TRY  
    BEGIN CATCH  
        Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
                    'NewValue="'+ cast(@virtualmultiplier as varchar(50))+ '" ' +  
                    'OldValue="'+ cast(@OldValue as varchar(50))+ '" ' +  
                    'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
                    'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
                    'ErrMsg="'+ cast(ERROR_MESSAGE() as varchar(50)) + '" '+  
                    'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
        EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
            @UserID = @UserID,  
            @CustID = @CustID,  
            @ActionID = 2800,  
            @TrackingValue = @LogSPData,  
            @duration = @duration  
    END CATCH  
END  
  

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [bodbadminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [vnteam] AS [dbo]