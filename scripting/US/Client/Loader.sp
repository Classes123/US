enum struct Client_LoaderDataDecl
{
    int iStep;
    bool bReady;
}

Client_LoaderDataDecl
    Client_LoaderData[MAXPLAYERS+1];

void Client_Loader_RegisterStep(int iClient, int iStep, bool bReady = false)
{
    Client_LoaderData[iClient].iStep = iStep;
    Client_LoaderData[iClient].bReady = bReady;

    API_Forward_ClientLoader_OnStep(iClient);
}


/**
 *  STEP #1
 *  Checking punishments.
 */
void Client_Loader_Step1(int iClient)
{
    Client_Loader_RegisterStep(iClient, 1);

    char szBuffer[512];
    GetClientIP(iClient, szBuffer, sizeof szBuffer);

    Server_Data.hDatabase.Format(szBuffer, sizeof szBuffer,     "SELECT \
                                                                    `punish_id`, \
                                                                    `punish_type`, \
                                                                    `punish_reason`, \
                                                                    `us_admin`.`name`, \
                                                                    `create_date`, \
                                                                    `expiry_date` \
                                                                FROM `us_punish` \
                                                                INNER JOIN `us_admin` \
                                                                    ON `us_punish`.`admin_id` = `us_admin`.`admin_id` \
                                                                WHERE \
                                                                        (`client_id` = %u OR `client_ip` = INET_ATON('%s')) \
                                                                    AND \
                                                                        (`expiry_date` > UNIX_TIMESTAMP() OR `expiry_date` = 0) \
                                                                    AND \
                                                                        (`remove_date` = 0) \
                                                                    AND \
                                                                        (`server_id` = %i OR `server_id` = 0)", GetSteamAccountID(iClient), szBuffer, Server_Data.iServerID);

    UTIL_Query(Client_Loader_Step1_CheckPunishments, szBuffer, "Client_Loader_Step1()", GetClientUserId(iClient), DBPrio_High);
}

public void Client_Loader_Step1_CheckPunishments(Database hDatabase, DBResultSet results, const char[] szError, int iUserID)
{
    if(szError[0])
    {
        LogError("Client_Loader_Step1_CheckPunishments: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(!iClient)
    {
        return;
    }

    if(results.HasResults)
    {
        char 
            szAdminName[MAX_NAME_LENGTH],
            szReason[256];

        while(results.FetchRow())
        {
            results.FetchString(2, szReason, sizeof szReason);
            results.FetchString(3, szAdminName, sizeof szAdminName);

            API_Forward_OnAdd(iClient, 2, results.FetchInt(1), results.FetchInt(0), results.FetchInt(4), results.FetchInt(5), szAdminName, szReason);

            if(!IsClientConnected(iClient))
            {
                return;
            }
        }
    }

    Client_Loader_Step2(iClient);
}


/**
 *  STEP #2
 *  Fetching And Updating information.
 */
void Client_Loader_Step2(int iClient)
{
    Client_Loader_RegisterStep(iClient, 2);

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `first_login`, \
                                                                `last_login`, \
                                                                INET_NTOA(`last_ip`) \
                                                            FROM `us_client` \
                                                            WHERE \
                                                                `client_id` = %u", GetSteamAccountID(iClient));

    UTIL_Query(Client_Loader_Step2_FetchInfo, szQuery, "Client_Loader_Step2()", GetClientUserId(iClient));
}

public void Client_Loader_Step2_FetchInfo(Database hDatabase, DBResultSet results, const char[] szError, int iUserID)
{
    if(szError[0])
    {
        LogError("Client_Loader_Step2_FetchInfo: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(!iClient)
    {
        return;
    }

    char szBuffer[512];
    GetClientIP(iClient, szBuffer, sizeof szBuffer);

    if(results.HasResults && results.FetchRow())
    {
        Client_Data[iClient].iFirstLogin = results.FetchInt(0);
        Client_Data[iClient].iLastLogin = results.FetchInt(1);

        results.FetchString(2, Client_Data[iClient].szLastIP, sizeof Client_Data[].szLastIP);
    }
    else
    {
        int iCurrentTime = GetTime();

        Client_Data[iClient].iFirstLogin = iCurrentTime;
        Client_Data[iClient].iLastLogin = iCurrentTime;

        strcopy(Client_Data[iClient].szLastIP, sizeof Client_Data[].szLastIP, szBuffer);
    }

    char szName[MAX_NAME_LENGTH];
    UTIL_GetClientFixName(iClient, szName, sizeof szName);

    Server_Data.hDatabase.Format(szBuffer, sizeof szBuffer, "INSERT INTO `us_client` \
                                                            (\
                                                                `client_id`, \
                                                                `client_name`, \
                                                                `first_login`, \
                                                                `last_login`, \
                                                                `last_ip` \
                                                            ) \
                                                            VALUES \
                                                            (\
                                                                %u, \
                                                                '%s', \
                                                                UNIX_TIMESTAMP(), \
                                                                UNIX_TIMESTAMP(), \
                                                                INET_ATON('%s') \
                                                            ) \
                                                            ON DUPLICATE KEY UPDATE \
                                                                `client_name` = '%s', \
                                                                `last_login` = UNIX_TIMESTAMP(), \
                                                                `last_ip` = INET_ATON('%s')", GetSteamAccountID(iClient), szName, szBuffer, szName, szBuffer);

    UTIL_Query(Client_Loader_Step2_Update, szBuffer, "Client_Loader_Step2_FetchInfo()", iUserID);
}

public void Client_Loader_Step2_Update(Database hDatabase, DBResultSet results, const char[] szError, int iUserID)
{
    if(szError[0])
    {
        LogError("Client_Loader_Step2_Update: %s", szError);
        return;
    }

    int iClient = GetClientOfUserId(iUserID);
    if(!iClient)
    {
        return;
    }

    Client_Loader_RegisterStep(iClient, 2, true);
}