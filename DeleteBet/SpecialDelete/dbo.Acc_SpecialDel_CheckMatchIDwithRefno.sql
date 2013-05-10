ALTER PROCEDURE dbo.Acc_SpecialDel_CheckMatchIDwithRefno
	@MatchID int
	,@FromRefno bigint --transid
	,@ToRefno bigint --transid
	,@Type SMALLINT = 0
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
    ,@ErrCode INT = 0 OUTPUT
AS
BEGIN
/*
	Created by: 
	Date: 20110906
	Task: check constraint between refno and matchid
	DB: DB053.BODB02	
	Original: 
	
	Revisions:
		- 20110908@Jamie: correct sp according to business rule	
		- 20110914@Jamie: correct sp to cover case of @FromRefno=@ToRefno
		- 20120829@Elodie: Check if the match belongs to virtual sport
						   Change DB053 server instead of DB052 server
	
	Param's Explanation:	
		- @Type: sports type
			0: Sportsbook
			1: Virtual sports
			2: Number Game
			3: Live Casino
*/
	SET NOCOUNT ON
	DECLARE @totalRecord INT, @Sporttype int
		
	select @Sporttype = sporttype
	from match with (NOLOCK)
	where matchid = @MatchID
	
	IF @Sporttype not between 1 and 99 AND @Type = 0
	BEGIN 
		SET @ErrCode = 2
		SET @ErrMsg ='This MatchID doesn''t belong to sportbook.' 
		RETURN
	END 
	
	IF @Sporttype not between 180 and 186 AND @Type = 1
	BEGIN 
		SET @ErrCode = 3
		SET @ErrMsg ='This MatchID doesn''t belong to virtual sports.' 
		RETURN
	END 
	
	IF @Sporttype <> 161 AND @Type = 2
	BEGIN 
		SET @ErrCode = 4
		SET @ErrMsg ='This MatchID doesn''t belong to number game.' 
		RETURN
	END 
	
	IF @Sporttype <> 162 AND @Type = 3
	BEGIN 
		SET @ErrCode = 5
		SET @ErrMsg ='This MatchID doesn''t belong to live casino.' 
		RETURN
	END 
	
	SELECT @totalRecord = count(1)
	FROM dbo.bettrans WITH (NOLOCK)		
	WHERE transid IN (@FromRefno,@ToRefno)
		AND matchid = @MatchID	
	
	IF @FromRefno=@ToRefno
	BEGIN
		IF @totalRecord <> 1 
			SELECT @ErrCode=1
				,@ErrMsg='You have entered an invalid matchId or refno.'
	END
	ELSE IF @totalRecord <> 2 
		SELECT @ErrCode=1
			,@ErrMsg='You have entered an invalid matchId or refno.'
	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON dbo.Acc_SpecialDel_CheckMatchIDwithRefno TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON dbo.Acc_SpecialDel_CheckMatchIDwithRefno TO vnteam
