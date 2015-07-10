/*
	Update pwdexpiry 
*/
	
	ALTER PROCEDURE [dbo].[Acc_ExecRep_09]	
		@ids varchar(max),
		@PwdExpiry DATETIME
	AS

	BEGIN
		SET NOCOUNT ON 

		IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('Customer') AND type = 'U') <> 1
			RETURN

		DECLARE @res AS TABLE (custid INT)
		DECLARE @splitter CHAR(1), @string VARCHAR(MAX)

		SELECT @splitter = ',', @string = @ids

		IF SUBSTRING (@string, LEN (@string), 1) <> @splitter
			  SET @string= @string+@splitter

		DECLARE @START INT, @word NVARCHAR(4000), @CHARINDEX INT, @i INT
		SET @i=1
		SET @START=1
		SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
		WHILE (@CHARINDEX <> 0)BEGIN
			SET @word= SUBSTRING( @string, @START, @CHARINDEX - @START)
			SET @START= @CHARINDEX +1
			SET @CHARINDEX= CHARINDEX( @splitter, @string, @START)
			INSERT INTO @res  VALUES(CAST(@word AS INT))
			SET @i=@i+1
		END

		UPDATE Customer WITH (UPDLOCK,ROWLOCK)
		SET    pwdexpiry =@PwdExpiry
		WHERE  custid IN (select * from @res) 
		
	END
	GO


DECLARE @MaxCustID INT
SELECT	@MaxCustID = -- SELECT MAX(CustID) FROM Custinfo WITH (NOLOCK)


create table #temp (custid int primary key, isfinished bit)

insert into #temp (custid, isfinished)
SELECT c.custid, 0
FROM custInfo c WITH (NOLOCK)
WHERE custid <= 10579672   --@MaxCustID
	AND srecommend NOT IN (SELECT custid from f_DepSuper_1('ALL'))
	AND roleid BETWEEN 2 AND 4 

    --'2013-03-28 22:42:07.967' latest updated password 

--
declare @ids varchar(max), @rowcnt int
DECLARE	@PwdExpiry DATETIME 
SELECT	@PwdExpiry = '2013-03-29'
SELECT	@PwdExpiry

while (1=1)
begin
	select @ids = ''
	
	update TOP (10000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(20))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount
	
	EXEC [Acc_ExecRep_09] @ids = @ids, @PwdExpiry = @PwdExpiry
	
	print  @ids
	
	if @rowcnt < 10000 RETURN
	WAITFOR DELAY '00:00:01'
end


--SELECT top 1 *
--FROM Customer with (NOLOCK)
--where roleid BETWEEN 2 and 4 


 