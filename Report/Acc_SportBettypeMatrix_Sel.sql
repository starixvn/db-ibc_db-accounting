/*<info serverAlias="DBAGE-bodb02,DBEXT-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbLicenseeNet,bodbExtAccNet,bodbRMSNet" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_SportBettypeMatrix_Sel]
	@Mode TINYINT=0
	,@ProductID TINYINT=0
	,@SportType SMALLINT=0
	,@BetType SMALLINT=0
	,@IsLive TINYINT=2
	,@SubProduct VARCHAR(500)=''
	,@ProductPrefix VARCHAR(500)=''
AS
	/*
		Created: Tom.Vo	
		Date: 2014.10.16
		Task: Get SportType_Bettype
		DB: DBACC/BODB02, DBAGE/BODB02, DBEXT/BODB02
		
		Revisions:
			- 20150418@Tom : Remove check enable on  [Enabled] column
			- 20150518@Sophia: Add @Mode = 5
			- 20151008@Sophia: Add test versions for UAT1, UAT2, UAT2, UAT4
		Paramters Explanation:
			@Mode: 
				0: Product ( ProductID,ProductName,ProductPrefix)
				1: SportType (ProductID,SportType)
				2: BetType (ProductID,SportType,BetType,EventType)
					- Get all : Live and Non-live
				3: BetType (ProductID,SportType,BetType,IsLive,EventType)
					- Get	: Live or Non-live
				4: BetType (ProductID,BetType,EventType)
					- Get all : Live or Non-live
				5: BetType (ProductID,BetType,EventType,SubProduct)
					- Get all : Live or Non-live
 
			@ProductID,@SportType,@BetType
				0	: get all
				<>0 : check condition
			@IsLive : check paramer which @mode > 0
				0	: None-live
				1	: Live
				2	: None-live & Live
			@ProductPrefix:
				''  : get all
				<>'': Check ProductPrefix column on dbo.Product table
	*/
BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT,@SQL NVARCHAR(100) = OBJECT_NAME(@@PROCID)

	IF  (@SQL like '%_xtest%' OR @SQL like '%_xpre%' OR @SQL like '%_UAT1%' OR @SQL like '%_UAT2%' OR @SQL like '%_UAT3%' OR @SQL like '%_UAT4%')
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 0
	END
	
	DECLARE @tblProductPrefix AS TABLE(ProductPrefix VARCHAR(10))

	IF ISNULL(@ProductPrefix,'')<>''
	BEGIN
		INSERT INTO @tblProductPrefix(ProductPrefix)
		SELECT val FROM dbo.strSplit (@ProductPrefix, ',')
	END

	IF @Mode = 0
	BEGIN
		SELECT p.ProductID
			,p.ProductName
			,p.ProductPrefix
		FROM dbo.Products p WITH(NOLOCK)			
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE (@ProductID = 0  OR p.ProductID = @ProductID)			
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
	ELSE IF @Mode = 1
	BEGIN
		SELECT DISTINCT ma.ProductID
			,ma.SportType
		FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
			INNER JOIN dbo.Products p WITH(NOLOCK)
				ON p.ProductID = ma.ProductID
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE (@ProductID = 0 OR ma.ProductID = @ProductID)
			AND (@SportType = 0 OR  ma.SportType = @SportType)
			AND (@IsLive = 2 OR  ma.IsLive = @IsLive)
			AND (@SubProduct = '' OR  ma.SubProduct = @SubProduct)			
			AND (ma.IsTest = 0 OR ma.IsTest = @isTest)
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
	ELSE IF @Mode = 2
	BEGIN
		SELECT DISTINCT ma.ProductID
			,ma.SportType
			,ma.BetType
			,ma.EventType
			,ma.SubProduct
		FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
			INNER JOIN dbo.Products p WITH(NOLOCK)
				ON p.ProductID = ma.ProductID
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE (@ProductID = 0 OR ma.ProductID = @ProductID)
			AND (@SportType = 0 OR  ma.SportType = @SportType)
			AND (@BetType = 0 OR  ma.BetType = @BetType)
			AND (@IsLive = 2 OR ma.IsLive = @IsLive)
			AND (@SubProduct = '' OR  ma.SubProduct = @SubProduct)
			AND (ma.IsTest = 0 OR ma.IsTest = @isTest)
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
	ELSE IF @Mode = 3
	BEGIN		
		SELECT DISTINCT ma.ProductID
			,ma.SportType
			,ma.BetType
			,ma.IsLive
			,ma.EventType
			,ma.SubProduct
		FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
			INNER JOIN dbo.Products p WITH(NOLOCK)
				ON p.ProductID = ma.ProductID
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE (@ProductID = 0 OR ma.ProductID = @ProductID)
			AND (@SportType = 0 OR  ma.SportType = @SportType)
			AND (@BetType = 0 OR  ma.BetType = @BetType)			
			AND (@IsLive = 2 OR  ma.IsLive = @IsLive)
			AND (@SubProduct = '' OR  ma.SubProduct = @SubProduct)
			AND (ma.IsTest = 0 OR ma.IsTest = @isTest)
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
	ELSE IF @Mode = 4
	BEGIN		
		SELECT DISTINCT ma.ProductID
			,ma.BetType
			,ma.EventType
		FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
			INNER JOIN dbo.Products p WITH(NOLOCK)
				ON p.ProductID = ma.ProductID
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE  (@ProductID = 0 OR ma.ProductID = @ProductID)
			AND (@SportType = 0 OR  ma.SportType = @SportType)
			AND (@BetType = 0 OR  ma.BetType = @BetType)			
			AND (@IsLive = 2 OR  ma.IsLive = @IsLive)
			AND (@SubProduct = '' OR  ma.SubProduct = @SubProduct)
			AND (ma.IsTest = 0 OR ma.IsTest = @isTest)
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
	ELSE IF @Mode = 5
	BEGIN		
		SELECT DISTINCT ma.ProductID
			,ma.BetType
			,ma.EventType
			,ma.SubProduct
		FROM dbo.SportBettypeMatrix ma WITH(NOLOCK)
			INNER JOIN dbo.Products p WITH(NOLOCK)
				ON p.ProductID = ma.ProductID
			LEFT JOIN @tblProductPrefix tblPrefix 
				ON p.ProductPrefix = tblPrefix.ProductPrefix
		WHERE  (@ProductID = 0 OR ma.ProductID = @ProductID)
			AND (@SportType = 0 OR  ma.SportType = @SportType)
			AND (@BetType = 0 OR  ma.BetType = @BetType)			
			AND (@IsLive = 2 OR  ma.IsLive = @IsLive)
			AND (@SubProduct = '' OR  ma.SubProduct = @SubProduct)
			AND (ma.IsTest = 0 OR ma.IsTest = @isTest)
			AND (@ProductPrefix = '' OR tblPrefix.ProductPrefix IS NOT NULL)
	END
END
GO