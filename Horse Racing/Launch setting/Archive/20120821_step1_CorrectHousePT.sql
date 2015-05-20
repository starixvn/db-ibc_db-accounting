


UPDATE custsuper WITH(ROWLOCK,UPDLOCK)
SET autoIBCPT153_AU = 0
WHERE custid IN (
					7118880	,	--- TycoonSuperINR
					7140071	,	--- VCasiaSuperGBP
					7140648	,	--- VCasiaSuperEuro
					7140747	,	--- VcasiaSuperUS$
					7140807	,	--- VCasiaSuperAUD
					7140934	,	--- VCasiaSuperSD$
					7141027	,	--- VCasiaSuperRMB
					7262758	,	--- HAIFASuperTB
					7508102	,	--- AoncashSuperUUS
					7508179	,	--- AoncashSuperIN
					7596081	,	--- HAIFASuperEURO
					7596126	,	--- SG8SuperEURO
					7596152	,	--- SUGSuperEURO
					7596180	,	--- MacaubetSuperEURO
					7596216	,	--- TLCSuperEURO
					7596235	,	--- TycoonSuperEURO
					7596324	,	--- VwinSuperEURO
					7596367	,	--- Z88SuperEURO
					7596617	,	--- MacaubetSuperUS$
					7596674	,	--- SG8SuperUS$
					7596708	,	--- TLCSuperUS$
					7596728	,	--- TycoonSuperUS$
					7596783	,	--- VwinSuperUS$
					7651889	,	--- BODOGSuperAUD
					7652025	,	--- BODOGSuperNZD
					7664193		--- BwinningSuperIN
					)