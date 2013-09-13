ALTER  PROCEDURE [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTableSel
    @GameTypeID int = 0,
	@ExcludeTest bit = 0
AS
SET NOCOUNT ON
/*
Created by: Daniel
Date: 2012-02-17
Task : Retrieve all game tables for Live Casino
DB: DB06.bodb02
Original:

Revisions:
	-20120910@Jim: change to use leaguenametc column for support live casino

*/
SET NOCOUNT ON



if @GameTypeID = 0
BEGIN
    SELECT	leagueid GameTableID, leaguename GameTable
    FROM	league WITH (NOLOCK)
    WHERE	sporttype = 162
		AND (@ExcludeTest = 0 OR isTest = @ExcludeTest)
    ORDER BY leagueid ASC
END
ELSE
BEGIN
    
    SELECT	leagueid GameTableID, leaguename GameTable
    FROM	league WITH (NOLOCK)
    WHERE	sporttype = 162
      AND leaguenametc =convert(char,@GameTypeID )
	  AND (@ExcludeTest = 0 OR isTest = @ExcludeTest)
    ORDER BY leagueid ASC
END

GO
GRANT EXECUTE ON [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTableSel TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_Rpt_LiveCasino_GameStatistics_GameTableSel TO [vnteam]


declare @dt datetime
set @dt = '20130101'

select
	DT = @dt,
	[Days in Month] =day(dateadd(mm,datediff(mm,-1,@dt),-1))