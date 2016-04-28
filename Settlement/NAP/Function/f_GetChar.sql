ALTER FUNCTION [dbo].[f_GetChar] (
  @data varchar(50),
  @pos int
) RETURNS tinyint 
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
BEGIN
  SET @pos += CASE WHEN @pos >= 45 THEN -44 ELSE 1 END -- OffSet Minute Index
  Declare @Char char(1)
  IF @pos <= 0 OR @pos > DATALENGTH(@data)
    SET @Char = '0'
  ELSE
    SET @Char = SUBSTRING(@data, @pos, 1)

  RETURN @Char
END