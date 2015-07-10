  ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
	@ids	VARCHAR(max)
 AS
 /*
	--Allow double comm losing for SMA
	--OFF double comm losing on members
 */
 SET NOCOUNT ON
	IF (SELECT COUNT(1) FROM sys.objects WHERE name IN ('custinfo') AND type = 'U') <> 1
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
	
	
	UPDATE custinfo WITH(ROWLOCK,UPDLOCK)
	SET DoubleCommLosing = 0
	WHERE custid IN (SELECT * FROM @res)
 
 
 GO
 
create table #temp (custid int primary key, isfinished bit)
declare @tmpVipSuper TABLE (custid int)
declare @tmpDirectMaster TABLE (custid int)
declare @max_custid int

select @max_custid = max(custid) from custinfo with(nolock)

insert into @tmpVipSuper (custid)
select custid
from custinfo with(nolock)
where username in ('SBKHK','SBKRMB','SBKTB','SMM','SMSM','SBKH','SBKR','SBKT','SMH','SMMH','SBK','SMAH','SMMS','SMAT','SMR','SMMR','SMBT','SMBH','SSMS'--MMMRM
 ,'SBTK','SBTN','SBTD','SBTL','SBTM','SBTH'--SBTK
 ,'SMT'
 ,'SCM','SCS','SCSM','SCH','SCAH','SCAI','SCI','SCBH','SCHK'--SCM
 ,'KM','KH','KR','KS','KT','KRC','KSD','KMM','KRR','KMA','KHH','KHK','KAR','KBR','KCR','KAM','KMAM','KMBM','KHAH','KHBH','KAT','KHCH','KDR','KER','KHT','KHDH'--679RM
 ,'SGS','SGTB','SGATB','SGI','SGT','SGAT','SGBT','SGCT','SGAR','TEH','TEC','THR','SGSM','SGSN','TEK','SGMM','TED','THH','THS'--MGTB
 ) AND roleid = 4
 
--get direct masters
insert into @tmpDirectMaster(custid)
select custid
from custinfo with(nolock)
where username in ('MMMRM','MMPRM','MMSD','MMRMB'--MMMRM
,'MTORMB'
,'MGBTB','MGCTB'--MGTB
) AND roleid = 3

insert into #temp (custid, isfinished)
select custid, 0
from custinfo with (nolock)
where roleid in (2,3)
	and srecommend not in (select custid from @tmpVipSuper)
	and mrecommend not in (select custid from @tmpDirectMaster)
	and DoubleCommLosing = 1 

declare @ids varchar(max), @rowcnt int

while (1=1)
begin
	select @ids = ''
	
	update TOP (5000) #temp
	set @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	from #temp
	where isfinished = 0
	
	select @rowcnt = @@rowcount	

	EXEC [Acc_ExecRep_09] @ids = @ids
	
	if @rowcnt < 5000 RETURN

	WAITFOR DELAY '00:00:01'
end

select @max_custid as max_custid