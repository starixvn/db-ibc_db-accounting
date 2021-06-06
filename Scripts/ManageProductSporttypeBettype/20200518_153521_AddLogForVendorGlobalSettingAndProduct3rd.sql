/*<info serverAlias="DBLOG-bodb_CustomerLog" ></info>*/

USE bodb_CustomerLog
GO
/*
   Created: Evan
	Date: 2021-05-18
    Task: NAP -  Manage VendorGlobal and Product3rd Setting    [Redmine: #153521] 
	DB:   DBCUST-CustDB   

	Revisions:
		- 20210518@Evan:  Task: NAP -  Manage VendorGlobal and Product3rd Setting    [Redmine: #153521] 
	Parameter's explaination:
*/
Insert LogAction(ActionID, ActionTypeID,SPName,ActionNameEN,ActionNameCH,ActionNameCS,ActionNameJP,ActionNameIT,ActionNameTH,ActionNameKO,XsltContent,IsInternal,ActionNameVI,ActionNameCN)
 VALUES
 (95044, 4, 'Acc_VendorGlobalSetting_Ins', 'Insert into VendorGlobalSetting table', 'Insert into VendorGlobalSetting table', 'Insert into VendorGlobalSetting table', 'Insert into VendorGlobalSetting table', NULL, 'Insert into VendorGlobalSetting table', 'Insert into VendorGlobalSetting table', NULL, 0, 'Insert into VendorGlobalSetting table', 'Insert into VendorGlobalSetting table' ), 
 (95045, 4, 'Acc_VendorGlobalSetting_Upd', 'Update VendorGlobalSetting table', 'Update VendorGlobalSetting table', 'Update VendorGlobalSetting table', 'Update VendorGlobalSetting table', NULL, 'Update VendorGlobalSetting table', 'Update VendorGlobalSetting table', NULL, 0, 'Update VendorGlobalSetting table', 'Update VendorGlobalSetting table' ), 
 (95046, 4, 'Acc_VendorGlobalSetting_Del', 'Delete VendorGlobalSetting table', 'Delete VendorGlobalSetting table', 'Delete VendorGlobalSetting table', 'Delete VendorGlobalSetting table', NULL, 'Delete VendorGlobalSetting table', 'Delete VendorGlobalSetting table', NULL, 0, 'Delete VendorGlobalSetting table', 'Delete VendorGlobalSetting table' ), 
 (95047, 4, 'Acc_Product3rd_Ins', 'Insert into Product3rd table', 'Insert into Product3rd table', 'Insert into Product3rd table', 'Insert into Product3rd table', NULL, 'Insert into Product3rd table', 'Insert into Product3rd table', NULL, 0, 'Insert into Product3rd table', 'Insert into Product3rd table' ), 
 (95048, 4, 'Acc_Product3rd_Upd', 'Update Product3rd table', 'Update Product3rd table', 'Update Product3rd table', 'Update Product3rd table', NULL, 'Update Product3rd table', 'Update Product3rd table', NULL, 0, 'Update Product3rd table', 'Update Product3rd table' ), 
 (95049, 4, 'Acc_Product3rd_Del', 'Delete Product3rd table', 'Delete Product3rd table', 'Delete Product3rd table', 'Delete Product3rd table', NULL, 'Delete Product3rd table', 'Delete Product3rd table', NULL, 0, 'Delete Product3rd table', 'Delete Product3rd table' )



