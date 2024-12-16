ALTER FUNCTION  [dbo].[strSplitResult] (@string NVARCHAR(4000), @BeforeSplitter NVARCHAR(20), @AfterSplitter CHAR(1)=' ')
RETURNS NVARCHAR(20)
AS
BEGIN	
	DECLARE @index INT
	SET @string=LTRIM(@string)
	SET @index=CHARINDEX(@BeforeSplitter, @string)
	IF @index=0
		RETURN ''

	DECLARE @res NVARCHAR(20)
	SET @res = SUBSTRING(@string, @index+LEN(@BeforeSplitter), 20)
	SET @index = CHARINDEX(@AfterSplitter, @res)
	RETURN SUBSTRING(@res,0,@index)
END
GO
GRANT VIEW DEFINITION ON [dbo].[strSplitResult] TO [vnteam]
