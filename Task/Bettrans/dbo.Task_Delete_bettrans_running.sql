select *
from bettype


/****** Object:  StoredProcedure [dbo].[Task_Delete_bettrans_running]    Script Date: 01/24/2013 00:29:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Delete_bettrans_running]
AS

/*
Created: 
Task : 
DB: DBAGE/bodb_AGE
Original:

Revisions:
	- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
	
Param's Explanation: 

*/	

DELETE TOP(500)
FROM dbo.bettrans_running_toDelete

IF @@ROWCOUNT = 0
	WAITFOR DELAY '00:00:15.000'