 DECLARE @ErrCode INT
DECLARE @ErrMsg NVARCHAR(400),
    @custid INT, @refno BIGINT, @sessionid INT, @turnover MONEY, @winlost MONEY, @swinlost MONEY, @mwinlost MONEY, @awinlost MONEY, @scomm MONEY, @acomm MONEY, @comm MONEY, @playercomm MONEY
SELECT @errcode = 0, @errmsg = ''

DECLARE @Casino_tmp_ticket TABLE(CustID INT, refno BIGINT, SessionID BIGINT, TurnOver MONEY, Winlost MONEY, swinlost MONEY, mwinlost MONEY, awinlost MONEY, scomm MONEY, acomm MONEY, comm MONEY, playercomm MONEY)

INSERT INTO @Casino_tmp_ticket(
[CustID],
[Refno],
[SessionID],
[TurnOver],
[Winlost],
[Swinlost],
[mwinlost],
[awinlost],
[scomm],
[acomm],
[comm],
[playercomm]
)
SELECT
1881161,
100110392404,   
4896,  
1035, 
0,   
51.75,   
20.7,   
755.55,   
0,   
0,  
0, 
0


DECLARE tmp CURSOR FOR SELECT * FROM @Casino_tmp_ticket
OPEN tmp
FETCH NEXT FROM tmp INTO @custid, @refno, @sessionid, @turnover, @winlost, @swinlost, @mwinlost, @awinlost, @scomm, @acomm, @comm, @playercomm

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC dbo.DBA_Bingo_UpdTicket
        @CustID = @custid,
        @refno = @refno,
        @sessionID = @sessionID,
        @BI_Turnover = @turnover,
        @BI_winlost = @winlost,
        @BI_swinlost = @swinlost,
        @BI_mwinlost = @mwinlost,
        @BI_awinlost = @awinlost,
        @BI_scomm = @scomm,
        @BI_mcomm = @acomm,
        @BI_acomm =@comm,
        @BI_playercomm = @playercomm,
        @transdesc = '',
        @IP = '',
        @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
    SELECT @ErrCode, @ErrMsg
    FETCH NEXT FROM tmp INTO @custid, @refno, @sessionid, @turnover, @winlost, @swinlost, @mwinlost, @awinlost, @scomm, @acomm, @comm, @playercomm

END
CLOSE tmp
DEALLOCATE tmp


SELECT Username,
[CustID],
[Refno],
stake,
[Winlost],
[Swinlost],
[mwinlost],
[awinlost],
[scomm],
[acomm],
[comm],
[playercomm],*
FROM bettrans (nolock)
WHERE refno =100110392404 and matchid = 0

