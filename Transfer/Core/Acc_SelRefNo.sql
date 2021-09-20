/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelRefNo]
	@refno BIGINT OUTPUT
AS

/*
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20210816@Sophia: Fix data Overflow [Redmine: #160262]
Param's Explanation:
*/

BEGIN TRAN

UPDATE ref 
SET  @refno=refno=refno+1
WHERE refid='refno'

COMMIT TRAN

GO