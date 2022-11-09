/*<info serverAlias="DBPRO-bodb02"></info>*/
/*
	Created: 20221108@Eddie
	DB: DBPRO-bodb02
	Task: Delete TypeId (23203, 23204) On SIT
*/

DELETE b
FROM dbo.bettype b WITH (ROWLOCK, UPDLOCK)
WHERE b.typeid IN (23203, 23204)
GO

