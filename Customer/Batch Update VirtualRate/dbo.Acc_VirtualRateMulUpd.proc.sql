ALTER PROCEDURE [dbo].[Acc_VirtualRateMulUpd]
    @UserID INT ,
    @IP VARCHAR(20) ,
    @FileName VARCHAR(20) ,
    @FileSize INT ,
    @Index INT ,
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS /*
	Created: 
	Task : Update new multi virtual rates for username
	DB: DBTXN/bodb02
	Original: 
	Revisions:	
		- 20090812@Simon: Update new multi virtual rates for username
		- 20090910@Jamie: Only update 500 users once 
		- 20090915@Simon: Only update max 500 users once exec this SP
		- 20090917@Phuc: Write log to dblog		
		- 20091116@Daniel: Change to check permission on dedicated function [UploadVR]
		- 20100107@Lewin: Modify @LogSPData, call new writelog function
		- 20101021@Henry: Record execution time
		- 20130224@Lukas: move table Acc_CustVirtualRate to new database bodb_ACC
						& change linked-server from db03 to DBPOLICY
*/
BEGIN
    SET NOCOUNT ON		
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

--Check permission for account site
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID,
        @funcname = '[UploadVR]', @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
	
    DECLARE @tmpStatus TABLE
        (
          custid INT PRIMARY KEY ,
          username VARCHAR(20) ,
          rate SMALLMONEY
        )

    DECLARE @FromRow INT ,
        @ToRow INT
    SET @FromRow = ( @Index - 1 ) * 500 + 1
    SET @ToRow = @Index * 500

    INSERT  INTO @tmpStatus
            ( custid ,
              username ,
              rate
            )
            SELECT  custid ,
                    username ,
                    1 + virtualrate
            FROM    ( SELECT    ROW_NUMBER() OVER ( ORDER BY v.USERID, v.USERNAME ) IndexRow ,
                                ci.custid ,
                                v.username ,
                                v.virtualrate
                      FROM      custinfo ci WITH ( NOLOCK )
                                INNER JOIN DBACC.bodb_acc.dbo.Acc_CustVirtualRate v
                                WITH ( NOLOCK ) ON ci.username = v.username
                                                   AND v.userID = @UserID
                    ) Tmp
            WHERE   IndexRow BETWEEN @FromRow AND @ToRow
				
    UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
    SET     virtualmultiplier = s.rate
    FROM    @tmpStatus s
    WHERE   custinfo.custid = s.custid 


	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

    IF @@ERROR <> 0 
    BEGIN
        SELECT  @ErrMsg = 'Update process is unsuccessful. Only updated successfully '
                + CONVERT(VARCHAR(8), @FromRow - 1)
                + ' first rows in list!' ,
                @ErrCode = 103

/*803	Acc_VirtualRateMulUpd_Sum	Sum up users when updating new multi virtual rates*/
        INSERT  INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP
                ( UserID,
                  CustID,
                  TrackingValue,
                  ActionId,
                  duration
                )
        SELECT  @UserID,
                -( @FromRow - 1 ),
                '<Acc_VirtualRateMulUpd_Sum IP="'
                + @IP + '" FileName="' + @FileName
                + '" FileSize="'
                + CONVERT(VARCHAR(20), @FileSize)
                + '" ErrMsg="' + @ErrMsg + '" />',
                803,
                @duration
        RETURN
    END

-- Write Log
/*802	Acc_VirtualRateMulUpd	Update new multi virtual rates*/
	INSERT  INTO DBLOG.bodb_CustomerLog.dbo.UserLog_RunSP
			( UserID,
			  CustID,
			  TrackingValue,
			  ActionID,
			  Duration
			)
    SELECT  @UserID,
            CustID,
            '<Acc_VirtualRateMulUpd Rate="'
            + CONVERT(VARCHAR(8), rate) + '" UserName="'
            + username + '" IP="' + @IP + '" FileName="'
            + @FileName + '" Size="'
            + CONVERT(VARCHAR(20), @FileSize) + '" />',
            802,
            @duration
    FROM    @tmpStatus 

    DECLARE @TotalUsers INT
    SELECT  @TotalUsers = COUNT(username)
    FROM    DBACC.bodb_acc.dbo.Acc_CustVirtualRate WITH ( NOLOCK )
    WHERE   userID = @UserID

-- Insert Last Log Row
    IF (@Index * 500 >= @TotalUsers) 
    BEGIN
		set @endRun = getdate()
		set @duration  = datediff (millisecond,@startRun,@endRun)
    
/*803	Acc_VirtualRateMulUpd_Sum	Sum up users when updating new multi virtual rates*/
        
         
         DECLARE @LogData NVARCHAR(200)  
         SET @LogData = '<Acc_VirtualRateMulUpd_Sum TotalUser="'
                + CONVERT(VARCHAR(20), @TotalUsers) + '" IP="'
                + @IP + '" FileName="' + @FileName
                + '" Size="' + CONVERT(VARCHAR(20), @FileSize) + '" />'
         
         SET @TotalUsers = -1 * @TotalUsers
         
         EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
         @UserID = @UserID,
         @CustID = @TotalUsers,
         @ActionID = 803,
         @TrackingValue = @LogData,
         @duration = @duration
         
         
                
    END				
END
	
GO
GRANT EXECUTE ON [dbo].[Acc_VirtualRateMulUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_VirtualRateMulUpd] TO [vnteam]
