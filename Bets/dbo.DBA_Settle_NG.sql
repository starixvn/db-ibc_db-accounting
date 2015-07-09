ALTER PROCEDURE [dbo].[DBA_Settle_NG]
	@matchid int,
	@ResultString nvarchar(50)
AS
BEGIN

/*
Created: PhuongDao
DATE : 2009-02-06
Task : Settlement for NEXT GOAL
DB: DBTRANS.bodb02
Original: 

Revisions: 
- 20110826@Sophia: add linked server DB02

*/

	SET NOCOUNT ON;
	DECLARE @length int, @FinalHomeScore int , @FinalAwayScore int , @i int , @str nvarchar(1), @num_a int, @num_h int
	SELECT @length = len(@ResultString), @i = 0 
	IF @length = 0 SELECT @FinalHomeScore = 0 ,  @FinalAwayScore = 0 
	ELSE 
	BEGIN 
		WHILE (@i < @length)
		BEGIN 
			set @str = SUBSTRING(@ResultString,@i,1)
			if @str ='a' SET @num_a = @num_a + 1 
			else SET @num_h = @num_h + 1 
			SET @i = @i + 1 
		END 
	END 
	SELECT @FinalHomeScore = @num_a , @FinalAwayScore = @num_h 
	UPDATE DB02.BODB02.dbo.Match SET GoalRecord = @ResultString, FinalHomeScore= @FinalHomeScore, FinalAwayScore = @FinalAwayScore, eventstatus='completed'
	WHERE matchid = @matchid 

	EXEC [dbo].[Admin_Settlement_3]  8, @matchid 
END
GO

