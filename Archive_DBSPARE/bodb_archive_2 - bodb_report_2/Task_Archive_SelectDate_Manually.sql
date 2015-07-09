 USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectDate_Manually]    Script Date: 03/30/2013 23:51:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectDate_Manually]
AS
SET NOCOUNT ON

Declare @minDate smalldatetime,
	@maxDate smalldatetime

--truncate table Task_ArchiveDate

select @minDate = '2013-03-01', @maxDate = '2013-03-15' 


;With Calendar As
    (
    Select @minDate As [Date]
    Union All
    Select DateAdd(d,1,[Date])
    From Calendar
    Where [Date] < @maxDate
    )
INSERT INTO Task_ArchiveDate (winlostdate)
Select [Date]
From Calendar    
Option ( Maxrecursion 0 );
