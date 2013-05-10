ALTER PROCEDURE [dbo].[ExecRep_06]
    @mrecommend int,
	@srecommend int,
	@srecommend_old int,
	@ErrCode INT OUTPUT,
	@ErrMsg VARCHAR(500) OUTPUT
AS

if NOT exists (select * from dbo.sysobjects where name = 'custinfo')
BEGIN
	RETURN
END

declare @cnt int
DECLARE @CustInfo TABLE (CustID INT PRIMARY KEY)

INSERT INTO @CustInfo
SELECT custid FROM custinfo (NOLOCK)
WHERE mrecommend = @mrecommend

--bettrans table
if exists (select * from dbo.sysobjects where name = 'bettrans')
BEGIN
    WHILE (1=1)
    BEGIN	
        Update TOP(1000) [dbo].[bettrans] WITH (ROWLOCK, UPDLOCK)
	    set srecommend = @srecommend 
	    where custid IN (SELECT CustID FROM @CustInfo)  
		    and srecommend = @srecommend_old  	
    	
	    select @cnt = @@ROWCOUNT
	    --print @cnt
        IF  @cnt< 1000
            BREAK       
    END

    IF @@ERROR <> 0 
    BEGIN
	    SELECT @ErrMsg = 'Error master ' + cast(@mrecommend as varchar) + ': update unsuccessfully (bettrans).',
		    @ErrCode = 110					 
	    RETURN
    END
END

------------------------------
--bettrans14 table
if exists (select * from dbo.sysobjects where name = 'bettrans14')
BEGIN
    WHILE (1=1)
    BEGIN
        Update TOP(1000) [dbo].[bettrans14] WITH (ROWLOCK, UPDLOCK)
	    set srecommend = @srecommend 
	    where custid IN (SELECT CustID FROM @CustInfo) 
		    and srecommend = @srecommend_old

        select @cnt = @@ROWCOUNT
        IF  @cnt< 1000
            BREAK
    END

    IF @@ERROR <> 0 
    BEGIN   

	    SELECT @ErrMsg = 'Error super master ' + cast(@mrecommend as varchar) + ': update unsuccessfully (bettrans14).',
		    @ErrCode = 111					 
	    RETURN
    END
END

--sum_winloss table
if exists (select * from dbo.sysobjects where name = 'sum_winloss')
BEGIN
    UPDATE sum_winloss WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
    WHERE custid IN (SELECT CustID FROM @CustInfo)
    IF @@ERROR <> 0 
    BEGIN	
	    SELECT @ErrMsg = 'Error master ' + cast(@mrecommend as varchar) + ': update unsuccessfully (sum_winloss).',
		    @ErrCode = 112					 
	    RETURN
    END
END