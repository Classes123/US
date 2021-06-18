int UTIL_GetServerPort()
{
    static ConVar hostport = null;
    if (hostport == null)
    {
        hostport = FindConVar("hostport");
    }
    return hostport.IntValue;
}

void UTIL_GetServerAddress(char[] szBuffer, int iBufferSize)
{
    static ConVar hostip = null;
    if (hostip == null)
    {
        hostip = FindConVar("hostip");
    }
    int iIp = hostip.IntValue;
    FormatEx(
        szBuffer, iBufferSize, "%d.%d.%d.%d",
        (iIp >> 24)     & 0xFF,
        (iIp >> 16)     & 0xFF,
        (iIp >> 8 )     & 0xFF,
        (iIp      )     & 0xFF
    );
}

void UTIL_GetServerHostname(char[] szBuffer, int iBufferSize)
{
    static ConVar hostname = null;
    if (hostname == null)
    {
        hostname = FindConVar("hostname");
    }
    hostname.GetString(szBuffer, iBufferSize);
}

void UTIL_Query(SQLQueryCallback callback, char[] query, any data = 0, DBPriority prio = DBPrio_Normal)
{
    #if defined US_DEBUG
        LogMessage(query);
    #endif

    Server_Data.hDatabase.Query(callback, query, data, prio);
}

bool UTIL_IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
{
    if (!(1 <= iClient <= MaxClients) || !IsClientInGame(iClient) || (IsFakeClient(iClient) && !bAllowBots) || IsClientSourceTV(iClient) || IsClientReplay(iClient) || (!bAllowDead && !IsPlayerAlive(iClient)))
    {
        return false;
    }
    return true;
}

void UTIL_AssignGroupPermissions(GroupId eGroup, int iFlags)
{
    int iFlag;
    AdminFlag eFlag;
    for (int iFlagId = 0; iFlagId < 33; ++iFlagId)
    {
        iFlag = (1 << iFlagId);

        if ((iFlags & iFlag) && BitToFlag(iFlag, eFlag))
        {
            eGroup.SetFlag(eFlag, true);
        }
    }
}

void UTIL_Steam32toSteamID(int iSteam32, char[] szOut, int iMaxlen)
{
    FormatEx(szOut, iMaxlen, "STEAM_0:%i:%i", iSteam32 % 2, iSteam32 / 2);
}