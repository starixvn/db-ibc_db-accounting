USE [bodb02]
GO
/****** Object:  UserDefinedFunction [dbo].[f_GetParamsList]    Script Date: 11/05/2009 06:51:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[f_GetParamsList]
(
	@tablename VARCHAR(50), @prefix VARCHAR(3)
)
RETURNS VARCHAR(4000)
AS
BEGIN

DECLARE @ParamsList VARCHAR(4000), @first BIT
SELECT @ParamsList = '', @first = null

SELECT 
	@ParamsList = @ParamsList + CASE WHEN @first IS NULL THEN '' ELSE ',' END + @prefix + d.name, @first = 0
FROM 
(	
select sc.name name
from
db02vn.bodb02_tmp.sys.tables st INNER JOIN db02vn.bodb02_tmp.sys.columns sc ON st.OBJECT_ID = sc.OBJECT_ID
WHERE st.name = @tablename and sc.system_type_id <> 189
)s inner join 
(
select dc.name name
from sys.tables dt INNER JOIN sys.columns dc on dt.OBJECT_ID = dc.OBJECT_ID 
WHERE dt.name = @tablename and dc.system_type_id <> 189
)d on s.name = d.name
order by d.name

RETURN @ParamsList
END

