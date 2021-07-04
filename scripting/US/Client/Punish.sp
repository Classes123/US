/**
 *  Register
 */
void Client_Punish_Register(Handle hPlugin, Function fCallback, const char[] szIdent)
{
    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `punish_type_id` \
                                                            FROM `us_punish_type` \
                                                            WHERE \
                                                                `identifier` = '%s'", szIdent);

    DataPack hPack = new DataPack();
    hPack.WriteString(szIdent);
    hPack.WriteCell(hPlugin);
    hPack.WriteFunction(fCallback);

    UTIL_Query(Client_Punish_RegisterCheck, szQuery, "Client_Punish_Register()", hPack, DBPrio_High);
}

public void Client_Punish_RegisterCheck(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    char szIdent[32];

    hPack.Reset();
    hPack.ReadString(szIdent, sizeof szIdent);

    Handle hPlugin = hPack.ReadCell();
    Function fCallback = hPack.ReadFunction();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_RegisterCheck: %s", szError);
        return;
    }

    if(results.HasResults && results.FetchRow())
    {
        Call_StartFunction(hPlugin, fCallback);
        Call_PushCell(results.FetchInt(0));
        Call_Finish();
    }
    else
    {
        char szQuery[512];
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "INSERT INTO `us_punish_type` \
                                                                (\
                                                                    `identifier` \
                                                                ) \
                                                                VALUES \
                                                                (\
                                                                    '%s' \
                                                                )", szIdent);

        hPack = new DataPack();
        hPack.WriteCell(hPlugin);
        hPack.WriteFunction(fCallback);

        UTIL_Query(Client_Punish_RegisterCreate, szQuery, "Client_Punish_RegisterCheck()", hPack, DBPrio_High);
    }
}

public void Client_Punish_RegisterCreate(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    hPack.Reset();

    Handle hPlugin = hPack.ReadCell();
    Function fCallback = hPack.ReadFunction();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_RegisterCreate: %s", szError);
        return;
    }

    Call_StartFunction(hPlugin, fCallback);
    Call_PushCell(results.InsertId);
    Call_Finish();
}


/**
 *  Add
 */
void Client_Punish_Add(int iClient, int iAdmin, int iPunishType, const char[] szReason, int iSeconds)
{
    if(!UTIL_IsValidClient(iClient) || (iAdmin && !Client_Data[iAdmin].iAdminID))
    {
        return;
    }

    API_Forward_OnAddPre(iClient, iAdmin, iPunishType, iSeconds, szReason);

    char szIP[16];
    GetClientIP(iClient, szIP, sizeof szIP);

    Client_Punish_AddSave(GetSteamAccountID(iClient), szIP, iPunishType, szReason, Client_Data[iAdmin].iAdminID, Server_Data.iServerID, iSeconds, GetClientUserId(iClient));
}

void Client_Punish_AddSave(int iSteam32, const char[] szIP, int iPunishType, const char[] szReason, int iAdminID, int iServerID, int iSeconds, int iUserID = 0)
{
    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `punish_id`, \
                                                                `expiry_date` \
                                                            FROM `us_punish` \
                                                            WHERE \
                                                                    (`client_id` = %u OR `client_ip` = INET_ATON('%s')) \
                                                                AND \
                                                                    (`punish_type` = %i) \
                                                                AND \
                                                                    (`expiry_date` > UNIX_TIMESTAMP() OR `expiry_date` = 0) \
                                                                AND \
                                                                    (`remove_date` = 0) \
                                                                AND \
                                                                    (`server_id` = %i)", iSteam32, szIP, iPunishType, iServerID);

    DataPack hPack = new DataPack();
    hPack.WriteString(szIP);
    hPack.WriteString(szReason);
    hPack.WriteCell(iSteam32);
    hPack.WriteCell(iPunishType);
    hPack.WriteCell(iAdminID);
    hPack.WriteCell(iServerID);
    hPack.WriteCell(iSeconds);
    hPack.WriteCell(iUserID);

    UTIL_Query(Client_Punish_AddCheck, szQuery, "Client_Punish_AddSave()", hPack, DBPrio_High);
}

public void Client_Punish_AddCheck(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    char
        szIP[16],
        szReason[256];

    hPack.Reset();
    hPack.ReadString(szIP, sizeof szIP);
    hPack.ReadString(szReason, sizeof szReason);
    
    int 
        iSteam32 = hPack.ReadCell(),
        iPunishType = hPack.ReadCell(),
        iAdminID = hPack.ReadCell(),
        iServerID = hPack.ReadCell(),
        iSeconds = hPack.ReadCell(),
        iUserID = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_AddCheck: %s", szError);
        return;
    }

    int 
        iCurrentTime = GetTime(),
        iPunishID;

    char szQuery[512];
    if(results.HasResults && results.FetchRow())
    {
        int 
            iOldExpiryDate = results.FetchInt(1),
            iNewExpiryDate = iSeconds ? (iOldExpiryDate ? (iOldExpiryDate + iSeconds) : (iCurrentTime + iSeconds)) : 0;

        iPunishID = results.FetchInt(0);

        Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "INSERT INTO `us_punish_update` \
                                                                (\
                                                                    `punish_id`, \
                                                                    `punish_update_date`, \
                                                                    `punish_update_reason`, \
                                                                    `prev_expiry_date`, \
                                                                    `new_expiry_date`, \
                                                                    `admin_id` \
                                                                ) \
                                                                VALUES \
                                                                (\
                                                                    %i, \
                                                                    %i, \
                                                                    '%s', \
                                                                    %i, \
                                                                    %i, \
                                                                    %i \
                                                                )", iPunishID, iCurrentTime, szReason, iOldExpiryDate, iNewExpiryDate, iAdminID);

        UTIL_Query(Client_Punish_AddRegisterUpdate, szQuery, "Client_Punish_AddSave()");

        Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "UPDATE `us_punish` \
                                                                SET \
                                                                    `update_date` = %i, \
                                                                    `expiry_date` = %i \
                                                                WHERE \
                                                                    `punish_id` = %i", iCurrentTime, iNewExpiryDate, iPunishID);
    }
    else
    {
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "INSERT INTO `us_punish` \
                                                                (\
                                                                    `punish_type`, \
                                                                    `punish_reason`, \
                                                                    `client_id`, \
                                                                    `client_ip`, \
                                                                    `admin_id`, \
                                                                    `server_id`, \
                                                                    `create_date`, \
                                                                    `update_date`, \
                                                                    `expiry_date` \
                                                                ) \
                                                                VALUES \
                                                                (\
                                                                    %i, \
                                                                    '%s', \
                                                                    %u, \
                                                                    INET_ATON('%s'), \
                                                                    %i, \
                                                                    %i, \
                                                                    UNIX_TIMESTAMP(), \
                                                                    UNIX_TIMESTAMP(), \
                                                                    %i \
                                                                )", iPunishType, szReason, iSteam32, szIP, iAdminID, iServerID, iSeconds ? (iCurrentTime + iSeconds) : 0);
    }

    hPack = new DataPack();
    hPack.WriteCell(iUserID);
    hPack.WriteCell(iPunishID);

    UTIL_Query(Client_Punish_AddPostSave, szQuery, "Client_Punish_AddSave()", hPack, DBPrio_High);
}

public void Client_Punish_AddRegisterUpdate(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
    if(szError[0])
    {
        LogError("Client_Punish_RegisterUpdate: %s", szError);
    }
}

public void Client_Punish_AddPostSave(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    hPack.Reset();
    
    int
        iUserID = hPack.ReadCell(),
        iPunishID = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_AddPostSave: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(!iClient)
    {
        return;
    }

    bool bUpdate = true;
    if(!iPunishID)
    {
        bUpdate = false;
        iPunishID = results.InsertId;
    }

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `punish_type`, \
                                                                `punish_reason`, \
                                                                `us_admin`.`name`, \
                                                                `create_date`, \
                                                                `expiry_date` \
                                                            FROM `us_punish` \
                                                            INNER JOIN `us_admin` \
                                                                ON `us_punish`.`admin_id` = `us_admin`.`admin_id` \
                                                            WHERE \
                                                                `punish_id` = %i", iPunishID);

    hPack = new DataPack();
    hPack.WriteCell(iUserID);
    hPack.WriteCell(iPunishID);
    hPack.WriteCell(bUpdate);

    UTIL_Query(Client_Punish_AddPostSaveCallback, szQuery, "Client_Punish_AddPostSave()", hPack, DBPrio_High);
}

public void Client_Punish_AddPostSaveCallback(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    hPack.Reset();

    int
        iUserID = hPack.ReadCell(),
        iPunishID = hPack.ReadCell(),
        iPunishStatus = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_PostSave_Callback: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(iClient && results.HasResults && results.FetchRow())
    {
        char 
            szAdminName[MAX_NAME_LENGTH],
            szReason[256];

        results.FetchString(1, szReason, sizeof szReason);
        results.FetchString(2, szAdminName, sizeof szAdminName);

        API_Forward_OnAdd(iClient, iPunishStatus, results.FetchInt(0), iPunishID, results.FetchInt(3), results.FetchInt(4), szAdminName, szReason);
    }
}


/**
 *  Remove
 */
void Client_Punish_Remove(int iClient, int iAdmin, int iPunishType)
{
    if(!UTIL_IsValidClient(iClient) || (iAdmin && !UTIL_IsValidClient(iAdmin) && GetUserAdmin(iAdmin) == INVALID_ADMIN_ID))
    {
        return;
    }

    API_Forward_OnPunishRemovedPre(iClient, iAdmin, iPunishType);

    char szIP[16];
    GetClientIP(iClient, szIP, sizeof szIP);

    Client_Punish_RemoveSave(GetSteamAccountID(iClient), szIP, iPunishType, Client_Data[iAdmin].iAdminID, Server_Data.iServerID, GetClientUserId(iClient));
}

void Client_Punish_RemoveSave(int iSteam32, const char[] szIP, int iPunishType, int iAdminID, int iServerID, int iUserID = 0)
{
    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `punish_id` \
                                                            FROM `us_punish` \
                                                            WHERE \
                                                                    (`client_id` = %u OR `client_ip` = INET_ATON('%s')) \
                                                                AND \
                                                                    (`punish_type` = %i) \
                                                                AND \
                                                                    (`expiry_date` > UNIX_TIMESTAMP() OR `expiry_date` = 0) \
                                                                AND \
                                                                    (`remove_date` = 0) \
                                                                AND \
                                                                    (`server_id` = %i OR `server_id` = 0) \
                                                            LIMIT 1", iSteam32, szIP, iPunishType, iServerID);

    DataPack hPack = new DataPack();
    hPack.WriteCell(iUserID);
    hPack.WriteCell(iPunishType);
    hPack.WriteCell(iAdminID);

    UTIL_Query(Client_Punish_RemoveSaveCallback, szQuery, "Client_Punish_RemoveSave()", hPack, DBPrio_High);
}

public void Client_Punish_RemoveSaveCallback(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    hPack.Reset();

    int 
        iUserID = hPack.ReadCell(),
        iPunishType = hPack.ReadCell(),
        iAdminID = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_RemoveSave_Callback: %s", szError);
        return;
    }

    if(results.HasResults && results.FetchRow())
    {
        Client_Punish_RemoveById(results.FetchInt(0), iAdminID, iPunishType, iUserID);
    }
}

void Client_Punish_RemoveById(int iPunishID, int iAdminID, int iPunishType = 0, int iUserID = 0)
{
    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "UPDATE `us_punish` \
                                                            SET \
                                                                `remove_admin_id` = %i, \
                                                                `remove_date` = UNIX_TIMESTAMP() \
                                                            WHERE \
                                                                    (`punish_id` = %i)", iAdminID, iPunishID);

    DataPack hPack = new DataPack();
    hPack.WriteCell(iUserID);
    hPack.WriteCell(iPunishType);
    hPack.WriteCell(iPunishID);

    UTIL_Query(Client_Punish_PostRemove, szQuery, "Client_Punish_RemoveById()", hPack, DBPrio_High);
}

public void Client_Punish_PostRemove(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    hPack.Reset();

    int 
        iUserID = hPack.ReadCell(),
        iPunishType = hPack.ReadCell(),
        iPunishID = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Client_Punish_PostRemove: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(iClient && iPunishType)
    {
        API_Forward_OnPunishRemoved(iClient, iPunishType, iPunishID);
    }
}