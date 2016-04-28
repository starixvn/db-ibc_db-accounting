ALTER FUNCTION [dbo].[f_GetChars] (
  @data varchar(50)
) RETURNS @res TABLE (pos tinyint, ResultStatus tinyint)
AS
/*
	DB: DBPROD.BODB02/DBTXN.BODB02
*/
BEGIN
  DECLARE @pos tinyint
  SET @pos = 1

  IF DATALENGTH(@data) > 0
    WHILE @pos <= DATALENGTH(@data)
    BEGIN
      INSERT INTO @res VALUES (@pos-1, SUBSTRING(@data, @pos, 1))
      SET @pos = @pos + 1
    END

  RETURN
END