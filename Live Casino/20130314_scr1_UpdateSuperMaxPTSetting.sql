/*
	Set Super Max PT to 90% for supers below:
	- Sheet "KKKUSD":
		1. SCC
		2. SCK
		3. VIP
		4. SKKS
		5. SKS
		6. SKT
		7. VID
		8. SKD
		9. SKV
		10. SKW
		11. SKX
		12. SKE
		13. SKF
		14. SKG
		15. SKH
		16. SKY
		17. SKZ
		18. SKI
		19. SKJ
		20. SKA
		21. SKB
		22. SKL
		23. SKQ
		24. SKK
		25. VIU
		26. SKO
		27. skn
		28. skp
		29. SKAA
		30. SKAB
		31. SKAC
		32. SKAD
		33. SKAE
		34. SKAF
		35. SKAG
		36. SKAH
		37. SKAI
		38. SKAJ
		39. SKKA
		40. QHN
		41. QVN
		42. SKAN
		43. SHB
		44. SKAO
		45. SKAP
		46. SHD
		47. SKAR
		48. SKAS
		49. SKAT
		50. skau
		51. skav
		52. skaw
		53. skax
		54. skay
		55. skaz
		56. skba
		57. skbb
		58. SKBC
		59. SKBD
		60. SKBE
		61. SKBF
		62. skbg
		63. skbh
		64. SKBI
		65. SKBJ
		66. SKBK
		67. SKBL
		68. SKBM
		69. skbn
		
	- Sheet "ETUS":
		1. XXJ
		2. XXK
		3. XXO
		4. XXP
		5. XXQ
		6. XXR
		7. XXS
		8. QA
		9. QB
		10. QD
		11. QE
		12. QF
		13. QG
		14. QH
		15. QI
		16. QJ
		17. QK
		18. QL
		19. QM
		20. QN
		21. QO
		22. QP
		23. qs
		24. QR
		25. QT
		26. QU
		27. QC
		28. BK
		29. HC
		30. BC
		31. QV
		32. BD
		33. BE
		34. BG
		35. BH
		36. BL
		37. BM
		38. BN
		39. BO
		40. BP
		41. BR
		42. BX
		43. BY
		44. BZ
		45. BC1
		46. BC2
		47. BC3
		48. BC5
		49. BC6
		50. BC7
		51. BC8
		52. BC9
		53. BCA
		54. EA1
		55. EA2
		56. EA3
		57. EA4
		58. AZ1
		59. AZ2
		60. AZ3
		61. AZ4
		62. AZ5
		63. EA6
		64. EA7
		65. EA8
		66. EA9
		67. EAA
		68. EG1
		69. EG2
		70. EG3
		71. EG5
		72. EG6
		73. EAB
		74. EAC
		75. EAD
		76. EAE
		77. EAF
		78. EAG
		79. EAH
		80. EAI
		81. EAK
		82. AZ6
		83. AZ7
		84. AZ8
		85. AZ9
		86. AZ10
		87. AZ11
		88. AZ12
		89. AZ13
		90. AZ14
		91. AZ15
		92. ET1
		93. ET2
		94. ET3
		95. ET4
		96. ET5
		97. EBK
		98. EBM
		99. ET6
		100. ET7
		101. ET8
		102. ET10
		
	- Sheet "SDD":
		1. SY1B
		2. SDE
		3. SDU
		4. SDY
		5. SDV
		6. SDW
		7. SDX
		8. SDZ
		9. SDJ
		10. SDO
		11. SDP
		12. SDB
		13. SDF
		14. SDG
		15. SDI
		16. SDN
		17. SDY1
		18. SYA
		19. SYB
		20. SYN
		21. SYO
		22. SYP
		23. SYQ
		24. SYS
		25. SYU
		26. SYV
		27. SYW
		28. SYY
		29. SDY2
		30. SYZ1
		31. SDY3
		32. SDY5
		33. SDQ
		34. SDS
		35. SDY6
		36. SDY7
		37. SDN1
		38. SDN2
		39. SDY8
		40. UZA
*/
/****Sheet KKKUSD****/
DECLARE @SuperTableKKKUSD TABLE (custid INT)

INSERT INTO @SuperTableKKKUSD
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN CustSettingGame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE roleid = 4 and 
username IN ('SCC','SCK','VIP','SKKS','SKS','SKT','VID','SKD','SKV','SKW','SKX','SKE','SKF','SKG','SKH','SKY','SKZ','SKI','SKJ','SKA','SKB','SKL','SKQ','SKK','VIU','SKO','skn','skp','SKAA','SKAB','SKAC','SKAD','SKAE','SKAF','SKAG','SKAH','SKAI','SKAJ','SKKA','QHN','QVN','SKAN','SHB','SKAO','SKAP','SHD','SKAR','SKAS','SKAT','skau','skav','skaw','skax','skay','skaz','skba','skbb','SKBC','SKBD','SKBE','SKBF','skbg','skbh','SKBI','SKBJ','SKBK','SKBL','SKBM','skbn')
AND cg.spositiontaking <> 0.9

-- 69 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.9
WHERE custid IN (SELECT custid FROM @SuperTableKKKUSD)
/*********************************************************/

/****Sheet ETUS****/
DECLARE @SuperTableETUS TABLE (custid INT)

INSERT INTO @SuperTableETUS
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN CustSettingGame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE roleid = 4 and 
username IN ('XXJ','XXK','XXO','XXP','XXQ','XXR','XXS','QA','QB','QD','QE','QF','QG','QH','QI','QJ','QK','QL','QM','QN','QO','QP','qs','QR','QT','QU','QC','BK','HC','BC','QV','BD','BE','BG','BH','BL','BM','BN','BO','BP','BR','BX','BY','BZ','BC1','BC2','BC3','BC5','BC6','BC7','BC8','BC9','BCA','EA1','EA2','EA3','EA4','AZ1','AZ2','AZ3','AZ4','AZ5','EA6','EA7','EA8','EA9','EAA','EG1','EG2','EG3','EG5','EG6','EAB','EAC','EAD','EAE','EAF','EAG','EAH','EAI','EAK','AZ6','AZ7','AZ8','AZ9','AZ10','AZ11','AZ12','AZ13','AZ14','AZ15','ET1','ET2','ET3','ET4','ET5','EBK','EBM','ET6','ET7','ET8','ET10')
AND cg.spositiontaking <> 0.9

-- 102 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.9
WHERE custid IN (SELECT custid FROM @SuperTableETUS)
/*********************************************************/


/****Sheet SDD****/
DECLARE @SuperTableSDD TABLE (custid INT)

INSERT INTO @SuperTableSDD
SELECT c.custid
FROM Customer c WITH(NOLOCK)
	INNER JOIN CustSettingGame cg WITH(NOLOCK) ON c.custid = cg.custid
WHERE roleid = 4 and 
username IN ('SY1B','SDE','SDU','SDY','SDV','SDW','SDX','SDZ','SDJ','SDO','SDP','SDB','SDF','SDG','SDI','SDN','SDY1','SYA','SYB','SYN','SYO','SYP','SYQ','SYS','SYU','SYV','SYW','SYY','SDY2','SYZ1','SDY3','SDY5','SDQ','SDS','SDY6','SDY7','SDN1','SDN2','SDY8','UZA')
AND cg.spositiontaking <> 0.9

-- 40 rows affected
UPDATE custsettinggame WITH(ROWLOCK,UPDLOCK)
SET spositiontaking = 0.9
WHERE custid IN (SELECT custid FROM @SuperTableSDD)
/*********************************************************/