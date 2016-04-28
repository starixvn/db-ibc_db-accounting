ALTER FUNCTION [dbo].[f_GetByte] (@data VARCHAR(50)
	, @pos INT
) RETURNS TINYINT 
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
BEGIN
	SET @pos += CASE WHEN @pos >= 45 THEN -44 ELSE 1 END -- OffSet Minute Index
	DECLARE @byte TINYINT
	IF @pos <= 0 OR @pos > DATALENGTH(@data)
		SET @byte = 0
	ELSE
		SET @byte = ASCII(SUBSTRING(@data, @pos, 1))

	RETURN @byte
END