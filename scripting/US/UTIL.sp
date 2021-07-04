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

stock void UTIL_Query(SQLQueryCallback callback, const char[] query, const char[] szFuncName = NULL_STRING, any data = 0, DBPriority prio = DBPrio_Normal)
{
    #if defined US_DEBUG
        LogMessage("%s: %s", szFuncName, query);
    #endif

    Server_Data.hDatabase.Query(callback, query, data, prio);
}

stock bool UTIL_IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
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

stock void UTIL_Steam32toSteamID(int iSteam32, char[] szOut, int iMaxlen)
{
    FormatEx(szOut, iMaxlen, "STEAM_0:%i:%i", iSteam32 % 2, iSteam32 / 2);
}

stock void UTIL_GetClientFixName(int iClient, char[] szOut, int iMaxlen)
{
	if (!GetClientName(iClient, szOut, iMaxlen))
	{
		return;
	}

	int iCharBytes;
	for (int i = 0, iLength = strlen(szOut); i < iLength;)
	{
		if ((iCharBytes = GetCharBytes(szOut[i])) > 2)
		{
			iLength -= iCharBytes;
			for (int u = i; u <= iLength; ++u)
			{
				szOut[u] = szOut[u+iCharBytes];
			}
			continue;
		}

		i += iCharBytes;
	}
}

stock void UTIL_AssignAdminID(int iAdmin)
{
    Client_Data[iAdmin].iAdminID = 0;

    AdminId eAdmin = GetUserAdmin(iAdmin);
    if(eAdmin != INVALID_ADMIN_ID)
    {
        char szSteam[10];
        IntToString(GetSteamAccountID(iAdmin), szSteam, sizeof szSteam);

        int iValue;
        if(Server_Data.hAdminIDS.GetValue(szSteam, iValue))
        {
            Client_Data[iAdmin].iAdminID = iValue;
        }
    }
}