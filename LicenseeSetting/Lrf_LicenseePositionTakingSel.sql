ALTER PROCEDURE [dbo].[Lrf_LicenseePositionTakingSel] 
	@CustID INT
	,@Product INT
AS
/*
	Created: Elodie
	Date: 20150121
	Task : Licensee Setting Configuration - Get Position taking [#6304]
	DB: DBAGE/bodb02
	Original:

	Revisions:

	Param's Explanation:
		@Product:	1: Sportbook
					161: Number Game
					180: Virtual sport
					162: Live Casino
					202: Keno
	Example: EXEC Lrf_LicenseePositionTakingSel @CustID = 16947245, @Product = 202	
*/ 
BEGIN
	SET NOCOUNT ON
	DECLARE @ptValue MONEY

	IF @Product = 1 --Sportbook
	BEGIN
		SELECT @ptValue = spositiontaking FROM Dep_CustSetting AS cs WITH (NOLOCK) WHERE cs.custid = @CustID AND cs.bettype =  1 AND cs.sporttype = 1
	END
	
	IF @Product = 161 --Number Game 
	BEGIN
		SELECT @ptValue = spositiontaking FROM Dep_CustSetting3rd AS cs WITH (NOLOCK) WHERE cs.custid = @CustID and cs.bettype = 81 and cs.sporttype=161
	END

	IF @Product = 162 --Live Casino
	BEGIN
		SELECT @ptValue = csg.spositiontaking FROM CustSettingGame csg WITH(NOLOCK) WHERE csg.custid = @CustID AND csg.sporttype = 162 AND csg.bettype = 1101
	END

	IF @Product = 180 --Virtual Sports
	BEGIN
		SELECT @ptValue = cs3.spositiontaking FROM Dep_CustSetting3rd cs3 WITH(NOLOCK) WHERE cs3.custid = @CustID AND cs3.sporttype = 180 AND cs3.bettype = 1201
	END

	IF @Product = 202 --Keno
	BEGIN
		SELECT @ptValue = csg.spositiontaking FROM CustSettingGame csg WITH(NOLOCK) WHERE csg.custid = @CustID AND csg.sporttype = 202 AND csg.bettype = 1501
	END 
	SELECT @ptValue
END
	
GO 
GRANT VIEW DEFINITION ON [dbo].[Lrf_LicenseePositionTakingSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Lrf_LicenseePositionTakingSel] TO [bodbAdminNet]
GO 

