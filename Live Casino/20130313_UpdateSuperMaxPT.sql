/*
	Set Super Max PT to 93% for 70 supers below:
		1. KMA  // spositiontaking of this super will not be update. Currently, spositiontaking = 0.93
		2. KM	// spositiontaking of this super will not be update. Currently, spositiontaking = 0.93
		3. SHRM
		4. SCSM
		5. S42RM
		6. SOGO
		7. S23RM
		8. SDARM
		9. S7RM
		10. S31M
		11. S56ARM
		12. SEM
		13. S51SM
		14. JTM
		15. S52ARM
		16. SYLRM
		17. SMSM
		18. WMB
		19. S33SM
		20. S69RM
		21. S188ARM
		22. S36RM
		23. SATM
		24. S989N
		25. S58RM
		26. S91RM
		27. S12RM
		28. S188RM
		29. S52RM
		30. SSTM
		31. SA-DDD
		32. MLAM
		33. SDM
		34. S69RD
		35. CKT
		36. TL6
		37. S257T
		38. S2T
		39. S5TT
		40. SBT
		41. S257AT
		42. S5AT
		43. S5BT
		44. S5CT
		45. JAT
		46. CKT2
		47. S5DT
		48. SYT
		49. S222T
		50. CKT1 --Amy updated by manual
		51. S56TC
		52. S5ET
		53. S86BTB
		54. SGATB
		55. S56TB
		56. S99TB
		57. TL4
		58. TL1
		59. TL2
		60. TL3
		61. SBKT
		62. TL5
		63. SFX
		64. S5T
		65. S86ATB
		66. SGTB
		67. S86TB
		68. SBKTB
		69. KOR --Amy updated by manual
		70. KOB --Amy updated by manual
*/
DECLARE @SuperTable TABLE (custid INT)

INSERT INTO @SuperTable
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN CustSettingGame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE roleid = 4 and 
username IN ('KMA','KM','SHRM','SCSM','S42RM','SOGO','S23RM','SDARM','S7RM','S31M','S56ARM','SEM','S51SM','JTM','S52ARM','SYLRM','SMSM','WMB','S33SM','S69RM','S188ARM','S36RM','SATM','S989N','S58RM','S91RM','S12RM','S188RM','S52RM','SSTM','SA-DDD','MLAM','SDM','S69RD','CKT','TL6','S257T','S2T','S5TT','SBT','S257AT','S5AT','S5BT','S5CT','JAT','CKT2','S5DT','SYT','S222T','S56TC','S5ET','S86BTB','SGATB','S56TB','S99TB','TL4','TL1','TL2','TL3','SBKT','TL5','SFX','S5T','S86ATB','SGTB','S86TB','SBKTB')
AND cg.spositiontaking <> 0.93


-- 65 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.93
WHERE custid IN (SELECT custid FROM @SuperTable)