DECLARE @ABS TABLE(rn int , oldname nvarchar(50),newname nvarchar(50))

INSERT INTO @ABS (rn,oldname,newname)
SELECT 1,'SSGIB','ABSSS1'
UNION SELECT 2,'SSDANIEL','ABSSS2'
UNION SELECT 3,'SSCAMELL','ABSSS3'

DECLARE @oldname nvarchar(50), @newname nvarchar(50), @i int,
		@ErrCode int, @ErrMsg nvarchar(200), @userid int

select @userid = 1948903-- dbaJamie
--
SELECT @i = 1

WHILE @i <=3
BEGIN
	SELECT @oldname = oldname,@newname = newname
	FROM @ABS
	WHERE rn = @i

	EXEC Acc_CustomerUpdUserName @oldname = @oldname, @newname = @newname, @userid = @userid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode as ErrCode, @ErrMsg as ErrMsg,@oldname as oldname_fail, @newname as newname
		BREAK;		
	END
	ELSE		
		SELECT @i = @i + 1
	
	WAITFOR DELAY '0:00:01'
			
END 