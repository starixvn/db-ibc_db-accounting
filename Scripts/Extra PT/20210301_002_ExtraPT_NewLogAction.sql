/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
/*
	Created: 20210301@Percy
	DB: DBLOG-bodb_CustomerLog
	Task: Add new logs for auto set primary extra pt group
*/

USE bodb_CustomerLog
GO

INSERT INTO dbo.LogAction (ActionID, ActionTypeID, SPName, ActionNameEN, IsInternal)
VALUES
	(95041,4,'Acc_ExternalGroupHeadline_Ins', 'Create Headline/External Group Mapping', 0)
	,(95042,4,'Acc_ExternalGroupHeadline_Upd', 'Update Headline/External Group Mapping', 0)
	,(95043,4,'Acc_ExternalGroupHeadline_Del', 'Delete Headline/External Group Mapping', 0)
	,(95050,4,'Acc_ExternalGroupHeadline_Ins', 'Update External Group and Extra PT Information', 0)
	,(95051,4,'Acc_ExternalGroupHeadline_Upd', 'Update External Group and Extra PT Information', 0)
	,(95052,4,'Acc_ExternalGroupHeadline_Del', 'Update External Group and Extra PT Information', 0)
	,(95053,4,'Acc_CreditTermUpdAddToGroup', 'Update External Group and Extra PT Information', 0)
	,(95054,4,'Acc_CreditTermUpdCustomer', 'Update External Group and Extra PT Information', 0)
	,(95055,4,'Acc_CreditTermUpdRemoveFromGroup', 'Update External Group and Extra PT Information', 0)
	,(95056,4,'Acc_CreditTermUpdCustomer', 'Delete Headline/External Group Mapping', 0)
	,(95057,4,'Acc_CreditTermUpdRemoveFromGroup', 'Delete Headline/External Group Mapping', 0)
GO
