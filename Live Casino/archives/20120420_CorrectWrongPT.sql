	
/*
	Task: Correct PT for some members 
	Date: 20120420@Jamie 
	
*/

--1. 
	UPDATE cg WITH(ROWLOCK,UPDLOCK)
			SET cg.apositiontaking		= cs.alivepositiontaking,
				cg.mpositiontaking		= cs.mlivepositiontaking,
				cg.spositiontaking		= cs.slivepositiontaking,
				cg.autopositiontaking	= cs.autolivepositiontaking,		
				cg.isautopositiontaking = cs.isautolivepositiontaking,
				cg.autompositiontaking	= cs.autolivempositiontaking,
				cg.isautompositiontaking= cs.isautolivempositiontaking
			FROM custsettingGame cg 
				INNER JOIN custsetting cs WITH(NOLOCK) ON cg.custid = cs.custid 
				INNER JOIN custinfo c WITH(NOLOCK) ON cg.custid = c.custid 
			WHERE cs.sporttype = 1 AND cs.bettype = 1
				AND cg.sporttype = 162 AND cg.bettype = 1101
				AND c.custid IN (
					514165	,	--	SCM5980003	|	1
					514169	,	--	SCM5980005	|	1
					514172	,	--	SCM5980006	|	1
					514174	,	--	SCM5980007	|	1
					514177	,	--	SCM5980008	|	1
					514180	,	--	SCM5980009	|	1
					514185	,	--	SCM5980010	|	1
					514188	,	--	SCM5980011	|	1
					514192	,	--	SCM5980012	|	1
					514216	,	--	SCM5980312	|	1
					514229	,	--	SCM5980544	|	1
					514233	,	--	SCM5980711	|	1
					514241	,	--	SCM5980838	|	1
					514244	,	--	SCM5980910	|	1
					514245	,	--	SCM5980975	|	1
					566893	,	--	SCM5980800	|	1
					591971	,	--	SCM5980018	|	1
					600338	,	--	SCM5980020	|	1
					622317	,	--	SCM5980013	|	1
					672351	,	--	SCM5980015	|	1
					1580403	,	--	SCM5980680	|	1
					1607263	,	--	SCM5980111	|	1
					1645895	,	--	SCM5980777	|	1
					5286671	,	--	SCMA103001	|	1
					5455395	,	--	SCMA103332	|	1
					6161638		--	SCMA103338	|	1

		)

--2. 
		UPDATE cg WITH(ROWLOCK,UPDLOCK)
			SET cg.apositiontaking		= cs.alivepositiontaking,
				cg.mpositiontaking		= cs.mlivepositiontaking,
				cg.spositiontaking		= cs.slivepositiontaking,
				cg.autopositiontaking	= cs.autolivepositiontaking,		
				cg.isautopositiontaking = cs.isautolivepositiontaking,
				cg.autompositiontaking	= cs.autolivempositiontaking,
				cg.isautompositiontaking= cs.isautolivempositiontaking
			FROM custsettingGame cg 
				INNER JOIN custsetting cs WITH(NOLOCK) ON cg.custid = cs.custid 
				INNER JOIN custinfo c WITH(NOLOCK) ON cg.custid = c.custid 
			WHERE cs.sporttype = 1 AND cs.bettype = 1
				AND cg.sporttype = 162 AND cg.bettype = 1101
				AND c.custid IN (
					430112	,	--	SMM7061111	|	1
					430114	,	--	SMM7061112	|	1
					430115	,	--	SMM7061115	|	1
					430116	,	--	SMM7061113	|	1
					430118	,	--	SMM7061116	|	1
					436754	,	--	SMM7061117	|	1
					583594	,	--	SMM7061118	|	1
					766671	,	--	SMM7061222	|	1
					2899225	,	--	SMM7061689	|	1
					2899282	,	--	SMM7061103	|	1
					2899294	,	--	SMM7061007	|	1
					2899312	,	--	SMM7061364	|	1
					2899333	,	--	SMM7061011	|	1
					2899387	,	--	SMM7061101	|	1
					2899401	,	--	SMM7061012	|	1
					2899449	,	--	SMM7061949	|	1
					2899482	,	--	SMM7061102	|	1
					3023959		--	SMM7061008	|	1

		)