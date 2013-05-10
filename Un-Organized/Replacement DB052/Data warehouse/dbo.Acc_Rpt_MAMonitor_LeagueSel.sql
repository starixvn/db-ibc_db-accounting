USE [bodb_dwrs]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Rpt_MAMonitor_LeagueSel]    Script Date: 12/13/2012 04:00:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_Rpt_MAMonitor_LeagueSel]
    @fromdate datetime,
    @todate datetime,
	@currency smallint = 0,
	@sporttype smallint = 0,
	@bettype smallint = 0,
	@Live BIT = NULL,
    @major BIT = 1,
    @minor BIT = 1
WITH RECOMPILE
AS
 /*
Created: Daniel@20110325
Task : Retrieve active major leagues, minor leagues or both types base on pre-select conditions
DB: DBDW2.bodb_dwrs
Original: 

Revisions:
    Daniel@20110907: Categorize more major leagues + sort league by ABC
    Dan@20121213: Change linked server from DB052-->DBEXT    

Param explain:
 - @currency: 
    0: All currency
    >0: Filter by currencyID
 - @sporttype: For SB product only
    0: All sports
    >0: filter by sportid
 - @bettype:
    0: All bet types
    >0: filter by bettype   
 - @live:
    NULL: ALL
    0: Non-live
    1: Live

 - @major: 1: include major leagues
 - @minor: 1: include minor leagues
  Major: 
    a) English Premier League - 3
    b) Germany-Bundesliga I - 5
    c) Italy Serie A - 4
    d) Spain Primera Laliga - 43
    e) UEFA Champions League - 1837
 
 */
set nocount on

declare @leagues table(leagueid int)

--cache parameters to avoid slow loading on web
DECLARE
    @_fromdate datetime,
    @_todate datetime,
	@_currency smallint,
	@_sporttype smallint,
	@_bettype smallint,
	@_Live BIT,
    @_major BIT,
    @_minor BIT

select 
    @_fromdate = @fromdate,
    @_todate = @todate,
	@_currency = @currency,
	@_sporttype = @sporttype,
	@_bettype = @bettype,
	@_Live = @Live ,
    @_major = @major,
    @_minor = @minor





if (@_major = 1)
	insert into @leagues
	select leagueid from DBEXT.bodb02.dbo.league with (nolock) 
	where sporttype = case when @_sporttype = 0 then sporttype else @_sporttype end
		and leagueid IN(3, 5, 4, 43, 1837)

if (@minor = 1)
	insert into @leagues
	select  distinct l.leagueid
	from DBEXT.bodb02.dbo.league l with (nolock) 
		left join bodb_account.dbo.rptleague b with (nolock) on l.leagueid = b.leagueid
	where rptdate between @_fromdate and @_todate
		and currency = case when @_currency = 0 then currency else @_currency end
		and sporttype = case when @_sporttype = 0 then sporttype else @_sporttype end
		and sporttype < 151
		and bettype = case when @_bettype = 0 then bettype else @_bettype end
		and IsLive = isnull(@_live, IsLive)
		and l.leagueid NOT IN(3, 5, 4, 43, 1837)
		and l.leagueid > 0

select leagueid from @leagues
 
