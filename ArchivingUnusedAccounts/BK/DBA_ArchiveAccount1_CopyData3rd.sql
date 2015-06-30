ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_CopyData3rd]
	@index	INT,
	@Step	INT
AS
/*
	Created by: Jamie
	Date: 2009-12-24
	Task: Move 3rd data from custsetting_old to custsetting3rd_old
	DB: DB05.bodb_Customer
*/
BEGIN
	INSERT INTO CustSetting3rd_old (
		   [custid]
		  ,[bettype]
		  ,[sporttype]
		  ,[apositiontaking]
		  ,[mpositiontaking]
		  ,[spositiontaking]
		  ,[playerdiscount]
		  ,[discount]
		  ,[adiscount]
		  ,[sdiscount]
		  ,[minbet]
		  ,[maxbet]
		  ,[autopositiontaking]
		  ,[isautopositiontaking]
		  ,[autompositiontaking]
		  ,[isautompositiontaking]
		  ,[alivepositiontaking]
          ,[mlivepositiontaking]
          ,[slivepositiontaking]
          ,[autolivepositiontaking]
          ,[isautolivepositiontaking]
          ,[autolivempositiontaking]
          ,[isautolivempositiontaking]
	)
	SELECT 
		   [custid]
		  ,[bettype]
		  ,[sporttype]
		  ,[apositiontaking]
		  ,[mpositiontaking]
		  ,[spositiontaking]
		  ,[playerdiscount]
		  ,[discount]
		  ,[adiscount]
		  ,[sdiscount]
		  ,[minbet]
		  ,[maxbet]
		  ,[autopositiontaking]
		  ,[isautopositiontaking]
		  ,[autompositiontaking]
		  ,[isautompositiontaking]
		  ,[alivepositiontaking]
          ,[mlivepositiontaking]
          ,[slivepositiontaking]
          ,[autolivepositiontaking]
          ,[isautolivepositiontaking]
          ,[autolivempositiontaking]
          ,[isautolivempositiontaking]
	FROM	CustSetting_old WITH (NOLOCK)
	WHERE	sporttype IN (151,201)
			AND bettype IN (2,3,31,32,41,42)
			AND custid BETWEEN @Step*@index + 1 AND @Step*(@index + 1)
END 
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount1_CopyData3rd] TO [VNTeam]
GO