USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_Statement]    Script Date: 05/23/2011 05:57:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_Statement]
	@winlostdate datetime
AS
/*
Created by:[]
Date:
Task: 
DB: DB06.BODB02
Revisions:
    - 20110523@Henry: change bettype to new range
    
 */
-- Member - winlost & commission
INSERT INTO bodb_Report.dbo.statement
	select custid,winlostdate accdate,sum(winlost-actual_stake) totalamt,'BET' transtype, 'Betting' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,custid
	--HAVING sum(winlost-actual_stake) <> 0

INSERT INTO bodb_Report.dbo.statement
	select custid,winlostdate accdate,sum(playercomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans  with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,custid
	HAVING sum(playercomm) <> 0

-- Agent - position & commission
INSERT INTO bodb_Report.dbo.statement
	select recommend,winlostdate accdate,sum(awinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,recommend
	HAVING sum(awinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select recommend,winlostdate accdate,sum(comm-playercomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans  with (nolock)
	where bettype  <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,recommend
	HAVING sum(comm-playercomm) <> 0

-- Master - position & commission
INSERT INTO bodb_Report.dbo.statement
	select mrecommend,winlostdate accdate,sum(mwinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,mrecommend
	HAVING sum(mwinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select mrecommend,winlostdate accdate,sum(acomm-comm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,mrecommend
	HAVING sum(acomm-comm) <> 0

-- Super - position & commission
INSERT INTO bodb_Report.dbo.statement
	select srecommend,winlostdate accdate,sum(swinlost) totalamt,'POS' transtype, 'Position' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,srecommend
	HAVING sum(swinlost) <> 0

INSERT INTO bodb_Report.dbo.statement
	select srecommend,winlostdate accdate,sum(scomm-acomm) totalamt,'COM' transtype, 'Commission' transdesc
	from bettrans14 bettrans with (nolock)
	where bettype <= 19999
	and winlostdate = @winlostdate
	group by winlostdate,srecommend
	HAVING sum(scomm-acomm) <> 0

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Archive_Statement] TO [vnteam]