/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_SelRefNo]
	@refno BIGINT OUTPUT
AS

/*
Created: 
DB: DBTXN/bodb02
Revisions:
	- 20210816@Sophia: Fix data Overflow 
Param's Explanation:
*/

begin tran

UPDATE ref 
SET  @refno=refno=refno+1
WHERE refid='refno'

commit tran

GO