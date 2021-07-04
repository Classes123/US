public int API_Native_ServerGetID(Handle plugin, int numParams)
{
    return Server_Data.iServerID;
}

public int API_Native_ClientGetFirstLogin(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);
    if(!UTIL_IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%i)", iClient);
    }

    return Client_Data[iClient].iFirstLogin;
}

public int API_Native_ClientGetLastLogin(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);
    if(!UTIL_IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%i)", iClient);
    }

    return Client_Data[iClient].iLastLogin;
}

public int API_Native_ClientGetLastIP(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);
    if(!UTIL_IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%i)", iClient);
    }

    SetNativeString(2, Client_Data[iClient].szLastIP, GetNativeCell(3));

    return 1;
}

public int API_Native_ClientGetAdminID(Handle plugin, int numParams)
{
    int iAdmin = GetNativeCell(1);
    if(iAdmin && (!UTIL_IsValidClient(iAdmin) || !Client_Data[iAdmin].iAdminID))
    {
        return -1;
    }

    return Client_Data[iAdmin].iAdminID;
}

public int API_Native_ServerLoaderGetStep(Handle plugin, int numParams)
{
    return Server_LoaderData.iStep;
}

public int API_Native_ServerLoaderIsReady(Handle plugin, int numParams)
{
    return Server_LoaderData.bReady;
}

public int API_Native_ClientLoaderGetStep(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);
    if(!UTIL_IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%i)", iClient);
    }

    return Client_LoaderData[iClient].iStep;
}

public int API_Native_ClientLoaderIsReady(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);
    if(!UTIL_IsValidClient(iClient))
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client (%i)", iClient);
    }

    return Client_LoaderData[iClient].bReady;
}

public int API_Native_PunishRegister(Handle plugin, int numParams)
{
    char szIdent[32];
    Function fCallback = GetNativeFunction(1);
    GetNativeString(2, szIdent, sizeof szIdent);

    Client_Punish_Register(plugin, fCallback, szIdent);
}

public int API_Native_PunishAdd(Handle plugin, int numParams)
{
    char szReason[256];
    GetNativeString(4, szReason, sizeof szReason);
    Client_Punish_Add(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), szReason, GetNativeCell(5));
}

public int API_Native_PunishAddSave(Handle plugin, int numParams)
{
    char
        szIP[16], 
        szReason[256];

    GetNativeString(2, szIP, sizeof szIP);
    GetNativeString(4, szReason, sizeof szReason);

    Client_Punish_AddSave(GetNativeCell(1), szIP, GetNativeCell(3), szReason, GetNativeCell(5), GetNativeCell(6), GetNativeCell(7));
}

public int API_Native_PunishRemove(Handle plugin, int numParams)
{
    Client_Punish_Remove(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int API_Native_PunishRemoveSave(Handle plugin, int numParams)
{
    char szIP[16];
    GetNativeString(2, szIP, sizeof szIP);
    Client_Punish_RemoveSave(GetNativeCell(1), szIP, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5));
}