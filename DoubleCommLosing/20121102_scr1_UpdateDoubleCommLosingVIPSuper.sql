 /*
	Date: 20121102@Johnson
	Update double comm losing status for VIP Suppers & Dirrect Masters NOT apply for downlines
 */
 DECLARE @tmpCust TABLE (custid int)
 
 INSERT INTO @tmpCust (custid) -- VIP Supers
 SELECT custid 
 FROM custinfo WITH(NOLOCK)
 WHERE username IN ('SBKHK','SBKRMB','SBKTB','SMM','SMSM','SBKH','SBKR','SBKT','SMH','SMMH','SBK','SMAH','SMMS','SMAT','SMR','SMMR','SMBT','SMBH','SSMS'--MMMRM
 ,'SBTK','SBTN','SBTD','SBTL','SBTM','SBTH'--SBTK
 ,'SMT'
 ,'SCM','SCS','SCSM','SCH','SCAH','SCAI','SCI','SCBH','SCHK'--SCM 
 ,'KM','KH','KR','KS','KT','KRC','KSD','KMM','KRR','KMA','KHH','KHK','KAR','KBR','KCR','KAM','KMAM','KMBM','KHAH','KHBH','KAT','KHCH','KDR','KER','KHT','KHDH'--679RM
 ,'SGS','SGTB','SGATB','SGI','SGT','SGAT','SGBT','SGCT','SGAR','TEH','TEC','THR','SGSM','SGSN','TEK','SGMM','TED','THH','THS'--MGTB
 ) AND roleid = 4

INSERT INTO @tmpCust (custid) -- Upline of direct Masters
SELECT distinct srecommend
FROM custinfo WITH(NOLOCK)
WHERE username IN ('MMMRM','MMPRM','MMSD','MMRMB'--MMMRM
,'MTORMB'
,'MGBTB','MGCTB'--MGTB
) AND roleid = 3

INSERT INTO @tmpCust (custid)-- Direct Masters
SELECT custid 
FROM custinfo WITH(NOLOCK)
WHERE username IN ('MMMRM','MMPRM','MMSD','MMRMB'--MMMRM
,'MTORMB'
,'MGBTB','MGCTB'--MGTB
) AND roleid = 3

--- 43 rows affected
UPDATE custinfo WITH(UPDLOCK,ROWLOCK)
SET DoubleCommLosing = 1
WHERE custid IN (SELECT custid FROM @tmpCust)