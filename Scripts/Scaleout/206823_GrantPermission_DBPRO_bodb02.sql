/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	 Created by: 20240628@Louisa
	 Task: grant permission [Redmine:#206823]
	 DB: DBPRO-bodb02

	 Revision:
		- 20240628@Louisa: grant permission [Redmine:#206823]
*/


USE bodb02
GO

GRANT EXECUTE ON [dbo].[Dot_Admin_Add_AdminSiteUser] TO [wsv_nap]
GO