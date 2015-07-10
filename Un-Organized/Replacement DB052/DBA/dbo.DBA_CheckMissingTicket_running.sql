USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CheckMissingTicket_running]    Script Date: 12/13/2012 03:39:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CheckMissingTicket_running] 
	@matchid int, 
	@isFirstHalf bit = 0
AS
/*
Created: 
Task : checking missing running ticket of a match on all servers
DB: DBTRANS.bodb02
Original:

Revisions:
	- 20121213@Dan: Change linked server from DB052-->DBEXT
Param's Explanation:
• @ErrCode:
    = 0: UPDATE successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

declare @countDBTrans int, 
	@countDB052 int, 
	@countDB053 int, 
	@countDB06 int,
	@countDB04 int, 
	@countDB042 int, 
	@countDB054 int

IF @isFirstHalf = 0
BEGIN
	SELECT @countDBTrans = COUNT(1) FROM bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB052 = COUNT(1) FROM DBEXT.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB053 = COUNT(1) FROM DB053.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB06 = COUNT(1) FROM DB06.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB04 = COUNT(1) FROM DB04.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB042 = COUNT(1) FROM DB042.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
	SELECT @countDB054 = COUNT(1) FROM DB054.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and statusid = 0
END
ELSE
BEGIN
	SELECT @countDBTrans = COUNT(1) FROM bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB052 = COUNT(1) FROM DBEXT.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB053 = COUNT(1) FROM DB053.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB06 = COUNT(1) FROM DB06.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB04 = COUNT(1) FROM DB04.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB042 = COUNT(1) FROM DB042.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
	SELECT @countDB054 = COUNT(1) FROM DB054.bodb02.dbo.bettrans WITH (nolock) WHERE matchid = @matchid and bettype in (7,8,12,15,21) and statusid = 0
END

SELECT  @countDBTrans DBTrans , @countDB052 DB052, @countDB053 DB053, @countDB06  DB06, @countDB04 DB04 , @countDB042 DB042, @countDB054 DB054





