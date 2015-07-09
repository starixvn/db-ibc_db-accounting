USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[ExecRep_09]    Script Date: 05/23/2011 05:47:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_09]
	@recommend int,
	@winlostdate smalldatetime,
	@parlay bit = 0
AS
/*
Created by:[]
Date:
Task: 
DB: DB02.BODB02
Revisions:
	--Thien@20100207: manipulate the flag isMovingBet on DB06.bodb02.dbo.SystemSettings for Parlay settlement
    - 20110523@Henry: change bettype to new range
    - 20120209@Sophia: Add table bettransg for Live Casino
 */


DELETE FROM bettrans
WHERE recommend = @recommend AND winlostdate = @winlostdate AND bettype <= 19000

IF @parlay = 1
BEGIN
	DELETE FROM bettransm
	--FROM bettransm , custinfo
	WHERE --bettransm.custid = custinfo.custid
		--AND recommend = @recommend AND 
		winlostdate = @winlostdate
		
	DELETE FROM bettransg
	WHERE  winlostdate = @winlostdate
	
	
	--set FALSE for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
	--to allow the Mix Parlay calculation again
	IF @@SERVERNAME = 'DB06'
	BEGIN
		if exists (select * from dbo.sysobjects where name = 'SystemSettings')
		BEGIN
			UPDATE SystemSettings set VValue = 0 where VName = 'isMovingBet'
		END
	END
END



GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_09] TO [vnteam]