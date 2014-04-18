CREATE PROCEDURE [NAP_Admin_Calculate_1101]
	@matchid int
AS
/*
	Created by: Kathy
	Date:20140224
	Task: Settlement 
	DB: DBTrans.BODB02

	Revisions:
		
*/

SET NOCOUNT ON

IF @@SERVERNAME not in ('DB042', 'DB043', 'DB044')
BEGIN  	


DECLARE @bettransG TABLE (
	[refno] [bigint] NOT NULL ,  
	[matchid] [int] NULL , 
	[winlost] [money] NULL , 
	[awinlost] [money] NULL ,  
	[mwinlost] [money] NULL ,  
	[swinlost] [money] NULL , 
	[statusID] [tinyint] NULL,
	[stake] [money] NOT NULL,
	[playercomm] [money] NULL,
	[comm] [money] NULL,
	[acomm] [money] NULL,
	[scomm] [money] NULL
)   

DECLARE @bettrans TABLE (
	[transid] [bigint] NOT NULL ,  
	[refno] [bigint] NOT NULL ,  
	[discount] [decimal](9, 8) NULL, 
	[adiscount] [decimal](9, 8) NULL, 
	[sdiscount] [decimal](9, 8) NULL, 
	[playerdiscount] [decimal](9, 8) NULL,  
	[apositiontaking] [smallmoney] NULL ,  
	[mpositiontaking] [smallmoney] NULL , 
	[spositiontaking] [smallmoney] NULL
)   

DECLARE @Temp_bettrans TABLE(
	[transid] [bigint] NOT NULL ,  
	[refno] [bigint] NOT NULL ,  
	[winlost] [money] NULL , 
	[awinlost] [money] NULL ,  
	[mwinlost] [money] NULL ,  
	[swinlost] [money] NULL , 
	[playercomm] [money] NULL ,
	[comm] [money] NULL ,
	[acomm] [money] NULL ,
	[scomm] [money] NULL 
) 

	INSERT INTO @bettransG ([refno],[matchid],[winlost],[awinlost],[mwinlost],[swinlost],[statusID],[stake],[playercomm],[comm],[acomm],[scomm])
	SELECT refno, matchid, WinLost, aWinLost, mWinLost, sWinLost, statusID, stake, playercomm, comm, acomm, scomm
	FROM bettransG WITH(NOLOCK)
	WHERE matchid=@matchid

	INSERT INTO @bettrans ([transid],[refno],[discount],[adiscount],[sdiscount],[playerdiscount],[apositiontaking],[mpositiontaking],[spositiontaking])
	SELECT transid ,refno, discount, adiscount, sdiscount, playerdiscount, apositiontaking, mpositiontaking, spositiontaking
	from bettrans WITH(NOLOCK)
	WHERE matchid=@matchid AND statusID NOT IN (101,102)

	INSERT INTO @Temp_bettrans ([transid],[refno],[winlost],[awinlost],[mwinlost],[swinlost],[PlayerComm],[comm],[acomm],[scomm])
	SELECT S.transid ,S.refno,
		sum(G.WinLost) as WinLost ,
		sum(G.aWinLost) as aWinLost ,
		sum(G.mWinLost) as mWinLost ,
		sum(G.sWinLost) as sWinLost ,
		sum(G.playercomm) as PlayerComm ,
		sum(G.comm) as comm ,
		sum(G.acomm) as acomm ,
		sum(G.scomm) as scomm
	FROM @bettrans S 
		INNER JOIN @bettransG G on G.refno = S.refno
	WHERE G.statusID NOT IN (101,102)
	GROUP BY S.transid ,S.refno

	UPDATE bettrans WITH(ROWLOCK, UPDLOCK)
	SET
		winlost = a.winlost
		,awinlost = a.awinlost
		,mwinlost = a.mwinlost
		,swinlost = a.swinlost
		,playercomm = a.playercomm
		,comm = a.comm
		,acomm = a.acomm
		,scomm = a.scomm
		, status = CASE WHEN a.winlost = bettrans.stake THEN 'DRAW'
						WHEN a.winlost > bettrans.stake THEN 'WON'
						WHEN a.winlost < bettrans.stake THEN 'LOSE'
				   END
		,statusid = CASE WHEN a.winlost = bettrans.stake THEN '111'
						WHEN a.winlost > bettrans.stake THEN '112'
						WHEN a.winlost < bettrans.stake THEN '113'
				   END
		,ruben = 1
	FROM @Temp_bettrans a
	WHERE a.transid  = bettrans.transid  and
	a.refno = bettrans.refno
END


GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_1101] TO [vnteam] AS [dbo]
GO


