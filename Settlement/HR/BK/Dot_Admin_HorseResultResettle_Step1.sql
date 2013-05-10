ALTER PROCEDURE [dbo].[Dot_Admin_HorseResultResettle_Step1]
 @HorseDate datetime,
 @ProgramID varchar(10),
 @GroupMatch varchar(20),
 @creator int = 0
AS
/*
 20111019@AllenWu(TransDB): userlog support dog racing (152)
    20111122@AllenWu(TransDB): Bug fix for leagueid
*/
BEGIN

 -- get sport type 
 declare @sport int
 select @sport=l.sporttype
 from league (nolock) l
 where l.ProgramID = @ProgramID

 if(@sport is null)
  set @sport=151

 -- log action
 DECLARE @LogData nvarchar(300)
 SET @LogData = 'Calculate Result (redo settlement by admin userid:' + CAST(@creator as varchar(20)) + ') for Program ID:' + @ProgramID + ' eventdate:' + CAST(@HorseDate as nvarchar(20)) + ' race:' + @GroupMatch
 EXEC dbo.LogFile @sport, @LogData

 -- delete horse dummy account
 EXEC Dot_Acc_Race_DummyDel @programID = @ProgramID, 
        @eventdate = @HorseDate, 
        @raceNumber = @GroupMatch
END 