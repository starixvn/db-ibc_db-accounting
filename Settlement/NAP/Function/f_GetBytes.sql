
ALTER FUNCTION [dbo].[f_GetBytes] (		
  @data VARCHAR(50)		
) RETURNS TABLE
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
RETURN (
	WITH dataTmp AS (
		SELECT 0 AS pos, ASCII(SUBSTRING(@data, 1, 1)) AS bitmap
		UNION ALL
		SELECT pos + 1, ASCII(SUBSTRING(@data, pos + 2, 1))
		FROM dataTmp 
		WHERE pos + 1 < DATALENGTH(@data)
	)
	SELECT pos, bitmap
	FROM dataTmp
)	