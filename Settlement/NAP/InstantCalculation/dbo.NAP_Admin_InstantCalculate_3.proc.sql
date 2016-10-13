ALTER PROCEDURE [dbo].[NAP_Admin_InstantCalculate_3]
	@matchid 		INT
    ,@action		VARCHAR(10)
	,@strTransIds 	VARCHAR(MAX)
AS
/*    
	Creator: 20161004@Bobby
    Task: Implement Instant Calculation
    DB: DBTXN.bodb02
	Original:

    Revisions:        
    Param's Explanation:
        
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xmlInstantTicket 	XML
		, @commWinRate 			SMALLMONEY
        , @commLostRate 		SMALLMONEY
		
	CREATE TABLE #instantTicket (transid BIGINT, modds MONEY)		
	
	SET @xmlInstantTicket = CONVERT(XML, N'<root><r t="' + REPLACE(REPLACE(@strTransIds, '|', '" m="'), ',', '"/><r t="') + '"/></root>')
	
	INSERT INTO #instantTicket (transid, modds)
	SELECT T.C.value('./@t', 'BIGINT') 		AS transid
			,T.C.value('./@m', 'MONEY') 	AS statusId
	FROM @xmlInstantTicket.nodes('/root/r') AS T(C)
	OPTION (OPTIMIZE FOR (@xmlInstantTicket = NULL ))

	IF(@@ROWCOUNT = 0) RETURN

	UPDATE b
	SET modds = t.modds 
		,@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN '0' THEN 1
			WHEN '1' THEN 0
			ELSE 1
			END
		,@commLostRate = CASE comstatus
			WHEN '0' THEN 1
			WHEN '1' THEN 2
			ELSE 1
			END
		,WinLost = CASE 
			WHEN t.modds >= 0.5 THEN actual_stake + stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE odds END
					) -- WIN                
			WHEN t.modds <= - 0.5 THEN 0 -- LOSE    
			WHEN t.modds IS NULL THEN winlost
			END
		,aWinLost = CASE 
			WHEN  t.modds >= 0.5 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE odds END
					) * - apositiontaking
			WHEN t.modds <= - 0.5 THEN actual_stake * apositiontaking
			WHEN t.modds IS NULL THEN awinlost
			END
		,mWinLost = CASE 
			WHEN t.modds >= 0.5 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE odds END
					) * - mpositiontaking
			WHEN t.modds <= - 0.5 THEN actual_stake * mpositiontaking
			WHEN t.modds IS NULL THEN mwinlost
			END
		,sWinLost = CASE 
			WHEN t.modds >= 0.5 THEN stake * (CASE 
					WHEN odds < 0 THEN 1
					ELSE odds END
					) * - spositiontaking
			WHEN t.modds <= - 0.5 THEN actual_stake * spositiontaking
			WHEN t.modds IS NULL THEN swinlost
			END
		,PlayerComm = CASE 
			WHEN t.modds >= 0.5 THEN @commWinRate * playerdiscount * stake
			WHEN t.modds <= - 0.5 THEN @commLostRate * playerdiscount * stake
			WHEN t.modds IS NULL THEN playercomm
			END
		,Comm = CASE 
			WHEN t.modds >= 0.5 THEN @commWinRate * discount * stake * (1 - apositiontaking)
			WHEN t.modds <= - 0.5 THEN @commLostRate * discount * stake * (1 - apositiontaking)
			WHEN t.modds IS NULL THEN comm
			END
		,aComm = CASE 
			WHEN t.modds >= 0.5 THEN @commWinRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
			WHEN t.modds <= - 0.5 THEN @commLostRate * adiscount * stake * (1 - (mpositiontaking + apositiontaking))
			WHEN t.modds IS NULL THEN acomm
			END
		,sComm = CASE 
			WHEN t.modds >= 0.5 THEN @commWinRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
			WHEN t.modds <= - 0.5 THEN @commLostRate * sdiscount * stake * (1 - (spositiontaking + mpositiontaking + apositiontaking))
			WHEN t.modds IS NULL THEN scomm
			END
		,STATUS = CASE 
			WHEN t.modds >= 0.5 THEN N'WON'
			WHEN t.modds <= - 0.5 THEN N'LOSE'
			WHEN t.modds IS NULL THEN status
			END
		,StatusID = CASE 
			WHEN t.modds >= 0.5 THEN 112 --WON
			WHEN t.modds <= - 0.5 THEN 113 --LOSE
			WHEN t.modds IS NULL THEN statusID
			END
		,ruben = CASE WHEN t.modds IS NULL THEN ruben
					  ELSE 1
				 END
	FROM dbo.bettrans b WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #instantTicket t
		ON b.transid = t.transid
	
	DROP TABLE #instantTicket;
	RETURN;
	
END
