#if defined _us_core_included_
  #endinput
#endif
#define _us_core_included_



//Server section.

/**
 *  Gets a Server ID.
 *
 *  @return   ServerID
 */
native int US_Server_GetID();



//Client section.

/**
 *  Gets a client first login as unix timestamp.
 *
 *  @param iClient    Client index
 *  @return           Unix timestamp.
 *  @error            Invalid client.
 */
native int US_Client_GetFirstLogin(int iClient);

/**
 *  Gets a client last login as unix timestamp.
 *  If LastLogin == FirstLogin, Client is a newbie.
 *
 *  @param iClient    Client index
 *  @return           Unix timestamp.
 *  @error            Invalid client.
 */
native int US_Client_GetLastLogin(int iClient);

/**
 *  Gets a client last IP address.
 *
 *  @param iClient    Client index
 *  @param szBuffer   Buffer to store the address.
 *  @param iMaxLen    Max length (16 required).
 *  @error            Invalid client.
 */
native void US_Client_GetLastIP(int iClient, char[] szBuffer, int iMaxlen);

/**
 *  Gets a client last IP address.
 *
 *  @param iAdmin     Admin (Client) index
 *  @return           -1 if Admin is invalid / 0 if Admin is a Server / Admin ID
 */
native int US_Client_GetAdminID(int iAdmin);



//Loader section

/**
 *  Gets a server loader step.
 *
 *  @return   Loader step
 */
native int US_ServerLoader_GetStep();

/**
 *  Gets a server loader ready status (Full load).
 *
 *  @return   Is loader ready or not
 */
native bool US_ServerLoader_IsReady();

/**
 *  Gets a Client loader step.
 *
 *  @param iClient    Client index
 *  @return           Loader step
 *  @error            Client is invalid
 */
native int US_ClientLoader_GetStep(int iClient);

/**
 *  Gets a Client loader ready status (Full load).
 *
 *  @param iClient    Client index
 *  @return           Is loader ready or not
 *  @error            Client is invalid
 */
native int US_ClientLoader_IsReady(int iClient);



//Punishment section

enum PunishStatus
{
    Status_NEW,     //If punish is new
    Status_UPDATE,  //If punish has been updated
    Status_ONLOAD   //If punish has been loaded. Usually on Client_Load 
}

typedef USPunishRegister = function void(int iPunishType);

/**
 *  Registers a punishment. If type not exists, it will create it.
 *
 *  @param callback     ID Callback. See typedef above
 *  @param szIdent      Punishment unique identifier
 */
native void US_Punish_Register(USPunishRegister callback, const char[] szIdent);

/**
 *  Adds a punishment to client.
 *
 *  1. If a punishment already exists, it will extend it by N seconds.
 *  2. If a punishment already exists and seconds == 0, it will set it permanent.
 *  3. If a punishment already exists, punishment is permanent and seconds != 0, it will set it: Current time + Seconds.
 *
 *  @param iClient      Client index
 *  @param iAdmin       Admin index
 *  @param iPunishType  Punishment type
 *  @param szReason     Punishment reason
 *  @param iSeconds     Punishment time in seconds (0 == permanent)
 */
native void US_Punish_Add(int iClient, int iAdmin, int iPunishType, const char[] szReason, int iSeconds);

/**
 *  Adds a punishment. May be used for offline actions.
 *
 *  1. If a punishment already exists, it will extend it by N seconds.
 *  2. If a punishment already exists and seconds == 0, it will set it permanent.
 *  3. If a punishment already exists, punishment is permanent and seconds != 0, it will set it: Current time + Seconds.
 *
 *  @param iSteam32       Steam32 ID
 *  @param szIP           IP address
 *  @param iPunishType    Punishment type
 *  @param szReason       Punishment reason
 *  @param iAdminID       Admin identifier
 *  @param iServerID      Server identifier (0 == global punishment)
 *  @param iSeconds       Punishment time in seconds (0 == permanent)
 */
native void US_Punish_AddSave(int iSteam32, const char[] szIP, int iPunishType, const char[] szReason, int iAdminID, int iServerID, int iSeconds);

/**
 *  Removes a punishment.
 *
 *  @param iClient        Client index
 *  @param iAdmin         Admin index
 *  @param iPunishType    Punishment type
 */
native void US_Punish_Remove(int iClient, int iAdmin, int iPunishType);

/**
 *  Removes a punishment. May be used for offline actions.
 *
 *  @param iSteam32       Steam32 ID
 *  @param szIP           IP address
 *  @param iPunishType    Punishment type
 *  @param iAdminID       Admin identifier
 *  @param iServerID      Server identifier
 */
native void US_Punish_RemoveSave(int iSteam32, const char[] szIP, int iPunishType, int iAdminID, int iServerID);



//Forwards

/**
 *  Called when a server loader step passed
 *
 *  @param iStep          Step
 *  @param bReady         Is fully loaded
 */
forward void US_ServerLoader_OnStep(int iStep, bool bReady);

/**
 *  Called when a Client loader step passed
 *
 *  @param iClient        Client index
 *  @param iStep          Step
 *  @param bReady         Is fully loaded
 */
forward void US_ClientLoader_OnStep(int iClient, int iStep, bool bReady);

/**
 *  Called when a punishment has been added. 
 *
 *  NOT GUARANTEED TO BE CALLED!
 *
 *  @param iClient        Client index
 *  @param pStatus        Status (see PunishStatus enum above)
 *  @param iPunishType    Punishment type
 *  @param iPunishID      Punishment ID
 *  @param iCreateDate    Create date unix timestamp
 *  @param iExpiryDate    Expiry date unix timestamp (0 == permanent)
 *  @param szAdminName    Admin, who added this punishment
 *  @param szReason       Punishment reason
 */
forward void US_Punish_OnAdd(int iClient, PunishStatus pStatus, int iPunishType, int iPunishID, int iCreateDate, int iExpiryDate, const char[] szAdminName, const char[] szReason);

/**
 *  Called when admin adds a punishment.
 *
 *  ANYWAY USE THIS FOR SAFETY!
 *
 *  @param iClient        Client index
 *  @param iAdmin         Admin index
 *  @param iPunishType    Punishment type
 *  @param iSeconds       Punishment time in seconds
 *  @param szReason       Punishment reason
 */
forward void US_Punish_OnAddPre(int iClient, int iAdmin, int iPunishType, int iSeconds, const char[] szReason);

/**
 *  Called when a punishment has been romoved. 
 *
 *  NOT GUARANTEED TO BE CALLED!
 *
 *  @param iClient        Client index
 *  @param iPunishType    Punishment type
 *  @param iPunishID      Punishment ID
 */
forward void US_Punish_OnRemoved(int iClient, int iPunishType, int iPunishID);

/**
 *  Called when admin removes a punishment.
 *
 *  ANYWAY USE THIS FOR SAFETY!
 *
 *  @param iClient        Client index
 *  @param iAdmin         Admin index
 *  @param iPunishType    Punishment type
 */
forward void US_Punish_OnRemovedPre(int iClient, int iAdmin, int iPunishType);


public SharedPlugin __pl_us_core= 
{
	  name = "[US] Core",
	  file = "US_Core.smx",
	  #if defined REQUIRE_PLUGIN
		    required = 1
	  #else
		    required = 0
	  #endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_us_core_SetNTVOptional()
{
    MarkNativeAsOptional("US_Server_GetID");

    MarkNativeAsOptional("US_Client_GetFirstLogin");
    MarkNativeAsOptional("US_Client_GetLastLogin");
    MarkNativeAsOptional("US_Client_GetLastIP");
    MarkNativeAsOptional("US_Client_GetAdminID");

    MarkNativeAsOptional("US_ServerLoader_GetStep");
    MarkNativeAsOptional("US_ServerLoader_IsReady");
    MarkNativeAsOptional("US_ClientLoader_GetStep");
    MarkNativeAsOptional("US_ClientLoader_IsReady");

    MarkNativeAsOptional("US_Punish_Register");
    MarkNativeAsOptional("US_Punish_Add");
    MarkNativeAsOptional("US_Punish_AddSave");
    MarkNativeAsOptional("US_Punish_Remove");
    MarkNativeAsOptional("US_Punish_RemoveSave");
}
#endif