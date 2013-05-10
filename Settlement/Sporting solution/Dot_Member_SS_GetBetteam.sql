ALTER PROCEDURE [dbo].[Dot_Member_SS_GetBetteam]
@oddsid		int,
@betteam	Varchar(10) = '' Output
AS

SET NOCOUNT ON

select @betteam = case when Bettype in (1301,1303,1304,1305,1306,1308,1310,1311,1312,1314,1316,1318,1319,1323,1324,1326,1327,1329,1331,1332) then	
						case when odds1a = 1 then 'h'
							when odds2a = 1 then 'a' end
					when Bettype = 1302 then
						case when Cs21 = 1 then '21'
							when Cs12 = 1 then '12'
							when Cs20 = 1 then '20'
							when Cs02 = 1 then '02'
							when Cs30 = 1 then '30'
							when Cs03 = 1 then '03'
							when Cs31 = 1 then '31'
							when Cs13 = 1 then '13'
							when Cs32 = 1 then '32'
							when Cs23 = 1 then '23' end
					when Bettype in (1307,1309,1313,1315,1330,1333,1334) then	
						case when Com1 = 1 then '1'
							when comx = 1 then 'x'
							when Com2 = 1 then '2' end
					when Bettype = 1317 then	
						case when Cs01 = 1 then '60'
							when Cs02 = 1 then '61'
							when Cs03 = 1 then '62'
							when Cs04 = 1 then '63'
							when Cs05 = 1 then '64'
							when Cs12 = 1 then '75'
							when Cs13 = 1 then '76'
							when Cs10 = 1 then '06'
							when Cs20 = 1 then '16'
							when Cs30 = 1 then '26'
							when Cs40 = 1 then '36'
							when Cs50 = 1 then '46'
							when Cs21 = 1 then '57'
							when Cs31 = 1 then '67' end
					when Bettype = 1320 then	
						case when Cs20 = 1 then '20'
							when Cs11 = 1 then '11'
							when CS02 = 1 then '02' end
					when Bettype = 1321 then	
						case when Cs40 = 1 then '40'
							when Cs31 = 1 then '31'
							when Cs22 = 1 then '22'
							when Cs13 = 1 then '13'
							when CS04 = 1 then '04' end
					when Bettype = 1322 then	
						case when Cs40 = 1 then '60'
							when Cs41 = 1 then '51'
							when Cs42 = 1 then '42'
							when Cs33 = 1 then '33'
							when CS24 = 1 then '24'
							when Cs14 = 1 then '15'
							when CS04 = 1 then '06' end	
					when Bettype = 1325 then	
						case when Cs01 = 1 then '01'
							when Cs02 = 1 then '02'
							when Cs03 = 1 then '03'
							when Cs04 = 1 then '04'
							when CS10 = 1 then '10'
							when Cs20 = 1 then '20'
							when CS30 = 1 then '30'
							when Cs40 = 1 then '40' end	
					when Bettype = 1328 then	
						case when Cs01 = 1 then '01'
							when Cs02 = 1 then '02'
							when Cs03 = 1 then '03'
							when Cs04 = 1 then '04' end					
				end
from odds with (nolock)	
where oddsid = @oddsid and comstatus = 1

GO


 