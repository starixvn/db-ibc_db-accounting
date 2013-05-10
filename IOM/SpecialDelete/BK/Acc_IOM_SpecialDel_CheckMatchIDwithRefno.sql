 ALTER PROCEDURE dbo.Acc_IOM_SpecialDel_CheckMatchIDwithRefno
	 @MatchID int
	,@FromRefno bigint --transid
	,@ToRefno bigint --transid
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
    ,@ErrCode INT = 0 OUTPUT
AS
BEGIN
/*
	Created by: Elodie
	Date: 20120705
	Task: check constraint between refno and matchid
	DB: DB053.BODB02	
	Original: Acc_SpecialDel_CheckMatchIDwithRefno
	
	Revisions:
	
	Param's Explanation:	

*/
	SET NOCOUNT ON
	DECLARE @totalRecord INT
		
	SELECT @totalRecord = count(1)
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE transid IN (@FromRefno,@ToRefno) AND matchid = @matchID

	IF @FromRefno=@ToRefno
	BEGIN
		IF @totalRecord <> 1 
			SELECT @ErrCode=1
				,@ErrMsg='You have entered an invalid matchId or refno'
	END
	ELSE IF @totalRecord <> 2 
		SELECT @ErrCode=1
			,@ErrMsg='You have entered an invalid matchId or refno'
	
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON dbo.Acc_IOM_SpecialDel_CheckMatchIDwithRefno TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON dbo.Acc_IOM_SpecialDel_CheckMatchIDwithRefno TO vnteam
go