ALTER PROCEDURE [dbo].[Dot_Acc_Race_DummyDel]
	@programID varchar(10),
	@eventdate smalldatetime,
	@raceNumber int,
	@userid int = 151 ----doing userid
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Horse TABLE (orid int)
	INSERT INTO @Horse (orid)
	SELECT orid
	FROM DB02.bodb02.dbo.outright with (nolock)
	WHERE
		ProgramID = @programID
		AND eventdate = @eventdate
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND oddsstatus = 'completed' --completed
	
	IF @@ROWCOUNT > 0 
	BEGIN
		IF @eventdate <'2012-06-01' --@20120530Jamie: From 2012-06-01, no need to check dummy accounts 
		BEGIN	
			DELETE dbo.bettrans 
			FROM dbo.bettrans b with (nolock)
				INNER JOIN @Horse h ON b.matchid = h.orid
			WHERE
				(b.statusID = 121 or refNO = 100000000000) -- 121:done
				and b.bettype in (31,32,33)
				
		END
		DELETE dbo.bettrans2 
		FROM dbo.bettrans2 b with (nolock)
			INNER JOIN @Horse h ON b.matchid = h.orid
		WHERE
			(b.statusID = 121 or refNO = 100000000000) -- 121:done
			and b.bettype in (31,32,33)	

		Declare @LogData as nvarchar(300)
		SET @LogData = 
			'Delete Horse Dummy Account Horse ID:' + @ProgramID 
			+ ' eventdate:' + CAST(@eventdate as nvarchar(20))
			+ ' race:' + CAST(@raceNumber as nvarchar(20))

		EXEC dbo.logfile @userid, @LogData
	END
END


GO
GRANT EXECUTE ON [dbo].[Dot_Acc_Race_DummyDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Acc_Race_DummyDel] TO [ITTim]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Acc_Race_DummyDel] TO [vnteam]