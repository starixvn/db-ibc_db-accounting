USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdDisableP2P]    Script Date: 12/13/2012 02:19:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdDisableP2P    Script Date: 7/17/2012 3:31:22 PM ******/
 ALTER PROCEDURE [dbo].[Acc_CustomerUpdDisableP2P]
	@custid int,
	@disablep2p bit,
	@disablefunp2p bit,
	@disablep2pdownlines bit = true, --Disable all downline for P2P
	@disablefunp2pdownlines bit = true, --Disable all downline play for fun P2P
	@SubAccID int = 0,
	@UserID int,
	@language varchar(2) = 'E',
	@errcode int = 0 OUTPUT,
	@errmsg nvarchar(200) = '' OUTPUT,
	@ip varchar(15)=''
AS
/*
Created: 20110727@TOM
Task : Update P2P Game status for customer
DB: DBTRANS.bodb02
Original:

Revisions:
	- 20120405@Johnson: correct tracking log
	- 20121213@Dan: correct linked server from DB052 --> DB053 
Param's Explanation:
• @custid: customer id.
• @DisableNumber: status
*/

SET NOCOUNT OFF
DECLARE @startrun DATETIME, @duration INT
SET @startrun = GETDATE()

EXEC DB053.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @errcode=@errcode OUTPUT,@errmsg=@errmsg OUTPUT
IF @errcode <>0 RETURN

DECLARE @uplinedisablep2p BIT, @old_disablep2p BIT ,
		@uplinedisablefunp2p BIT, @old_disablefunp2p BIT ,
		@roleid TINYINT , @bdisablep2p BIT , @bdisablefunp2p BIT 

SELECT	@roleid = roleid, 
		@old_disablep2p = ISNULL(DisableP2P,0),
		@old_disablefunp2p = ISNULL(DisableFUNP2P,0) 
FROM custInfo WITH (NOLOCK) 
WHERE custId = @custid

IF @roleid NOT IN (1,2,3,4)
BEGIN
	SELECT @errmsg = CASE @language 
						WHEN 'E' THEN 'Invalid user!'
						WHEN 'CS' THEN N'账号无效!'
						WHEN 'CT' THEN N'帳號無效.!'
						WHEN 'TH' THEN N'ผู้ใช้ไม่ถูกต้อง!'
						WHEN 'J' THEN N'Invalid user!'
						WHEN 'KO' THEN N'잘못된 사용자 입니다.'
						ELSE N'Invalid user!'
					END, @ErrCode = 400	
	RETURN
END

IF (@old_disablep2p = @disablep2p)
	SET @bdisablep2p = 0
ELSE
	SET @bdisablep2p = 1

IF (@old_disablefunp2p = @disablefunp2p)
	SET @bdisablefunp2p = 0
ELSE
	SET @bdisablefunp2p = 1

IF (@bdisablep2p = 0 AND @bdisablefunp2p = 0) RETURN

IF @disablep2p = 0 OR @disablefunp2p = 0
BEGIN			
	IF @roleid = 4 
		SELECT @uplinedisablep2p = 0 , @uplinedisablefunp2p = 0
	ELSE IF @roleid = 3
		SELECT @uplinedisablep2p = ISNULL(DisableP2P,0) ,
				@uplinedisablefunp2p = ISNULL(DisableFUNP2P,0)
		FROM custInfo WITH (NOLOCK)
		WHERE custId = (SELECT srecommend 
						FROM custInfo WITH (NOLOCK) 
						WHERE custId = @custid)
	ELSE IF @roleid = 2
		SELECT @uplinedisablep2p = ISNULL(DisableP2P,0) ,
				@uplinedisablefunp2p = ISNULL(DisableFUNP2P,0)
		FROM custInfo WITH (NOLOCK)
		WHERE custId = (SELECT mrecommend 
						FROM custInfo WITH (NOLOCK) 
						WHERE custId = @custid)
	ELSE IF @roleid = 1
		SELECT @uplinedisablep2p = ISNULL(DisableP2P,0) ,
				@uplinedisablefunp2p = ISNULL(DisableFUNP2P,0)
		FROM custInfo WITH (NOLOCK)
		WHERE custId = (SELECT recommend 
						FROM custInfo WITH (NOLOCK) 
						WHERE custId = @custid)

	IF (@uplinedisablep2p = 1 AND @disablep2p = 0 AND @bdisablep2p = 1)
	BEGIN
		SELECT @errmsg = CASE @language
							WHEN 'E' THEN 'Account disabled for P2P Game. Unable to edit downlines.'
							WHEN 'CS' THEN N'未开启玩家对玩，因此无法对下线进行修改'
							WHEN 'CT' THEN N'未開啟玩家對玩，因此無法對下線進行修改'
							WHEN 'TH' THEN N'บัญชีได้ปิดใช้งาน P2P เกมส์, ไม่สามารถแก้ไขดาวน์ไลน์'
							WHEN 'J' THEN N'Account disabled for P2P Game. Unable to edit downlines.'
							WHEN 'KO' THEN N'계정 P2P 게임 비활성화하기.다운라인 수정 활성화하기'
							ELSE N'Account disabled for P2P Game. Unable to edit downlines.'
						END, @errcode = 401
		RETURN
	END 

	IF (@uplinedisablefunp2p = 1 AND @disablefunp2p = 0 AND @bdisablefunp2p = 1)
	BEGIN
		SELECT @errmsg = CASE @language
							WHEN 'E' THEN 'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							WHEN 'CS' THEN N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							WHEN 'CT' THEN N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							WHEN 'TH' THEN N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							WHEN 'J' THEN N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							WHEN 'KO' THEN N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
							ELSE N'Account disabled Play for Fun P2P Game. Unable to edit downlines.'
						END, @errcode = 402
		RETURN
	END 
END

UPDATE custInfo WITH (ROWLOCK, UPDLOCK) 
SET DisableP2P = @disablep2p ,
	DisableFUNP2P = @disablefunp2p
WHERE custId = @custid

IF (@@ERROR <> 0)
BEGIN
	SELECT @errmsg = CASE @Language 
						WHEN 'E' THEN 'Update process is unsuccessful.'
						WHEN 'CS' THEN 'Update process is unsuccessful.'
						WHEN 'CT' THEN 'Update process is unsuccessful.'
						WHEN 'TH' THEN 'Update process is unsuccessful.'
						WHEN 'J' THEN 'Update process is unsuccessful.'
						WHEN 'KO' THEN 'Update process is unsuccessful.'
						ELSE N'Update process is unsuccessful.'
					END	, @errcode = 403
	RETURN
END

--Check condition for update all downline for p2p
IF (@bdisablep2p = 1 AND (@disablep2p = 1 OR (@disablep2p = 0 AND @disablep2pdownlines = 0)))
BEGIN
	IF @RoleID = 4 
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableP2P = @DisableP2P 
		WHERE srecommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @errmsg = CASE @language
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @errcode = 404
			RETURN
		END
	END

	IF @RoleID = 3
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableP2P = @DisableP2P 
		WHERE mrecommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @ErrCode = 405
			RETURN
		END
	END

	IF @RoleID = 2 
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableP2P = @DisableP2P 
		WHERE recommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @ErrCode = 406
		RETURN
		END
	END
END

--Check condition for update all downline play for fun p2p
IF (@bdisablefunp2p = 1  AND (@disablefunp2p = 1 OR (@disablefunp2p = 0 AND @disablefunp2pdownlines = 0)))
BEGIN
	IF @RoleID = 4 
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableFUNP2P = @disablefunp2p
		WHERE srecommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @errmsg = CASE @language
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @errcode = 407
			RETURN
		END
	END

	IF @RoleID = 3
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableFUNP2P = @disablefunp2p
		WHERE mrecommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @ErrCode = 408
			RETURN
		END
	END

	IF @RoleID = 2 
	BEGIN
		UPDATE custInfo WITH (ROWLOCK, UPDLOCK)
		SET DisableFUNP2P = @disablefunp2p
		WHERE recommend = @CustID

		IF (@@ERROR <> 0)
		BEGIN			
			SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Update process is unsuccessful.'
							WHEN 'CS' THEN 'Update process is unsuccessful.'
							WHEN 'CT' THEN 'Update process is unsuccessful.'
							WHEN 'TH' THEN 'Update process is unsuccessful.'
							WHEN 'J' THEN 'Update process is unsuccessful.'
							WHEN 'KO' THEN 'Update process is unsuccessful.'
							ELSE N'Update process is unsuccessful.'
						END	, @ErrCode = 409
			RETURN
		END
	END
END

DECLARE @LogSPData VARCHAR(4000)

SELECT @LogSPData = '<Acc_CustomerUpdDisableP2P CustID="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" '+					
					'DisableP2P="'+ COALESCE(CAST(@DisableP2P AS VARCHAR(2)),SPACE(1)) + '" '+
					'DisableFunP2P="'+ COALESCE(CAST(@DisableFunP2P AS VARCHAR(2)),SPACE(1)) + '" '+
					'DisableP2Pdownlines="'+ COALESCE(CAST(@DisableP2Pdownlines AS VARCHAR(2)),SPACE(1)) + '" '+
					'DisableFunP2Pdownlines="'+ COALESCE(CAST(@DisableFunP2Pdownlines AS VARCHAR(2)),SPACE(1)) + '" '+
					'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + '" '+
					'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" '+
					'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1))+'" '+
					'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '+
					'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1))+'" '+
					'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'

SET @duration  = DATEDIFF (millisecond,@startRun,GETDATE())

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1132,
	@TrackingValue = @LogSPData,
	@duration = @duration