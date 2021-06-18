#define     PLUGIN_NAME             "[US] Core"

#define     US_DEBUG                1
/////////////////////////////////////////////////////

#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required


#include "US/Server/Init.sp"
//#include "US/Client/Init.sp"

#include "US/UTIL.sp"


public void OnPluginStart()
{
    Server_Loader_Step1(true);
}

public void OnRebuildAdminCache(AdminCachePart ePart)
{
    if(ePart == AdminCache_Groups && Server_LoaderData.iStep >= 3 && Server_LoaderData.bIsReady)
    {
        Server_Loader_Step3(true);
    }
}

/*public void OnClientAuthorized(int iClient)
{
    if(UTIL_IsValidClient(iClient))
    {
        Client_Loader_Step1(iClient, true);
    }
}*/

public Action OnClientPreAdminCheck(int iClient)
{
    return (Server_LoaderData.iStep >= 6 && Server_LoaderData.bIsReady) ? Plugin_Continue : Plugin_Handled;
}