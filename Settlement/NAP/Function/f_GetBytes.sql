ALTER FUNCTION [dbo].[f_GetBytes] (		
  @data VARCHAR(50)		
) RETURNS @res TABLE (pos TINYINT, bitmap TINYINT)		
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
BEGIN		
	DECLARE @pos TINYINT		
	SET @pos = 1		
		
	IF DATALENGTH(@data) > 0		
	WHILE @pos <= DATALENGTH(@data)		
	BEGIN		
		INSERT INTO @res VALUES (@pos-1, ASCII(SUBSTRING(@data, @pos, 1)))		
		SET @pos = @pos + 1		
	END		
		
	RETURN
END		