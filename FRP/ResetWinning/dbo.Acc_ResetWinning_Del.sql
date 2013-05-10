 CREATE PROCEDURE [dbo].[Acc_ResetWinning_Del]
	@winlostdate	DATETIME,
	@userid		INT,
	@custid		INT = 44621,--'IBC 0506'	
	@IP			VARCHAR(15)='',
	@ErrCode	INT = 0 output,
	@ErrMsg		NVARCHAR(500) ='' output 
AS
/*	
	Creator: Johnson
	Date:	2011-01-12
	Task:	Reset Winning- Delete Transaction After Reset
	DB:		DBTRANS.BODB02, DB06.BODB02
	
	Revision:
	
	Explanation's Param:
*/	
BEGIN
	SET NOCOUNT ON
	
	--Check permission for account site
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid = @userID, @funcname = '[DeleteFinanceTrans]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		IF @ErrCode <> 0 
			RETURN
	
	IF NOT EXISTS (SELECT 1 FROM Bettrans WITH (NOLOCK) WHERE  custid = @custid AND bettype IN (21001,21002) AND matchID = 0 AND winlostdate = @winlostdate)
	BEGIN
		SELECT @ErrMsg = 'Not reset winning on ' + convert(varchar(15),@winlostdate, 107), @ErrCode = 101		
		RETURN	
	END
	
	DECLARE c CURSOR FOR
	SELECT transid, refno, winlost-actual_stake
	FROM bettrans WITH(NOLOCK)
	WHERE custid = @custid AND winlostdate = @winlostdate AND bettype IN (21001,21002) AND matchid = 0
	
	DECLARE @transid bigint, @refno bigint, @amount money, @LogData NVARCHAR(200)
	
	OPEN c
	FETCH NEXT FROM c INTO @transid, @refno, @amount
	
	WHILE @@FETCH_STATUS = 0
	BEGIN	
		DELETE FROM bettrans WITH(ROWLOCK,UPDLOCK)
		WHERE  transid = @transid
				
		IF @@ERROR <> 0
		BEGIN
			Select @ErrMsg = 'Delete trans failed. Please try again.', @ErrCode = 103		
				RETURN
		END	
		
		SELECT @LogData = 'Delete transaction Reset Winning :' + convert(varchar(20),@custid) + ' amount ' + convert(varchar(20),@amount) + ' Ref.No ' + convert(varchar(20),@refno) + ' TransID ' + convert(varchar(20),@transid)
		
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer @UserID = @UserID, @FromCustID = 0, @ToCustID = @CustID, @IP = @IP, @Doing = @LogData
		
		FETCH NEXT FROM c INTO @transid, @refno, @amount
	END
	
	CLOSE c
	DEALLOCATE c
END

GO
GRANT EXECUTE ON [dbo].[Acc_ResetWinning_Del] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ResetWinning_Del] TO [vnteam]
GO
	