DECLARE @ErrCode INT
DECLARE @ErrMsg NVARCHAR(400), @transdesc NVARCHAR(300),
    @custid INT, @refno BIGINT, @sessionid INT, @turnover MONEY, @winlost MONEY, @swinlost MONEY, @mwinlost MONEY, @awinlost MONEY, @scomm MONEY, @acomm MONEY, @comm MONEY, @playercomm MONEY
SELECT @errcode = 0, @errmsg = ''

DECLARE @Casino_tmp_ticket TABLE(CustID INT, refno BIGINT, SessionID BIGINT, TurnOver MONEY, Winlost MONEY, swinlost MONEY, mwinlost MONEY, awinlost MONEY, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY)

INSERT INTO @Casino_tmp_ticket([CustID], [Refno], [SessionID], [TurnOver], [Winlost], [Swinlost], [mwinlost], [awinlost], [scomm], [acomm], [comm], [playercomm])
SELECT custid, refno, betid, winlost,actual_stake, -swinlost, -mwinlost, -awinlost, -scomm, -acomm, -comm, -playercomm
FROM bettrans14 WITH(nolock)
WHERE Custid=1674541 --member II0271111
AND winlostdate='2009-11-14'
AND bettype=71

DECLARE tmp CURSOR FOR SELECT * FROM @Casino_tmp_ticket
OPEN tmp
FETCH NEXT FROM tmp INTO @custid, @refno, @sessionid, @turnover, @winlost, @swinlost, @mwinlost, @awinlost, @scomm, @acomm, @comm, @playercomm

SELECT @transdesc='Correction - II0271111 Refund transaction' + CAST(@refno AS VARCHAR(30))

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.Dot_Casino_BetIns_Thien
        @CustID = @custid,        
        @CS_Turnover = @turnover,
        @CS_winlost = @winlost,
        @CS_swinlost = @swinlost,
        @CS_mwinlost = @mwinlost,
        @CS_awinlost = @awinlost,
        @CS_scomm = @scomm,
        @CS_mcomm = @acomm,
        @CS_acomm =@comm,
        @CS_playercomm = @playercomm,
		@refno = @refno,
		@sessionId = @sessionid,
        @transdesc = @transdesc,
        @IP = 'ServerIP',
        @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
   
    FETCH NEXT FROM tmp INTO @custid, @refno, @sessionid, @turnover, @winlost, @swinlost, @mwinlost, @awinlost, @scomm, @acomm, @comm, @playercomm

END
CLOSE tmp
DEALLOCATE tmp