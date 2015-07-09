USE [bodb_staging]
GO
/****** Object:  StoredProcedure [dbo].[CheckData_PerformChecking]    Script Date: 12/13/2012 04:13:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CheckData_PerformChecking]
AS	
/*   
 Task: check data
 DB: DB054.bodb_staging
 Revisions:   
  - 20121015@viet: create SP   
  - 20121213@Dan: Change linked server from DB052-->DBEXT
*/  	
SET NOCOUNT ON				
	
	Declare @result_unsynced varchar(MAX), @result_missing varchar(MAX)
	declare @cnt1 int ,@cnt2 int
	SELECT @result_unsynced = '', @result_missing =''	
	
	SELECT @cnt1 = SUM(p.rows)
	FROM sys.objects o
	INNER JOIN sys.partitions p ON p.OBJECT_ID = o.OBJECT_ID
	WHERE p.index_id < 2
		and name = 'checkdata_bettrans_main'	
		
	SELECT @cnt2 = SUM(p.rows)
	FROM sys.objects o
	INNER JOIN sys.partitions p ON p.OBJECT_ID = o.OBJECT_ID
	WHERE p.index_id < 2
		and name = 'checkdata_bettrans'	

	IF (@cnt2 <> @cnt1*4) 
	BEGIN
		Declare @date varchar(10)
		EXEC dbo.CheckData_GetWinlostdate @date = @date OUTPUT 
		
		-- find missing row at main table
		declare @IDs_main as TABLE (transid bigint)	
		INSERT INTO @IDs_main (transid)
		select distinct s.transid
		FROM checkdata_bettrans s with(nolock)
			LEFT JOIN checkdata_bettrans_main d with(nolock) on s.transid = d.transid
		WHERE d.custid is null

		IF @@ROWCOUNT > 0 --copy tickets from DBTrans again
		BEGIN
			INSERT INTO dbo.checkdata_bettrans_main (custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid)		
			SELECT custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid
			FROM DBTrans.bodb02.dbo.bettrans with(rowlock)
			WHERE transid in (select transid from @IDs_main)	
				and winlostdate = @date
				
			DELETE d
			FROM dbo.checkdata_bettrans_main s with(nolock)
				INNER JOIN @IDs_main d on s.transid = d.transid

			-- report problem (if any)			
			SELECT @result_unsynced = @result_unsynced
				+ ISNULL((SELECT ',' + cast(transid as varchar(15)) +' ('+cast(servername as varchar(30))+') ' 
			FROM dbo.checkdata_bettrans with(nolock)
			WHERE transid in (select transid from @IDs_main)			
			FOR XML PATH('')),'')									
		END
		
		-- find missing tickets at rep table
		declare @IDs_rep as TABLE (transid bigint)
		INSERT INTO @IDs_rep(transid)
		select distinct s.transid
		FROM dbo.checkdata_bettrans_main s with(nolock)
			LEFT JOIN dbo.checkdata_bettrans d with(nolock) on s.transid = d.transid
		WHERE d.custid is null
		UNION
		SELECT distinct transid
		FROM dbo.checkdata_bettrans with(nolock)
		group by transid
		having COUNT(1) < 4
			
		IF @@ROWCOUNT > 0
		BEGIN --re-copy for missing tickets
			DELETE dbo.checkdata_bettrans
			WHERE transid in (select transid from @IDs_rep)
			
			--DB052
			INSERT INTO dbo.checkdata_bettrans (Servername, custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid)		
			SELECT 'DB052', custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid
			FROM DBEXT.bodb02.dbo.bettrans with(rowlock)
			WHERE transid in (select transid from @IDs_rep)
				and winlostdate = @date
				
			--DB053
			INSERT INTO dbo.checkdata_bettrans (Servername, custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid)		
			SELECT 'DB053', custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid
			FROM DB053.bodb02.dbo.bettrans with(rowlock)
			WHERE transid in (select transid from @IDs_rep)
				and winlostdate = @date
				
			--DB054
			INSERT INTO dbo.checkdata_bettrans (Servername, custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid)		
			SELECT 'DB054', custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid
			FROM DB054.bodb02.dbo.bettrans with(rowlock)
			WHERE transid in (select transid from @IDs_rep)
				and winlostdate = @date
			
			--DB06
			INSERT INTO dbo.checkdata_bettrans (Servername, custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid)		
			SELECT 'DB06', custid, bettype, stake, winlost, actual_stake, ruben, statuswinlost, 
				status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid
			FROM DB06.bodb02.dbo.bettrans with(rowlock)
			WHERE transid in (select transid from @IDs_rep)
				and winlostdate = @date			
			
			-- report problem (if any)
			SELECT @result_missing = @result_missing + ISNULL((SELECT ',' + cast(transid as varchar(15)) 
			FROM (
				SELECT transid
				FROM dbo.checkdata_bettrans with(nolock)
				WHERE transid in (select transid from @IDs_rep)
				GROUP BY transid
				HAVING COUNT(1) < 4	
			) X 
			FOR XML PATH('')),'')							
		END
	END

	DECLARE @data as TABLE(servername nvarchar(128), custid int)
	
	;WITH D AS (
		select servername
			,custid
			,SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as CS
		FROM checkdata_bettrans with(nolock)
		GROUP BY Servername, custid
	)
	INSERT INTO @data(servername, custid)
	SELECT d.servername, d.custid
	FROM (	SELECT custid, SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as CS
			FROM dbo.checkdata_bettrans_main with(nolock)
			GROUP BY custid
		) s
		INNER JOIN D d on s.custid =d.custid
	WHERE s.CS <> d.CS
			
	IF @@ROWCOUNT > 0
	BEGIN
		declare @temp_unsync as table(servername nvarchar(128), transid bigint)
		
		;WITH D AS (
			select b.servername
				,transid
				,SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as CS
			FROM checkdata_bettrans b with(nolock)
				INNER JOIN @data d on b.servername = d.servername and b.custid = d.custid
			GROUP BY b.Servername, transid
		)	
		INSERT INTO @temp_unsync (servername, transid)	
		SELECT d.servername, d.transid
		FROM (	SELECT transid, SUM(CAST(CHECKSUM(bettype, stake, winlost, actual_stake, ruben, statuswinlost, status, statusid, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, currency, transid) as bigint)) as CS
				FROM dbo.checkdata_bettrans_main with(nolock)
				WHERE custid in (select distinct custid from @data)
				GROUP BY transid
			) s
			INNER JOIN D d on s.transid =d.transid
		WHERE s.CS <> d.CS
		
		IF @@rowcount > 0
		BEGIN	
			SELECT @result_unsynced = @result_unsynced + ISNULL((SELECT ',' + cast(transid as varchar(15)) +' ('+cast(servername as varchar(30))+') ' 
			FROM @temp_unsync 
			FOR XML PATH('')),'')	
		END				
	END	
	IF @result_unsynced <> '' OR @result_missing <> ''
	BEGIN
		DECLARE @body VARCHAR(MAX) 
		SET @body = 'Hi There, '+char(13)+char(13)+'Please have a check!!'+char(13)+char(13)
		SELECT @body = @body + case when @result_unsynced <> '' then 'There are un-sync ticket(s): ' + STUFF(@result_unsynced, CHARINDEX(',', @result_unsynced, 0), 1, '') + char(13) else '' end			
		SELECT @body = @body + case when @result_missing <> '' then 'There are missing ticket(s): ' + STUFF(@result_missing, CHARINDEX(',', @result_missing, 0), 1, '') + char(13) else '' end
		SELECT @body = @body + char(13) + '---------------------------------------------------------'
		SELECT @body = @body + char(13) + 'This email is sent from DB054, by SP CheckData_PerformChecking @ bodb_staging [SQL-JOB: bodb_staging: verify bettrans data]:)'+cHar(13)
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
	
	TRUNCATE TABLE dbo.checkdata_setting
	
SET NOCOUNT OFF	