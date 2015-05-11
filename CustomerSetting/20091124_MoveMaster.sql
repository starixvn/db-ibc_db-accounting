declare @supername VARCHAR(40),
	@userid	INT,
	@IP VARCHAR(15),
	@ErrCode INT,
	@ErrMsg NVARCHAR(200)
select 
	@supername = 'skw',
	@userid = 862400,
	@IP='202.78.228.8',
	@ErrCode = 0, 
	@ErrMsg = ''

	DECLARE @mastername VARCHAR(30)

	DECLARE @master TABLE (username VARCHAR (30))
	INSERT INTO @master
	SELECT 'SKC76' UNION 
	SELECT 'SKCAR' UNION
	SELECT 'SKCAV' UNION
	SELECT 'SKCBZ' UNION
	SELECT 'SKCCV' UNION
	SELECT 'SKCDQ' UNION
	SELECT 'SKCDV' UNION
	SELECT 'SKCE4' UNION
	SELECT 'SKCEJ' UNION
	SELECT 'SKCID' UNION
	SELECT 'SKCIF' UNION	
	SELECT 'SKCK1'

declare @cnt int
startloop:

	SELECT TOP 1 @mastername = username FROM @master
	SELECT @cnt = @@ROWCOUNT

	IF @cnt = 0 GOTO EndLoop
	
	EXEC dbo.Acc_CustomerUpdMoveMaster 
	@supername = @supername,
	@mastername = @mastername,
	@userid = @userid,
	@IP = @IP,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT

	if @ErrCode <> 0 SELECT @ErrCode, @ErrMsg

	DELETE FROM @master WHERE username = @mastername

	GOTO StartLoop

EndLoop: