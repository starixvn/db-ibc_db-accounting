


ALTER PROCEDURE [dbo].[Admin_Recalculate_Settlement_FGLG]
	@creator int,
	@matchid int,	
	@betstatus nvarchar(50),
	@IncludeLG bit = 1,
	@IP varchar(15) = '',
	@goalrecord varchar(50) = ''
	
AS
/*	Creator: 20111116@Lukas
	Task: SP for settle FGLG
	DB: DB052.BODB_REVIEW
	
	History:
		- 20091225@Daniel: Add writelog to table Userlog_settle
		- 20100305@Daniel: Add writelog to table Userlog
		- 20100720@Henry: Change SP Logfile to WriteLog_UserLog
		- 20100825@Lukas: Update last time modify (changetime column) for match table
		- 20110606@Lukas: replace update match statement by store procedure	
		- 20110620@Jamie: Refer to Match in DB02 instead of DBTRANS	
	Param's Explanation:
		+ @betstatus: FGLG status
		
*/
BEGIN
	-------------------------
	--First Goal, Last Goal 
	Declare @FGLG1 varchar(10), @FGLG2 varchar(10), @FLString varchar(10)
	
	select @FGLG1 = '', @FGLG2 = ''
	
	if charindex('FL:', @betstatus) > 0
	BEGIN
		select 	@FLString = substring(@betstatus, charindex('FL:', @betstatus) + 3, 3)

		select @FGLG1 = case @FLString
							when '0-0' then '0:0'
							else left(@FLString,1) + ':1'
							end,			
				@FGLG2 = case @FLString
							when '0-0' then ''
							else right(@FLString,1) + ':2'
							end
	END
	-------------------------

-- bettype 14 : First Goal Last Goal - re-use the SP of Correct Score, so we have to call it twice		

	if @FGLG2 <> ''
	BEGIN	
		EXEC dbo.Admin_Recalculate_4 @matchid, 14, @FGLG1, 0, @FGLG2
	END
	ELSE
	BEGIN
		EXEC dbo.Admin_Recalculate_4 @matchid, 14, @FGLG1, 0			
	END


	--refund all LG tickets if not include LG
	IF @IncludeLG = 0
	BEGIN
		EXEC dbo.Admin_Recalculate_Settlement_Refund_FGLG--refund LG
			@matchid = @matchid,
			@adminid = @creator,
			@LGOnly = 1,
			@IP = @IP
	END
END

