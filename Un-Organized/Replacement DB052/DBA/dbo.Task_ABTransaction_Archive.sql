USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_ABTransaction_Archive]    Script Date: 12/13/2012 03:51:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER PROCEDURE [dbo].[Task_ABTransaction_Archive]
 @winlostdate	DATETIME 

 AS	
	/*
		Created: Johnson
		Date: 2012-09-13
		Task: Archive transactions for ABS
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20121017@Jamie: Archive the data based on winlostdate instead of MAX TransID 
			- 20121213@Dan: Change linked server from DB052-->DBABS
		
		Parameters Explanation:
	*/
 SET NOCOUNT ON
 
IF EXISTS (	SELECT	TOP 1 1 
			FROM	bodb_archive.dbo.bettrans_bk b WITH (NOLOCK,INDEX=IX_transid) 
					INNER JOIN DBABS.bodb_ABS.dbo.ABTransaction t WITH (NOLOCK) ON b.transid = t.transid 
			WHERE	b.winlostdate = @winlostdate
		   )
BEGIN 
	IF EXISTS(	SELECT	TOP 1 1 
				FROM	bodb_archive.dbo.bettrans_bk b WITH (NOLOCK,INDEX=IX_transid) 
						INNER JOIN DBABS.bodb_ABS.dbo.ABTransaction_bk t WITH (NOLOCK) ON b.transid = t.transid  
				WHERE	b.winlostdate = @winlostdate 			
	) 
		RETURN

	INSERT INTO DBABS.bodb_ABS.[dbo].[ABTransaction_BK]
			   ([transid]
			   ,[punterid]
			   ,[custid]
			   ,[remark])
	SELECT	t.[transid]
		   ,t.[punterid]
		   ,t.[custid]
		   ,t.[remark]
	FROM	bodb_archive.dbo.bettrans_bk b WITH (NOLOCK) 
			INNER JOIN DBABS.bodb_ABS.[dbo].[ABTransaction] t WITH (NOLOCK) ON b.transID = t.transID
	WHERE	winlostdate = @winlostdate 
	
	IF @@ERROR <> 0
	BEGIN
		RAISERROR('Archiving AB Bet transaction failed!',16,1)
		RETURN 
	END


	INSERT INTO DBABS.[bodb_ABS].[dbo].[ABMatch_Remark_BK]
			   ([matchid]
			   ,[bettype]
			   ,[hdp]
			   ,[odds]
			   ,[transid])
	SELECT	r.[matchid]
		   ,r.[bettype]
		   ,r.[hdp]
		   ,r.[odds]
		   ,r.[transid]	
	FROM	bodb_archive.dbo.match_bk m WITH (NOLOCK)
			INNER JOIN DBABS.bodb_ABS.dbo.ABMatch_Remark r WITH (NOLOCK) ON m.matchid = r.matchid 
	WHERE	m.eventdate = @winlostdate 
	IF @@ERROR <> 0
	BEGIN
		RAISERROR('Archiving AB Match failed!',16,1)
		RETURN 
	END

END

