USE [bodb02]
GO

CHECKPOINT 
GO

DECLARE @intDBID INTEGER 
SET @intDBID = DB_ID()

DBCC FLUSHPROCINDB (@intDBID)
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
/*
*later, in case of slow.  after check the performance monitor.
maybe try this one, and see the effect
*main command is DROPCLEANBUFFERS
*this will remove all contents in SQL memory (which already commit trans)
Thien says:
*ok, if these command cannot solve, then should consider to restart the SQL service?
Joe : Case Closed ? says:
*if it's a case..
yes.  maybe need to consider restart SQL Engine of DB06  as routine.  (daily or every X days)
*/