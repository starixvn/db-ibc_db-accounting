ALTER FUNCTION [dbo].[f_CurrencyBySystem]
(
	@System varchar(50) = 'ACCOUNTING'
)
	
	RETURNS @tbCurrency table (exchangeID  int PRIMARY KEY)
AS

/*
Created: 
Task : Get currencies by system
DB:   DBTXN/bodb02; DBAGE/bodb02

Revisions:
	- 20100720@Shifu: Get currencies by System
	- 20101119@Henry: Add ACCINDO
	- 20110908@Johnson: Add two system ACCYEN789, ACCYEN889
	- 20111122@Johnson: Add ACCDDD system
	- 20120809@Elodie: Add ACCIRR system
	- 2O130404@Jamie: Put UUS for Testing 
	- 20130513@Lukas: add group ACCUSD
	- 20130718@Lukas: add group ACCUT
	- 20130909@Jamie: add group ACCYEN668
Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING', 'ACCINDO'
*/

BEGIN
	IF (@System = 'ACCOUNTING')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		Select ExchangeID 
		From Exchange (nolock)
	END
	ELSE IF(@System = 'ACCTHAI')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 43 --THB,...
	END
	ELSE IF (@System = 'ACCINDO')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 47 --DDD
		UNION SELECT 15 --IN
	END	
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668'))
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 16 --YEN		
	END	
	ELSE IF (@System = 'ACCNTD')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 17 --NTD		
	END
	ELSE IF (@system = 'ACCDDD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 47 --DDD
	END
	ELSE IF (@system = 'ACCIRR')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 40 --IRR
	END
	ELSE IF (@system = 'ACCUUS')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 20 --UUS
	END
	ELSE IF (@system = 'ACCUSD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 16	--- 	Yen
		UNION ALL SELECT 17	--- 	NTD
		UNION ALL SELECT 35	--- 	$US
		UNION ALL SELECT 40	--- 	IRR
		UNION ALL SELECT 64 ---		UT
	END
	ELSE IF (@system = 'ACCUT')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 64	--- 	UT		
	END
	Return
END

GO
GRANT VIEW DEFINITION ON [dbo].[f_CurrencyBySystem] TO [vnteam]
GO
GRANT SELECT ON [dbo].[f_CurrencyBySystem] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[f_CurrencyBySystem] TO [bodbExtAccNet]