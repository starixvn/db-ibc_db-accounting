USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_MoveIndex]    Script Date: 12/01/2009 23:19:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_MoveIndex]
AS
/*		
	DB: All servers.bodb02 (DB02, DB03, DB053, DB052, DB054, DB06, DB07)
	
*/
CREATE UNIQUE INDEX "IX_bettrans_2" ON "dbo"."bettrans" ("transid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE UNIQUE INDEX "PK_bettrans" ON "dbo"."bettrans" ("refno") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_bettrans" ON "dbo"."bettrans" ("custid", "matchid", "winlostdate") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_bettrans_3" ON "dbo"."bettrans" ("betid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_bettrans_4" ON "dbo"."bettrans" ("betdaqid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE UNIQUE INDEX "PK_bettransm" ON "dbo"."bettransm" ("transid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_bettransm_1" ON "dbo"."bettransm" ("matchid", "oddsid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_bettransm_2" ON "dbo"."bettransm" ("refno") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_match" ON "dbo"."match" ("leagueid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_match_1" ON "dbo"."match" ("homeid", "awayid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_match_2" ON "dbo"."match" ("awayid", "homeid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_match_3" ON "dbo"."match" ("kickofftime") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE UNIQUE INDEX "PK_odds" ON "dbo"."odds" ("oddsid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[custaccount]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
CREATE UNIQUE INDEX "PK_custaccount" ON "dbo"."custaccount" ("custaccid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_custaccount_2" ON "dbo"."custaccount" ("transcode", "transtype") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
END
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[zzzbettrans]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
BEGIN
CREATE UNIQUE INDEX "PK_zzzbettrans" ON "dbo"."zzzbettrans" ("keyid") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
CREATE INDEX "IX_zzzbettrans_1" ON "dbo"."zzzbettrans" ("oddsid", "bettype") WITH FILLFACTOR = 80 ,DROP_EXISTING ON "INDEX"
END
DECLARE @db_id int, @tbl_id int
SET @db_id = DB_ID('bodb02')
SET @tbl_id = OBJECT_ID('bodb02.dbo.exchange')
DBCC PINTABLE (@db_id, @tbl_id)
SET @db_id = DB_ID('bodb02')
SET @tbl_id = OBJECT_ID('bodb02.dbo.bettype')
DBCC PINTABLE (@db_id, @tbl_id)
