USE [CustDB]
GO

CREATE PROCEDURE [dbo].[CS_ReportPermission_Update]
      @CustID INT
	, @IsViewAllPeriod BIT
AS
/*
	Created: Malcolm
	Date: 2020-01-21
	Task:   Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	DB: DBCUST/CustDB

	Revisions:
		- 20200121@Malcolm:  Configuration for CN88 Headlines to view all periods - [Redmine: #127520]
	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS(SELECT 1 FROM dbo.CS_ReportPermission WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN 
	     UPDATE CS
		 SET CS.IsViewAllPeriod = @IsViewAllPeriod
		 FROM dbo.CS_ReportPermission CS
		 WHERE CS.CustID = @CustID AND CS.IsViewAllPeriod <> @IsViewAllPeriod
	END
	ELSE 
	BEGIN
        INSERT INTO dbo.CS_ReportPermission(CustID, IsViewAllPeriod)
		VALUES(@CustID, @IsViewAllPeriod)
	END 
END
GO


