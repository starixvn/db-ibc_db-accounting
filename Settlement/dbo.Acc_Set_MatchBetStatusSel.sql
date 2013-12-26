ALTER PROCEDURE dbo.Acc_Set_MatchBetStatusSel
	@matchid VARCHAR(max),
	@betstatus VARCHAR(8000) = '' OUTPUT
AS
	/*
		Crated: Johnson
		Date: 20131216
		Task: Get bet status on match
		DB: DBTXN/bodb02

		Revisions:

		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @intDocHandle INT

	--Create an internal representation of the XML document.      
	EXEC sp_xml_preparedocument @intDocHandle OUTPUT, @matchid
	
	;WITH t AS
	(
		SELECT matchid , COUNT(1) AS cnt
		FROM dbo.bettrans WITH(NOLOCK)
		WHERE matchid IN (
							SELECT matchid
							FROM OPENXML(@intDocHandle,'/root/match',2)
							with (matchid INT) 
						)
			AND bettype = 14
		GROUP BY matchid 
	)

	SELECT @betstatus = (
		SELECT * 
		FROM t
		FOR XML PATH('match'), ROOT('root')
	)
	
END



		
 