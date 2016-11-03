
ALTER FUNCTION [dbo].[f_GetChars] (
  @data varchar(50)
) RETURNS TABLE
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
RETURN (
	WITH dataTmp AS (
		SELECT 0 AS pos, CAST(SUBSTRING(@data, 1, 1) AS TINYINT) AS ResultStatus
		UNION ALL
		SELECT pos + 1, CAST(SUBSTRING(@data, pos + 2, 1) AS TINYINT)
		FROM dataTmp 
		WHERE pos + 1 < DATALENGTH(@data)
	)
	SELECT pos, ResultStatus FROM dataTmp
)
