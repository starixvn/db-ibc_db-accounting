/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,wsv_xnap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdTransferOption]
    @CustId INT,
    @TransferOption VARCHAR(8),
    @TurnOffAutoTransfer BIT,
    @UserID INT = 0,
    @IP VARCHAR(15) = '',
    @SubAccID INT = 0, --Sub-AccountID
    @Language VARCHAR(2) = 'E',
    @ReturnErrCode BIT = 0,        
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: 
Task : Update transfer option.
DB: DBTXN/CustDB
Original: 

Revisions:
    - 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
    - 20090828@HuyNguyen: replace [Customer] --> [OtherCust]                
	- 20090402@Phuc: write log into DBLog.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20100413@Kiwi: Move to Update transferoption to CustSuper/CustMaster/CustAgent
	- 20101021@Henry: Record execution time
	- 20110603@Amy: Write log Old value
    - 20110907@Lukas: Change linked-server from DB052 -> DB053
    - 20130208@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
						Write more log on DBTXN server in case of DBLOG server failure
    - 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB, Change Age_CustomerSelCheckBelonging -> Age_CustomerSelCheckBelongingByCustID) [Redmine:#36216]
    - 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
    - 20231102@Luke: Alpha - Enhance auto transfer function (phase 2) [Redmine: #195135]
	- 20240919@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]                           
Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON

    declare @startRun datetime
    declare @endRun datetime
    declare @duration int
    set @startRun = getdate()

    DECLARE @Old_TransferOption TINYINT

    --------------------------
    -- ***Check Downline Belonging***
    DECLARE @roleid TINYINT
    EXEC dbo.Age_CustomerSelCheckBelongingByCustID 
    @SessionCustID = @UserID, 
    @Custid = @CustId,
    @roleid = @roleid OUTPUT
    IF (@roleid = 0) RETURN
    ---------------------------
    
	--Check disable user
    EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
    IF @ErrCode <>0 RETURN
    --end

    DECLARE @TransferOption_dec TINYINT

    SELECT @roleid = roleid FROM custinfo WITH (NOLOCK) WHERE custid = @custid
    SELECT @TransferOption_dec = dbo.F_Binary_Decimal(@TransferOption)
    /*
    --update himself:
    IF (@roleid = 4 AND @Custid >= 100)--normal super
            OR
            (@roleid = 3)--master
            OR
            (
                    --(@roleid = 2 AND exists(select 1 from customer with (nolock) where custid = @custid and srecommend < 100))--agent of direct master
                    --OR
                    (EXISTS(SELECT 1 FROM customer WITH (NOLOCK) WHERE transferoption = 0 AND custid = (SELECT mrecommend FROM customer WITH (NOLOCK) WHERE custid = @custid))) --master of the agent is allowed to transfer all day 
            )
                    UPDATE customer SET transferoption = @TransferOption_dec WHERE custid = @CustId
    */
        
    CREATE TABLE #tmpCustAutoTransfer(FromCustID INT, ToCustID INT, Old_ScheduleOption_Numeric TINYINT, New_ScheduleOption_Numeric TINYINT, isFinished BIT DEFAULT(0), PRIMARY KEY (FromCustID, ToCustID))

    --update downline: 
    IF (@roleid = 4) AND (@Custid >= 100)--normal super
    BEGIN        
        SELECT @Old_TransferOption = TransferOption FROM CustSuper WITH (nolock) WHERE custid= @custid
                
        IF @Old_TransferOption = @TransferOption_dec
		BEGIN
			SELECT FromCustID AS CustId, NULL AS UserName, NULL AS Downlines, NULL AS Names
			FROM #tmpCustAutoTransfer

			SELECT @ErrCode = 101,
				@ErrMsg	= CASE WHEN @Language = 'E' THEN 'There is no change of Transfer Condition to update.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](50034,@Language) 
								END
			RETURN
		END
        --Update Super himself
        UPDATE CustSuper WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid = @custid
                
        --Update Master Level
        UPDATE CustMaster WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE srecommend = @custid AND roleid = 3)

        --Update Agent Level
        UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE srecommend = @custid AND roleid = 2)        
                
        IF @TransferOption_dec <> 0
        --Get auto transfer downline list 
        BEGIN
            INSERT INTO #tmpCustAutoTransfer(FromCustID, ToCustID, Old_ScheduleOption_Numeric)
            SELECT a.FromCustID, a.ToCustID, a.ScheduleOption
            FROM Age_ClearBalanceCust_Setting a WITH (NOLOCK)
                INNER JOIN custinfo c WITH (NOLOCK) ON a.FromCustID = c.custid
            WHERE c.srecommend = @CustId 
                AND c.roleid IN (2,3) --Keep auto transfer to Master unchanged
        END
    END
    ELSE IF (@roleid = 3) --master
    BEGIN
        select @Old_TransferOption = TransferOption from CustMaster with (nolock) where custid= @custid
                
        IF @Old_TransferOption = @TransferOption_dec		
		BEGIN
			SELECT FromCustID AS CustId, NULL AS UserName, NULL AS Downlines, NULL AS Names
			FROM #tmpCustAutoTransfer

			SELECT @ErrCode = 101,
				@ErrMsg	= CASE WHEN @Language = 'E' THEN 'There is no change of Transfer Condition to update.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](50034,@Language) 
								END
			RETURN
		END
        --Update Master himself
        UPDATE CustMaster WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid = @custid

        --Update Agent Level
        UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid IN (SELECT custid FROM custinfo (NOLOCK) WHERE mrecommend = @custid AND roleid = 2)
                
        IF @TransferOption_dec <> 0
        --Get auto transfer downline list
        BEGIN
            INSERT INTO #tmpCustAutoTransfer(FromCustID, ToCustID, Old_ScheduleOption_Numeric)
            SELECT a.FromCustID, a.ToCustID, a.ScheduleOption
            FROM Age_ClearBalanceCust_Setting a WITH (NOLOCK)
                INNER JOIN custinfo c WITH (NOLOCK) ON a.FromCustID = c.custid
            WHERE c.mrecommend = @CustId 
                AND c.roleid IN (2,3)
        END
    END
    -- master of the agent is allowed to transfer all day 
    ELSE IF (EXISTS(SELECT 1 FROM CustMaster WITH (NOLOCK) WHERE TransferOption = 0 AND custid = (SELECT mrecommend FROM custinfo WITH (NOLOCK) WHERE custid = @custid)))
    BEGIN
        select @Old_TransferOption = TransferOption from CustAgent with (nolock) where custid= @custid
                
        IF @Old_TransferOption = @TransferOption_dec 
		BEGIN
			SELECT FromCustID AS CustId, NULL AS UserName, NULL AS Downlines, NULL AS Names
			FROM #tmpCustAutoTransfer

			SELECT @ErrCode = 101,
				@ErrMsg	= CASE WHEN @Language = 'E' THEN 'There is no change of Transfer Condition to update.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](50034,@Language) 
								END
			RETURN
		END

        UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET TransferOption = @TransferOption_dec
        WHERE custid = @custid

        IF @TransferOption_dec <> 0
        --Get auto transfer downline list
        BEGIN
            INSERT INTO #tmpCustAutoTransfer(FromCustID, ToCustID, Old_ScheduleOption_Numeric)
            SELECT a.FromCustID, a.ToCustID, a.ScheduleOption
            FROM Age_ClearBalanceCust_Setting a WITH (NOLOCK)
                INNER JOIN custinfo c WITH (NOLOCK) ON a.FromCustID = c.custid
            WHERE c.recommend = @CustId 
                AND c.roleid IN (2)
        END
    END

	DECLARE @isAdmin BIT = 0
	IF @roleid > 4 SET @isAdmin = 1


    DECLARE @LogSPData varchar(3000)
    DECLARE @TrackingValue2 varchar(3000)

    Select @LogSPData = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
                                        'TransferOption="'+ coalesce(cast(@TransferOption as varchar(8)),space(1))+'" '+
                                        'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
                                        'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
                                        'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
                                        'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
                                        'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'
                                                
    Select @TrackingValue2 = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
                                        'TransferOption="'+ coalesce(cast(dbo.F_Decimal_Binary(@Old_TransferOption) as varchar(8)),space(1))+'" '+
                                        'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
                                        'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
                                        'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
                                        'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
                                        'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

    set @endRun = getdate()
    set @duration  = datediff (millisecond,@startRun,@endRun)

    /*700 Acc_CustomerUpdTransferOption Update Transfer Condition */
    BEGIN TRY
        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
            @UserID = @UserID,
            @CustID = @CustID,
            @ActionID = 700,
            @TrackingValue = @LogSPData,
            @TrackingValue2 = @TrackingValue2,
            @duration = @duration
    END TRY
    BEGIN CATCH
        Select @LogSPData = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
                                        'TransferOption="'+ coalesce(cast(@TransferOption as varchar(8)),space(1))+'" '+
                                        'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
                                        'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
                                        'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
                                        'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
                                        'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ ' ' + error_message() + '" />'
                                                
	    Select @TrackingValue2 = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
                                        'TransferOption="'+ coalesce(cast(dbo.F_Decimal_Binary(@Old_TransferOption) as varchar(8)),space(1))+'" '+
                                        'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
                                        'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
                                        'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
                                        'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
                                        'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
                                        'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ ' ' + error_message() + '" />'
        EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                @UserID = @UserID,
                @CustID = @CustID,
                @ActionID = 700,
                @TrackingValue = @LogSPData,
                @TrackingValue2 = @TrackingValue2,
                @duration = @duration
    END CATCH

    --TODO: Update auto transfer schedule
    IF EXISTS (SELECT TOP 1 1 FROM #tmpCustAutoTransfer)
    BEGIN
        --Get TransferOption converted to AutoTransfer format in order to compare valid day
        DECLARE @TransferOption_convert TINYINT
        SELECT @TransferOption_convert = dbo.f_TransferConditon_CharToNumeric_BaseAutoTransfer(@TransferOption)
                
        DECLARE @Logdata NVARCHAR(MAX), 
				@Logdata2 NVARCHAR(MAX)
                
        CREATE TABLE #custOffAutoTransfer(FromCustID INT, ToCustID INT, Old_ScheduleOption_Numeric TINYINT)
        CREATE TABLE #custUpdSchedule(FromCustID INT, ToCustID INT, Old_ScheduleOption_Numeric TINYINT, New_ScheduleOption_Numeric TINYINT)

        IF @TurnOffAutoTransfer = 1 --OFF Auto Transfer and clear schedule for all downlines
        BEGIN
            WHILE (1=1)
            BEGIN
                TRUNCATE TABLE #custOffAutoTransfer

                UPDATE TOP (50) t
                SET t.isFinished = 1 
                    OUTPUT inserted.FromCustID, inserted.ToCustID, inserted.Old_ScheduleOption_Numeric
                    INTO #custOffAutoTransfer(FromCustID, ToCustID, Old_ScheduleOption_Numeric)
                FROM #tmpCustAutoTransfer t
				WHERE t.isFinished = 0

                IF @@ROWCOUNT = 0 BREAK

                DELETE a 
                FROM Age_ClearBalanceCust_Setting a WITH (ROWLOCK)
                    INNER JOIN #custOffAutoTransfer t ON a.FromCustID = t.FromCustID AND a.ToCustID = t.ToCustID

                --TODO: Write log
                SET @duration = DATEDIFF(MILLISECOND, @startRun, CURRENT_TIMESTAMP)

                SELECT @Logdata = (
                        SELECT ToCustID AS '@cid'
								,CASE WHEN @roleid = 4 OR (@roleid = 3 AND @isAdmin = 0) THEN 95101
										WHEN (@roleid = 3 AND @isAdmin = 1) OR (@roleid = 2 AND @isAdmin = 0) THEN 95102
										WHEN (@roleid = 2 AND @isAdmin = 1) THEN 95103 ELSE 0 END AS '@aid'
                        FROM #custOffAutoTransfer
                        FOR XML PATH ('r')
                )

                BEGIN TRY
                    EXEC DBLOG.bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
							@UserID = @UserID,
							@LogData = @LogData,
							@SubAccID = @SubAccID,
							@Duration = @Duration,
							@Language = @Language,
							@IP = @IP,
							@ErrCode = @ErrCode,
							@ErrMsg = @ErrMsg,
							@Mode = 3                                              
                END TRY
                BEGIN CATCH
                    SELECT @ErrCode = 102
                            , @ErrMsg  = CONCAT(@ErrMsg, ERROR_NUMBER(),': ',ERROR_MESSAGE());
                    EXEC bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
                            @UserID = @UserID,
                            @LogData = @LogData,
                            @SubAccID = @SubAccID,
                            @Duration = @Duration,
                            @Language = @Language,
                            @IP = @IP,
                            @ErrCode = @ErrCode,
                            @ErrMsg = @ErrMsg,
                            @Mode = 3
                END CATCH

				SELECT @Logdata2 = (
						SELECT ToCustID AS '@cid'
										,dbo.f_AutoTransferSchedule_NumericToChar(Old_ScheduleOption_Numeric) AS '@os'
										,'' AS '@ns'
										,CASE WHEN @roleid = 4 OR (@roleid = 3 AND @isAdmin = 0) THEN 95104
														WHEN (@roleid = 3 AND @isAdmin = 1) OR (@roleid = 2 AND @isAdmin = 0) THEN 95105
														WHEN (@roleid = 2 AND @isAdmin = 1) THEN 95106 ELSE 0 END AS '@aid'
						FROM #custOffAutoTransfer
						FOR XML PATH('r')
				)

				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
							@UserID = @UserID,
							@LogData = @LogData2,
							@SubAccID = @SubAccID,
							@Duration = @Duration,
							@Language = @Language,
							@IP = @IP,
							@ErrCode = @ErrCode,
							@ErrMsg = @ErrMsg,
							@Mode =  4
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = 101
							, @ErrMsg  = CONCAT(@ErrMsg, ERROR_NUMBER(),': ',ERROR_MESSAGE());
					EXEC bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
							@UserID = @UserID,
							@LogData = @LogData2,
							@SubAccID = @SubAccID,
							@Duration = @Duration,
							@Language = @Language,
							@IP = @IP,
							@ErrCode = @ErrCode,
							@ErrMsg = @ErrMsg,
							@Mode = 4
				END CATCH
            END        
        END
        ELSE --Keep Auto Transfer ON and retain current valid auto transfer schedule for all downlines
        BEGIN
            UPDATE t 
            SET t.New_ScheduleOption_Numeric = t.Old_ScheduleOption_Numeric & @TransferOption_convert 
            FROM #tmpCustAutoTransfer t 

            IF EXISTS(
				SELECT TOP (1) 1 
				FROM #tmpCustAutoTransfer 
				WHERE New_ScheduleOption_Numeric > 0 
					AND Old_ScheduleOption_Numeric <> New_ScheduleOption_Numeric
			)        
            BEGIN	--At least 1 valid day: update auto transfer schedule
                WHILE (1=1)
				BEGIN
					TRUNCATE TABLE #custUpdSchedule
                                        
					UPDATE TOP (50) t
					SET t.isFinished = 1 
							OUTPUT inserted.FromCustID, inserted.ToCustID, inserted.Old_ScheduleOption_Numeric, inserted.New_ScheduleOption_Numeric
							INTO #custUpdSchedule(FromCustID, ToCustID, Old_ScheduleOption_Numeric, New_ScheduleOption_Numeric)                        
					FROM #tmpCustAutoTransfer t
					WHERE New_ScheduleOption_Numeric > 0
						AND Old_ScheduleOption_Numeric <> New_ScheduleOption_Numeric
						AND t.isFinished = 0

					IF @@ROWCOUNT = 0 BREAK

					UPDATE a 
					SET a.ScheduleOption = t.New_ScheduleOption_Numeric
					FROM Age_ClearBalanceCust_Setting a WITH (ROWLOCK, UPDLOCK)
							INNER JOIN #custUpdSchedule t ON a.FromCustID = t.FromCustID AND a.ToCustID = t.ToCustID

					--TODO: Write log
					SET @duration = DATEDIFF(MILLISECOND, @startRun, CURRENT_TIMESTAMP)

					SELECT @Logdata = (
							SELECT ToCustID AS '@cid'
											,dbo.f_AutoTransferSchedule_NumericToChar(Old_ScheduleOption_Numeric) AS '@os'
											,dbo.f_AutoTransferSchedule_NumericToChar(New_ScheduleOption_Numeric) AS '@ns'
											,CASE WHEN @roleid = 4 OR (@roleid = 3 AND @isAdmin = 0) THEN 95104
															WHEN (@roleid = 3 AND @isAdmin = 1) OR (@roleid = 2 AND @isAdmin = 0) THEN 95105
															WHEN (@roleid = 2 AND @isAdmin = 1) THEN 95106 ELSE 0 END AS '@aid'
							FROM #custUpdSchedule
							FOR XML PATH('r')
					)

					BEGIN TRY
						EXEC DBLOG.bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
								@UserID = @UserID,
								@LogData = @LogData,
								@SubAccID = @SubAccID,
								@Duration = @Duration,
								@Language = @Language,
								@IP = @IP,
								@ErrCode = @ErrCode,
								@ErrMsg = @ErrMsg,
								@Mode =  4
					END TRY
					BEGIN CATCH
						SELECT @ErrCode = 101
								, @ErrMsg  = CONCAT(@ErrMsg, ERROR_NUMBER(),': ',ERROR_MESSAGE());
						EXEC bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
								@UserID = @UserID,
								@LogData = @LogData,
								@SubAccID = @SubAccID,
								@Duration = @Duration,
								@Language = @Language,
								@IP = @IP,
								@ErrCode = @ErrCode,
								@ErrMsg = @ErrMsg,
								@Mode = 4
					END CATCH
				END
            END

            IF EXISTS(SELECT TOP (1) 1 FROM #tmpCustAutoTransfer WHERE New_ScheduleOption_Numeric = 0)        --No valid day remaining: turn off auto transfer and clear schedule
            BEGIN
                WHILE (1=1)
                BEGIN
                    TRUNCATE TABLE #custOffAutoTransfer

                    UPDATE TOP (50) t
                    SET t.isFinished = 1 
                        OUTPUT inserted.FromCustID, inserted.ToCustID, inserted.Old_ScheduleOption_Numeric
                        INTO #custOffAutoTransfer(FromCustID, ToCustID, Old_ScheduleOption_Numeric)                        
                    FROM #tmpCustAutoTransfer t
                    WHERE New_ScheduleOption_Numeric = 0
						AND t.isFinished = 0

                    IF @@ROWCOUNT = 0 BREAK

                    DELETE a 
                    FROM Age_ClearBalanceCust_Setting a WITH (ROWLOCK)
                        INNER JOIN #custOffAutoTransfer t ON a.FromCustID = t.FromCustID AND a.ToCustID = t.ToCustID

                    --TODO: Write log
                    SET @duration = DATEDIFF(MILLISECOND, @startRun, CURRENT_TIMESTAMP)

                    SELECT @Logdata = (
                            SELECT ToCustID AS '@cid'
                                        ,CASE WHEN @roleid = 4 OR (@roleid = 3 AND @isAdmin = 0) THEN 95101
                                                WHEN (@roleid = 3 AND @isAdmin = 1) OR (@roleid = 2 AND @isAdmin = 0) THEN 95102
                                                WHEN (@roleid = 2 AND @isAdmin = 1) THEN 95103 ELSE 0 END AS '@aid'
                            FROM #custOffAutoTransfer
                            FOR XML PATH ('r')
                    )

                    BEGIN TRY
                        EXEC DBLOG.bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
                                @UserID = @UserID,
                                @LogData = @LogData,
                                @SubAccID = @SubAccID,
                                @Duration = @Duration,
                                @Language = @Language,
                                @IP = @IP,
                                @ErrCode = @ErrCode,
                                @ErrMsg = @ErrMsg,
                                @Mode = 3
                    END TRY
                    BEGIN CATCH
                        SELECT @ErrCode = 101
                                , @ErrMsg  = CONCAT(@ErrMsg, ERROR_NUMBER(),': ',ERROR_MESSAGE());
                        EXEC bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
                                @UserID = @UserID,
                                @LogData = @LogData,
                                @SubAccID = @SubAccID,
                                @Duration = @Duration,
                                @Language = @Language,
                                @IP = @IP,
                                @ErrCode = @ErrCode,
                                @ErrMsg = @ErrMsg,
                                @Mode = 3
                    END CATCH

					SELECT @Logdata2 = (
							SELECT ToCustID AS '@cid'
											,dbo.f_AutoTransferSchedule_NumericToChar(Old_ScheduleOption_Numeric) AS '@os'
											,'' AS '@ns'
											,CASE WHEN @roleid = 4 OR (@roleid = 3 AND @isAdmin = 0) THEN 95104
															WHEN (@roleid = 3 AND @isAdmin = 1) OR (@roleid = 2 AND @isAdmin = 0) THEN 95105
															WHEN (@roleid = 2 AND @isAdmin = 1) THEN 95106 ELSE 0 END AS '@aid'
							FROM #custOffAutoTransfer
							FOR XML PATH('r')
					)

					BEGIN TRY
						EXEC DBLOG.bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
								@UserID = @UserID,
								@LogData = @LogData2,
								@SubAccID = @SubAccID,
								@Duration = @Duration,
								@Language = @Language,
								@IP = @IP,
								@ErrCode = @ErrCode,
								@ErrMsg = @ErrMsg,
								@Mode =  4
					END TRY
					BEGIN CATCH
						SELECT @ErrCode = 101
								, @ErrMsg  = CONCAT(@ErrMsg, ERROR_NUMBER(),': ',ERROR_MESSAGE());
						EXEC bodb_CustomerLog.dbo.Age_WriteLog_UserLog_RunSP_Multiple
								@UserID = @UserID,
								@LogData = @LogData2,
								@SubAccID = @SubAccID,
								@Duration = @Duration,
								@Language = @Language,
								@IP = @IP,
								@ErrCode = @ErrCode,
								@ErrMsg = @ErrMsg,
								@Mode = 4
					END CATCH
                END
            END
		END
    END

	--TODO: Return TargetInfo result set
	SELECT t.FromCustID CustId, c.username Username, STRING_AGG(t.ToCustID, ', ') Downlines, STRING_AGG(ci.username, ', ') Names
	FROM #tmpCustAutoTransfer t
		INNER JOIN custinfo c WITH (NOLOCK) ON t.FromCustID = c.custid
		INNER JOIN custinfo ci WITH (NOLOCK) ON t.ToCustID = ci.custid
	WHERE Old_ScheduleOption_Numeric <> ISNULL(New_ScheduleOption_Numeric,0)
	GROUP BY t.FromCustID, c.username
END
GO