ALTER PROCEDURE  [dbo].[Acc_P2PUpdDefaultSetting]
	@Currency INT,
	@MinCredit MONEY,
	@MaxCredit MONEY,
	@Maxsdiscount DECIMAL(9,8),
	@Maxadiscount DECIMAL(9,8),
	@Maxdiscount DECIMAL(9,8),
	@Maxplayerdiscount DECIMAL(9,8),
	@UserID INT , 
	@Language VARCHAR(2) = 'E',
	@IP VARCHAR(40) = '',
	@ErrCode INT= 0 OUTPUT ,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT

AS
/*
	Created: TOM
	Date: 08152011
	DB: DBTRANS.BODB02
	Task: Update default setting of P2P 
	
	Revisions:
		- 20120329@Sophia: Change sp write log to WriteLog_UserLog_ExchangeRate
		- 20120530@Sophia: Add write log for old value
		- 20120705@Elodie: Change max value of discount = 1
		- 20130318@Elodie: Change linked server DB03 to DBPOLICY
						   Write more log on DBTXN server in case of DBLOG server failure
*/
SET NOCOUNT ON

DECLARE
	@MinCredit_Old MONEY,
	@MaxCredit_Old MONEY,
	@Maxsdiscount_Old DECIMAL(9,8),
	@Maxadiscount_Old DECIMAL(9,8),
	@Maxdiscount_Old DECIMAL(9,8),
	@Maxplayerdiscount_Old DECIMAL(9,8)
    
DECLARE @startRun DATETIME, @duration INT ;

SET @startRun = getdate()

EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[P2PDefaultSetting]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
IF	(@MinCredit > @MaxCredit OR @MinCredit < 0 )
BEGIN
	SELECT @ErrMsg = CASE @Language 
						WHEN 'E' THEN 'Invalid Transfer Credit.'
						WHEN 'CS' THEN N'Invalid Transfer Credit.'
						WHEN 'CT' THEN N'Invalid Transfer Credit.'
						WHEN 'TH' THEN N'Invalid Transfer Credit.'
						WHEN 'J' THEN N'Invalid Transfer Credit.'
						WHEN 'KO' THEN N'Invalid Transfer Credit.'
						ELSE N'Invalid Transfer Credit.'
					END, @ErrCode = 100
	RETURN
END

IF	@Maxsdiscount < 0 OR @Maxsdiscount > 1 OR 
	@Maxadiscount < 0 OR @Maxadiscount > 1 OR 
	@Maxdiscount < 0 OR @Maxdiscount > 1 OR 
	@Maxplayerdiscount < 0 OR @Maxplayerdiscount > 1 OR 
	@Maxplayerdiscount > @Maxdiscount OR 
	@Maxdiscount > @Maxadiscount OR 
	@Maxadiscount > @Maxsdiscount
BEGIN
	SELECT @ErrMsg = CASE @Language 
						WHEN 'E' THEN 'Invalid commission rate.'
						WHEN 'CS' THEN N'Invalid commission rate.'
						WHEN 'CT' THEN N'Invalid commission rate.'
						WHEN 'TH' THEN N'Invalid commission rate.'
						WHEN 'J' THEN N'Invalid commission rate.'
						WHEN 'KO' THEN N'Invalid commission rate.'
						ELSE N'Invalid commission rate.'
					END, @ErrCode = 101
	RETURN
END

SELECT @MinCredit_old = MinCredit ,
	@MaxCredit_old = MaxCredit ,
	@Maxsdiscount_old = Maxsdiscount ,
	@Maxadiscount_old = Maxadiscount ,
	@Maxdiscount_old = Maxdiscount ,
	@Maxplayerdiscount_old = Maxplayerdiscount
FROM P2PDefaultSetting WITH (NOLOCK)
WHERE currency = @currency

IF (@MinCredit_old = @MinCredit 
	AND @MaxCredit_old = @MaxCredit 
	AND @Maxsdiscount_old = @Maxsdiscount 
	AND @Maxadiscount_old = @Maxadiscount 
	AND @Maxdiscount_old = @Maxdiscount 
	AND @Maxplayerdiscount_old = @Maxplayerdiscount)
RETURN

UPDATE P2PDefaultSetting  WITH (ROWLOCK,UPDLOCK)
SET	MinCredit = @MinCredit ,
	MaxCredit = @MaxCredit ,
	Maxsdiscount = @Maxsdiscount ,
	Maxadiscount = @Maxadiscount ,
	Maxdiscount = @Maxdiscount ,
	Maxplayerdiscount = @Maxplayerdiscount
WHERE currency = @currency

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
					END	, @ErrCode = 102
	RETURN
END

DECLARE @LogData VARCHAR(5000)

SELECT @LogData = '<Acc_P2PUpdDefaultSetting ' +
	'currency="'+ coalesce(cast(@Currency as varchar(50)),space(1)) + '" ' +
	'MinCredit="'+ coalesce(cast(@MinCredit as varchar(50)),space(1)) + '" ' +
	'OldMinCredit="'+ coalesce(cast(@MinCredit_old as varchar(50)),space(1)) + '" ' +
	'MaxCredit="'+ coalesce(cast(@MaxCredit as varchar(50)),space(1)) + '" ' +
	'OldMaxCredit="'+ coalesce(cast(@MaxCredit_old as varchar(50)),space(1)) + '" ' +
	'Maxsdiscount="'+ coalesce(cast(@Maxsdiscount as varchar(50)),space(1)) + '" ' +
	'OldMaxsdiscount="'+ coalesce(cast(@Maxsdiscount_old as varchar(50)),space(1)) + '" ' +
	'Maxadiscount="'+ coalesce(cast(@Maxadiscount as varchar(50)),space(1)) + '" ' +
	'OldMaxadiscount="'+ coalesce(cast(@Maxadiscount_old as varchar(50)),space(1)) + '" ' +
	'Maxdiscount="'+ coalesce(cast(@Maxdiscount as varchar(50)),space(1)) + '" ' +
	'OldMaxdiscount="'+ coalesce(cast(@Maxdiscount_old as varchar(50)),space(1)) + '" ' +
	'Maxplayerdiscount="'+ coalesce(cast(@Maxplayerdiscount as varchar(50)),space(1)) + '" ' +
	'OldMaxplayerdiscount="'+ coalesce(cast(@Maxplayerdiscount_old as varchar(50)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

SET @duration  = datedIFf (millisecond,@startRun,getdate())

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_ExchangeRate 
		@UserID = @UserID, 
		@exchangeID = @Currency, 
		@actualrate = 0, 
		@IP = @IP, 
		@Doing = @LogData
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_P2PUpdDefaultSetting ' +
		'currency="'+ coalesce(cast(@Currency as varchar(50)),space(1)) + '" ' +
		'MinCredit="'+ coalesce(cast(@MinCredit as varchar(50)),space(1)) + '" ' +
		'OldMinCredit="'+ coalesce(cast(@MinCredit_old as varchar(50)),space(1)) + '" ' +
		'MaxCredit="'+ coalesce(cast(@MaxCredit as varchar(50)),space(1)) + '" ' +
		'OldMaxCredit="'+ coalesce(cast(@MaxCredit_old as varchar(50)),space(1)) + '" ' +
		'Maxsdiscount="'+ coalesce(cast(@Maxsdiscount as varchar(50)),space(1)) + '" ' +
		'OldMaxsdiscount="'+ coalesce(cast(@Maxsdiscount_old as varchar(50)),space(1)) + '" ' +
		'Maxadiscount="'+ coalesce(cast(@Maxadiscount as varchar(50)),space(1)) + '" ' +
		'OldMaxadiscount="'+ coalesce(cast(@Maxadiscount_old as varchar(50)),space(1)) + '" ' +
		'Maxdiscount="'+ coalesce(cast(@Maxdiscount as varchar(50)),space(1)) + '" ' +
		'OldMaxdiscount="'+ coalesce(cast(@Maxdiscount_old as varchar(50)),space(1)) + '" ' +
		'Maxplayerdiscount="'+ coalesce(cast(@Maxplayerdiscount as varchar(50)),space(1)) + '" ' +
		'OldMaxplayerdiscount="'+ coalesce(cast(@Maxplayerdiscount_old as varchar(50)),space(1)) + '" ' +
		'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ error_message() + '" />'
		
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_ExchangeRate 
		@UserID = @UserID, 
		@exchangeID = @Currency, 
		@actualrate = 0, 
		@IP = @IP, 
		@Doing = @LogData
END CATCH	

GO
GRANT EXECUTE ON [dbo].[Acc_P2PUpdDefaultSetting] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_P2PUpdDefaultSetting] TO [vnteam]