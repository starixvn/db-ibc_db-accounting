/*<info serverAlias="DBRMS-bodb_RMS" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Get_SystemSettings]
(
	@VName VARCHAR(50)
)

RETURNS VARCHAR(200)
AS

/*
	Created: 20191212@Percy
	DB: DBACC.bodb02, DBAGE.bodb02, DBWH.bodb02, DBBOF.bodb02, DBRMS.bodb_RMS
	Task: Get VValue from local SystemSettings by VName

	Revisions:
		- 20191212@Percy: Initialize function [RedmineID: #122071]
*/

BEGIN
	DECLARE @VValue VARCHAR(200)
	SELECT  @VValue = VValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE VName = @VName
	
	RETURN  @VValue
END
GO