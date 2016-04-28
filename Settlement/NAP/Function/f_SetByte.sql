ALTER FUNCTION [dbo].[f_SetByte] (@data VARCHAR(50)
	, @pos INT -- minute to store
	, @byte TINYINT -- bitmap value convert to Decimal
) RETURNS VARCHAR(50)
AS
/*
	DB: DBPRO.BODB02
*/
BEGIN
	SET @pos += CASE WHEN @pos >= 45 THEN -44 ELSE 1 END -- OffSet Minute Index
	IF @pos > 0
	BEGIN
		IF @data IS NULL SET @data = ''
		IF @pos <= DATALENGTH(@data)
			SET @data = LEFT(@data,@pos-1) + CHAR(@byte) + SUBSTRING(@data,@pos+1,50)
		ELSE
			SET @data = @data + REPLACE(SPACE(@pos - DATALENGTH(@data)-1),' ',CHAR(0)) + CHAR(@byte)
	END

	RETURN @data
END