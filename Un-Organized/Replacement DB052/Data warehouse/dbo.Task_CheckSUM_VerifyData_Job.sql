USE [bodb_staging]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckSUM_VerifyData_Job]    Script Date: 12/13/2012 04:11:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckSUM_VerifyData_Job] 	
AS
/*
	Created: Viet @ 30 NOV 2012
	Task : get checksum data to compare with other servers.
	DB: DB054.bodb_staging

	Revisions:
		- 20121213@Dan: Change linked server from DB052-->DBEXT
					
*/
SET NOCOUNT ON
	IF EXISTS(SELECT 1 FROM DB06.bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VValue = '1' AND VName in ('isMovingBet','isArchivingBet')) RETURN 
	
	truncate table Checksum_match
	truncate table checksum_ticket
	
	DECLARE @startRun DATETIME ,@endRun DATETIME, @duration int
	SELECT @startRun = CURRENT_TIMESTAMP
	
	DECLARE @fdate datetime, @tdate datetime, @date smalldatetime, @checkID int
	SET @date = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)
	SET @tdate = DATEADD(minute, -15, CURRENT_TIMESTAMP)

	IF DATEPART(HOUR, CURRENT_TIMESTAMP) < 4 SET @date = DATEADD(dd,-1, @date)
	SELECT TOP 1 @fdate = checktime
	FROM dbo.Checksum_setting WITH(NOLOCK)
	WHERE status = 'completed'
	ORDER BY CheckID DESC
	
	IF @@ROWCOUNT = 0 
		SET @fdate = @date
	ELSE 
		SET @fdate = DATEADD(MINUTE, -15, @fdate)
	
	INSERT INTO dbo.Checksum_setting(checktime, status) values(CURRENT_TIMESTAMP, 'running')
	SELECT @checkID = @@IDENTITY
		
	CREATE TABLE #Tempdata (mode varchar(20), ID bigint, hasCalled bit)
	
	INSERT INTO #Tempdata(mode, ID, hasCalled)
	SELECT 'match', matchid, 0	
	FROM bodb02.dbo.match with(nolock)
	WHERE eventstatus = 'completed'
	and changetime between @fdate AND @tdate
			
	INSERT INTO #Tempdata(mode, ID, hasCalled)
	SELECT 'outright', orid, 0	
	FROM bodb02.dbo.outright with(nolock)
	WHERE oddsstatus = 'completed'
		AND changetime between @fdate AND @tdate				
	
	
	INSERT INTO #Tempdata(mode, ID, hasCalled)
	SELECT 'parlay', transid, 0		
	FROM bodb02.dbo.bettrans b with(nolock) 		
	WHERE matchid in (9,29)
		and ruben = 1
		and winlostdate >= @date						
		
	declare @list varchar(max), @_mode varchar(20), @n int
	declare @modes as table(mode varchar(20), hasCalled bit)
	INSERT INTO @modes(mode, hasCalled) values('match', 0)
	INSERT INTO @modes(mode, hasCalled) values('outright', 0)
	INSERT INTO @modes(mode, hasCalled) values('parlay', 0)
	--INSERT INTO @modes(mode, hasCalled) values('transfer', 0)
	
	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) @modes	
		SET hasCalled = 1,
			@_mode = mode
		WHERE hasCalled = 0
			
		IF @@ROWCOUNT = 0 BREAK
				
		WHILE (1 = 1)
		BEGIN
			SET @list = ''
			if @_mode='parlay' SET @n = 100
			ELSE SET @n = 10
			
			UPDATE TOP (@n) #Tempdata
			set @list = @list + ',' + cast(ID as varchar(13))
				,hascalled = 1
			where hascalled = 0
				and mode = @_mode
			
			IF @@ROWCOUNT = 0 BREAK
			
			SET @list = STUFF(@list,1,1,'')		
			EXEC DBTrans.bodb02.dbo.Task_CheckSUM_VerifyData @checkID = @checkID, @mode = @_mode, @list = @list
			EXEC DBEXT.bodb02.dbo.Task_CheckSUM_VerifyData @checkID = @checkID, @mode = @_mode, @list = @list
			EXEC DB053.bodb02.dbo.Task_CheckSUM_VerifyData @checkID = @checkID, @mode = @_mode, @list = @list
			EXEC DB054.bodb02.dbo.Task_CheckSUM_VerifyData @checkID = @checkID, @mode = @_mode, @list = @list
			EXEC DB06.bodb02.dbo.Task_CheckSUM_VerifyData @checkID = @checkID, @mode = @_mode, @list = @list
		END	
	END
	drop table #Tempdata		
		
	SELECT @endRun = CURRENT_TIMESTAMP		
	SET @duration = DATEDIFF(millisecond, @startRun, @endRun)					
								
	UPDATE dbo.Checksum_setting WITH(ROWLOCK, UPDLOCK)
	SET status = 'completed'
		,duration = @duration
	WHERE CheckID = @checkID


	DECLARE @errcode bit
	SET @errcode = 0
	INSERT INTO dbo.Checksum_match_problem(
		checkid, matchid, bettype, s_dbtrans, s_db052, s_db053, s_db054, s_db06
	)
	SELECT @checkID, matchid, bettype, s_dbtrans, s_db052, s_db053, s_db054, s_db06
	FROM Checksum_match 
	where 4*s_dbtrans <> (s_db052 + s_db053 + s_db054 + s_db06)
	
	IF @@ROWCOUNT > 0 SET @errcode = 1
	
	INSERT INTO dbo.Checksum_ticket_problem (
		checkid, transid, bettype, s_dbtrans, s_db052, s_db053, s_db054, s_db06
	)
	SELECT @checkID, transid, bettype, s_dbtrans, s_db052, s_db053, s_db054, s_db06
	from checksum_ticket 
	where 4*s_dbtrans <> (s_db052 + s_db053 + s_db054 + s_db06)
	
	IF @@ROWCOUNT > 0 SET @errcode = 1 
	
	IF @errcode > 0
	BEGIN
		DECLARE @body VARCHAR(MAX) 
		SET @body = 'Hi There, '+char(13)+char(13)+'Please have a check!!'+char(13)+char(13)
		SELECT @body = 'There are un-sync ticket(s)!!! '		
		SELECT @body = @body + char(13) + '-- SELECT * FROM DB054.bodb_staging.dbo.Checksum_ticket_problem WHERE CheckID = '+CAST(@checkID as varchar(10))+cHar(13)
		SELECT @body = @body + char(13) + '-- SELECT * FROM DB054.bodb_staging.dbo.Checksum_match_problem WHERE CheckID = '+CAST(@checkID as varchar(10))+cHar(13)
		--SELECT @body
		EXEC msdb.dbo.sp_send_dbmail
		@recipients=N'viet.hoang@nexcel.vn',
		@body=@body,
		@sensitivity ='Personal',
		@importance ='High',
		@copy_recipients ='thien.pham@nexcel.vn',
		@subject ='Tickets problem notification',
		@profile_name ='DB054Profile';
	END
	
	/*
	SELECT SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as cs
	FROM dbo.bettrans with(nolock) 
	WHERE .....
	*/
