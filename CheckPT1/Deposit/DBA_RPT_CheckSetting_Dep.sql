USE CheckResultDB
 
GO 

ALTER PROCEDURE [dbo].DBA_RPT_CheckSetting_Dep
	@iType INT=NULL,
	@iQuery INT=NULL
AS
/*
	Created: 20131015@Tom.Vo	
	Task :   Show data
	DB: DB054.CheckResultDB
	Original:

	Revisions:
		
	Param's Explanation:(5)
		@iType : 
			-1: Show all data
			0: Show report filer by SiteID 
			1: Show report filer by CustID
			2: Show report filer by recommend
	
*/

SET NOCOUNT ON

IF @iType IS NULL OR @iQuery IS NULL 
	SET @iType = -1

SELECT DISTINCT CASE WHEN tblComm.SportName IS NOT NULL THEN tblComm.SportName 
			ELSE tblPT.SportName END SportName,
		CASE WHEN tblComm.SiteID IS NOT NULL THEN tblComm.SiteID 
			ELSE tblPT.SiteID END SiteID,
		CASE WHEN tblComm.SiteName IS NOT NULL THEN tblComm.SiteName 
			ELSE tblPT.SiteName END SiteName,
		CASE WHEN tblComm.CurrencyCode IS NOT NULL THEN tblComm.CurrencyCode 
			ELSE tblPT.CurrencyCode END CurrencyCode,
		CASE WHEN tblComm.Currency IS NOT NULL THEN tblComm.Currency 
			ELSE tblPT.Currency END Currency,
		CASE WHEN tblComm.Custid IS NOT NULL THEN tblComm.Custid 
			ELSE tblPT.Custid END Custid,
		CASE WHEN tblComm.UserName IS NOT NULL THEN tblComm.UserName 
			ELSE tblPT.UserName END UserName,
		CASE WHEN tblPT.PT_Invaild  <> tblPT.PT_spec THEN tblPT.PT_Invaild 		ELSE NULL END [Invalid PT],
		tblPT.PT_spec [Spec PT],
		CASE WHEN tblComm.CommP <> tblComm.Comm_P_Spec THEN tblComm.CommP ELSE NULL END [Invalid Comm P],
		tblComm.Comm_P_Spec [Spec Comm P],
		CASE WHEN tblComm.CommA <> tblComm.Comm_SMA_Spec THEN tblComm.CommA
			WHEN tblComm.CommM <> tblComm.Comm_SMA_Spec THEN tblComm.CommM
			WHEN tblComm.CommS <> tblComm.CommS THEN tblComm.CommS			
			ELSE NULL END [Invalid Comm SMA],
		tblComm.Comm_SMA_Spec [Spec Comm SMA]
FROM (
	SELECT DISTINCT CASE WHEN data.IsBA = 1 THEN 'BA'
						WHEN data.SportType <=99 OR data.SportType =154 THEN 'Sports Book' 
						WHEN data.SportType IN (161)  THEN 'Number Game' 
						WHEN data.SportType IN (162)  THEN 'Live Casino'
						WHEN data.SportType IN (151,152,153)  THEN 'Racing'			
						WHEN data.SportType >= 180 AND data.SportType <=186  THEN 'Virtual Sports'
						WHEN data.SportType IN (202)  THEN 'Keno'
						WHEN data.SportType IN (251)  THEN 'RNG Casino'
						ELSE CONVERT(VARCHAR(100),data.SportType)
					END SportName
					,CASE  WHEN data.BetType IN (1,2,3,7,8) THEN 'GroupComm'
						WHEN data.BetType IN (5) THEN '1x2Comm'
						WHEN data.BetType IN (4,6,9,20) THEN 'OtherComm'
						ELSE 'OtherComm'
						END CommType
					,data.SiteID SiteID, st.Site  AS SiteName
					,e.exchangeid CurrencyCode,e.Code Currency
					,co.Custid ,co.UserName 
					,data.Ugroup	
					,data.CommP	
					,data.Comm_P_Spec
					,data.CommA	
					,data.CommM	
					,data.CommS	
					,data.Comm_SMA_Spec	
				FROM CheckResultDB.[dbo].CheckCommResult_Deposit data
					LEFT JOIN bodb02.dbo.Site st WITH(NOLOCK)
						ON data.SITEID=st.siteid
					LEFT JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
						ON data.Custid = co.Custid
					LEFT JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
						ON co.currency = e.exchangeid
				WHERE data.RoleId =1 AND (@iType =-1 
													OR (@iType =0 AND data.SiteID = @iQuery)  
													OR (@iType =1 AND co.Custid = @iQuery)
													OR (@iType =2 AND co.recommend = @iQuery)
													)
	) tblComm
FULL OUTER JOIN
	(
	SELECT DISTINCT CASE WHEN data.IsBA = 1 THEN 'BA' 
						WHEN data.SportType <=99 OR data.SportType =154 THEN 'Sports Book' 
						WHEN data.SportType IN (161)  THEN 'Number Game' 
						WHEN data.SportType IN (162)  THEN 'Live Casino'
						WHEN data.SportType IN (151,152,153)  THEN 'Racing'			
						WHEN data.SportType >= 180 AND data.SportType <=186  THEN 'Virtual Sports'
						WHEN data.SportType IN (202)  THEN 'Keno'
						WHEN data.SportType IN (251)  THEN 'RNG Casino'
						ELSE CONVERT(VARCHAR(100),data.SportType)
					END SportName
					,data.SiteID SiteID, st.Site  AS SiteName
					,e.exchangeid CurrencyCode,e.Code Currency
					,co.Custid ,co.UserName 
					,data.PT_Invalid AS PT_Invaild 
					,data.PT_spec
				FROM CheckResultDB.[dbo].[CheckPTResult_Deposit] data
					LEFT JOIN bodb02.dbo.Site st WITH(NOLOCK)
						ON data.SITEID=st.siteid
					LEFT JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
						ON data.Custid = co.Custid
					LEFT JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
						ON co.currency = e.exchangeid
				WHERE data.RoleId =1 AND (@iType =-1 
													OR (@iType =0 AND data.SiteID = @iQuery)  
													OR (@iType =1 AND co.Custid = @iQuery)
													OR (@iType =2 AND co.recommend = @iQuery))
	)tblPT
ON tblComm.SiteID = tblPT.SiteID
	AND tblComm.SportName = tblPT.SportName
	AND tblComm.Custid = tblPT.Custid
ORDER BY 1,3,5

--Licensee
SELECT DISTINCT CASE WHEN tblComm.SportName IS NOT NULL THEN tblComm.SportName 
			ELSE tblPT.SportName END SportName,
		CASE WHEN tblComm.SiteID IS NOT NULL THEN tblComm.SiteID 
			ELSE tblPT.SiteID END SiteID,
		CASE WHEN tblComm.SiteName IS NOT NULL THEN tblComm.SiteName 
			ELSE tblPT.SiteName END SiteName,
		CASE WHEN tblComm.CurrencyCode IS NOT NULL THEN tblComm.CurrencyCode 
			ELSE tblPT.CurrencyCode END CurrencyCode,
		CASE WHEN tblComm.Currency IS NOT NULL THEN tblComm.Currency 
			ELSE tblPT.Currency END Currency,
		CASE WHEN tblComm.Custid IS NOT NULL THEN tblComm.Custid 
			ELSE tblPT.Custid END Custid,
		CASE WHEN tblComm.UserName IS NOT NULL THEN tblComm.UserName 
			ELSE tblPT.UserName END UserName,
		CASE WHEN tblPT.PT_Invaild  <> tblPT.PT_spec THEN tblPT.PT_Invaild 		ELSE NULL END [Invalid PT],
		tblPT.PT_spec [Spec PT],
		CASE WHEN tblComm.CommA <> tblComm.Comm_SMA_Spec THEN tblComm.CommA
			WHEN tblComm.CommM <> tblComm.Comm_SMA_Spec THEN tblComm.CommM
			WHEN tblComm.CommS <> tblComm.CommS THEN tblComm.CommS			
			ELSE NULL END [Invalid Comm SMA],
		tblComm.Comm_SMA_Spec [Spec Comm SMA]
FROM (
	SELECT DISTINCT CASE WHEN data.IsBA = 1 THEN 'BA' 
						WHEN data.SportType <=99 OR data.SportType =154 THEN 'Sports Book' 
						WHEN data.SportType IN (161)  THEN 'Number Game' 
						WHEN data.SportType IN (162)  THEN 'Live Casino'
						WHEN data.SportType IN (151,152,153)  THEN 'Racing'			
						WHEN data.SportType >= 180 AND data.SportType <=186  THEN 'Virtual Sports'
						WHEN data.SportType IN (202)  THEN 'Keno'
						WHEN data.SportType IN (251)  THEN 'RNG Casino'
						ELSE CONVERT(VARCHAR(100),data.SportType)
					END SportName
					,data.SiteID SiteID, st.Site  AS SiteName
					,e.exchangeid CurrencyCode,e.Code Currency
					,co.Custid ,co.Username 
					,data.PT_Invalid AS PT_Invaild 
					,data.PT_spec
				FROM CheckResultDB.[dbo].[CheckPTResult_Deposit] data
					LEFT JOIN bodb02.dbo.Site st WITH(NOLOCK)
						ON data.SITEID=st.siteid
					LEFT JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
						ON data.Custid = co.Custid
					LEFT JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
						ON co.currency = e.exchangeid
				WHERE data.RoleId =2 AND (@iType =-1 
													OR (@iType =0 AND data.SiteID = @iQuery)  
													OR (@iType =1 AND co.Custid = @iQuery)
													OR (@iType =2 AND co.recommend = @iQuery)
													)
	) tblPT
FULL OUTER JOIN
(
	SELECT DISTINCT CASE WHEN data.IsBA = 1 THEN 'BA' 
						WHEN data.SportType <=99 OR data.SportType =154 THEN 'Sports Book' 
						WHEN data.SportType IN (161)  THEN 'Number Game' 
						WHEN data.SportType IN (162)  THEN 'Live Casino'
						WHEN data.SportType IN (151,152,153)  THEN 'Racing'			
						WHEN data.SportType >= 180 AND data.SportType <=186  THEN 'Virtual Sports'
						WHEN data.SportType IN (202)  THEN 'Keno'
						WHEN data.SportType IN (251)  THEN 'RNG Casino'
						ELSE CONVERT(VARCHAR(100),data.SportType)
					END SportName
					,CASE  WHEN data.BetType IN (1,2,3,7,8) THEN 'GroupComm'
						WHEN data.BetType IN (5) THEN '1x2Comm'
						WHEN data.BetType IN (4,6,9,20) THEN 'OtherComm'
						ELSE 'OtherComm'
						END CommType
					,data.SiteID SiteID, st.Site  AS SiteName
					,e.exchangeid CurrencyCode,e.Code Currency
					,co.Custid ,co.UserName 
					--,data.Ugroup
					,data.CommP	
					,data.Comm_P_Spec
					,data.CommA	
					,data.CommM	
					,data.CommS	
					,data.Comm_SMA_Spec
				FROM CheckResultDB.[dbo].CheckCommResult_Deposit data
					LEFT JOIN bodb02.dbo.Site st WITH(NOLOCK)
						ON data.SITEID=st.siteid
					LEFT JOIN CheckCustDB.dbo.Customer co WITH(NOLOCK)
						ON data.Custid = co.Custid
					LEFT JOIN CheckCustDB.dbo.exchange e WITH(NOLOCK) 
						ON co.currency = e.exchangeid
				WHERE data.RoleId =2 AND (@iType =-1 
													OR (@iType =0 AND data.SiteID = @iQuery)  
													OR (@iType =1 AND co.Custid = @iQuery)
													OR (@iType =2 AND co.recommend = @iQuery)
													)
	)tblComm
	ON tblComm.SiteID = tblPT.SiteID
		AND tblComm.SportName = tblPT.SportName
		AND tblComm.Custid = tblPT.Custid