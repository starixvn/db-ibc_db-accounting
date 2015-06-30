 USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectDate]    Script Date: 03/30/2013 23:50:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectDate]
AS
SET NOCOUNT ON

Declare @minDate smalldatetime,
	@maxDate smalldatetime

select @maxDate = max(winlostdate) from bettrans_bk with (nolock)

select @minDate = max(winlostdate)
from Task_ArchiveDate with (nolock)
--where isDone = 1

if datediff(d, @minDate, @maxDate) <> 7
BEGIN
	RaisError ('Wrong date count!!! Or already done the second balance up!!', 16, 1)
	RETURN
END

;With Calendar As
    (
    Select DateAdd(d,1,@minDate) As [Date]
    Union All
    Select DateAdd(d,1,[Date])
    From Calendar
    Where [Date] < @maxDate
    )
INSERT INTO Task_ArchiveDate (winlostdate)
Select [Date]
From Calendar    
Option ( Maxrecursion 0 );
