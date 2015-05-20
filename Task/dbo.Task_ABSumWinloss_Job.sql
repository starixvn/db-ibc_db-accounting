IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'Stored_Procedure_Name')
	BEGIN
		DROP  Procedure  Stored_Procedure_Name
	END

GO

CREATE Procedure Stored_Procedure_Name
/*
	(
		@parameter1 int = 5,
		@parameter2 datatype OUTPUT
	)

*/
AS


GO

/*
GRANT EXEC ON Stored_Procedure_Name TO PUBLIC

GO
*/

