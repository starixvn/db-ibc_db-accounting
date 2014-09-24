ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableEsports]
	@custid             INT,
	@Disable            BIT,
	@DisableDownlines   BIT = 1,
	@SubAccID           INT = 0,
	@UserID             INT = 0,	
	@Language           VARCHAR(2) = 'E',
	@IP                 VARCHAR(15)= '',
	@ErrCode            INT = 0 OUTPUT,
	@ErrMsg             NVARCHAR(4000) = '' OUTPUT

AS

/*
    Created :   Logan
    Task    :   Update status of E-Sports
    DB      :   DBTXN/CustDB
    Original:

    Revisions:
    	- 20140820@Logan: Initial version [Redmine: #20792]
    Param's Explanation:
	
*/
BEGIN

    SET NOCOUNT ON

    SELECT @ErrCode = 101
         , @ErrMsg = 'Function is under maintenance.'

    RETURN
/*    
    DECLARE @startRun DATETIME
          , @endRun   DATETIME
          , @duration INT

          , @oldDisableEsports   BIT
          , @oldDisableDownlines BIT
          , @uplineStatus        BIT
          
          , @roleid TINYINT

    SET @startRun = GETDATE()

    EXEC DBAGE.bodb02.dbo.Acc_CustomerSelCheckEnable
        @custid = @custid
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0
    BEGIN
        RETURN
    END

    SELECT @roleid = roleid
      FROM custinfo WITH(NOLOCK)
     WHERE custid = @custid

    IF (@roleid IS NULL) 
    BEGIN
	    SELECT @ErrCode = 101
	         , @ErrMsg =
				 CASE @Language 
				   WHEN 'E' THEN 'Account does not exist or invalid customer account'
                   ELSE [dbo].[f_Get_MsgNamebyMsgID](40019, @Language)
				 END	
	    RETURN
    END

    --Check old & new value
    SELECT @oldDisableEsports = DisableEsports
      FROM custInfo WITH(NOLOCK)
     WHERE custid = @custid
     
    SELECT @oldDisableDownlines =
             CASE @roleid
               WHEN 4 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0)
                              FROM custInfo WITH(NOLOCK)
                             WHERE srecommend = @custid
                               AND roleid = 3
                               AND DisableEsports = 1
                           )
               WHEN 3 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0)
                              FROM custInfo WITH(NOLOCK)
                             WHERE mrecommend = @custid
                               AND roleid = 2
                               AND DisableEsports = 1
                           )
               WHEN 2 THEN (SELECT TOP 1 ISNULL(DisableEsports, 0)
                              FROM custInfo WITH(NOLOCK)
                             WHERE recommend = @custid
                               AND roleid = 1
                               AND DisableEsports = 1
                           )
               ELSE 0
             END

    IF @oldDisableEsports = @Disable
       AND @oldDisableDownlines = @DisableDownlines
    BEGIN
        RETURN
    END

    --Check upline status
    SELECT @uplineStatus =
             CASE @roleid
               WHEN 3 THEN (SELECT ISNULL(cs.DisableEsports, 0)
                              FROM custInfo cs WITH(NOLOCK)
                        INNER JOIN custInfo cm WITH(NOLOCK) ON cs.custid = cm.srecommend
                             WHERE cs.roleid = 4
                               AND cm.custid = @custid
                           )
               WHEN 2 THEN (SELECT ISNULL(cm.DisableEsports, 0)
                              FROM custInfo cm WITH(NOLOCK)
                        INNER JOIN custInfo ca WITH(NOLOCK) ON cm.custid = ca.mrecommend
                             WHERE cm.roleid = 3
                               AND ca.custid = @custid
                           )
               WHEN 1 THEN (SELECT ISNULL(ca.DisableEsports, 0)
                              FROM custInfo ca WITH(NOLOCK)
                        INNER JOIN custInfo c WITH(NOLOCK) ON ca.custid = c.recommend
                             WHERE ca.roleid = 2
                               AND c.custid = @custid
                           )
               ELSE 0
             END

    IF @uplineStatus = 1 AND @Disable = 0
    BEGIN
        SELECT @ErrCode = 102
	         , @ErrMsg = 'Can not enable this account when its upline is disabled.'
	    RETURN
    END


    IF (@roleid = 1)                                --update member
       OR (@Disable = 0 AND @DisableDownlines = 1)  --enable customer & not enable downlines
    BEGIN
        UPDATE custInfo WITH(ROWLOCK, UPDLOCK)
           SET DisableEsports = @Disable
         WHERE custid = @custid
    END
    ELSE
    --disable super, master, agent
    --enable customer & enable downlines
    BEGIN
        IF @roleid = 4
        BEGIN
            UPDATE custInfo WITH(ROWLOCK, UPDLOCK)
               SET DisableEsports = @Disable
             WHERE srecommend = @custid
        END
        ELSE IF @roleid = 3
        BEGIN
            UPDATE custInfo WITH(ROWLOCK, UPDLOCK)
               SET DisableEsports = @Disable
             WHERE mrecommend = @custid
        END
        ELSE IF @roleid = 2
        BEGIN
            UPDATE custInfo WITH(ROWLOCK, UPDLOCK)
               SET DisableEsports = @Disable
             WHERE recommend = @custid
        END
    END

    DECLARE  @LogSPData VARCHAR(8000)

    SELECT @LogSPData =
             '<Acc_CustomerUpdDisableEsports '
           + 'CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '
           + 'Disable="' + COALESCE(CAST(@Disable AS VARCHAR(2)), SPACE(1)) + '" '
           + 'DisableDownlines="' + COALESCE(CAST(@DisableDownlines AS VARCHAR(2)), SPACE(1)) + '" '
           + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
           + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
           + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
           + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
           + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" '
           + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'
     
    SET @endRun = GETDATE()
    SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

    BEGIN TRY 
	    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
		  , @CustID = @CustID
		  , @ActionID = 1150
		  , @TrackingValue = @LogSPData
		  , @duration = @duration
    END TRY

    BEGIN CATCH
	    SELECT @LogSPData = 
	             '<Acc_CustomerUpdDisableEsports '
               + 'CustID="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" '
               + 'Disable="' + COALESCE(CAST(@Disable AS VARCHAR(2)), SPACE(1)) + '" '
               + 'DisableDownlines="' + COALESCE(CAST(@DisableDownlines AS VARCHAR(2)), SPACE(1)) + '" '
               + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
               + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
               + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
               + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
               + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" '
               + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(4000)), SPACE(1)) + '" />'

	    EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID
		  , @CustID = @CustID
		  , @ActionID = 1150
		  , @TrackingValue = @LogSPData
		  , @duration = @duration
    END CATCH
*/
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableEsports] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableEsports] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDisableEsports] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDisableEsports] TO [vnteam] AS [dbo]