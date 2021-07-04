#define     PLUGIN_NAME             "[US] Core"
#define     PLUGIN_VERSION          "1.0.0.0 Beta"

#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required


#include "US/Server/Init.sp"
#include "US/Client/Init.sp"
#include "US/API/Init.sp"

#include "US/UTIL.sp"


/**
 *  Special thanks to:
 *
 *  CrazyHackGUT (github.com/CrazyHackGUT)
 */
public Plugin myinfo =
{
    name     =  PLUGIN_NAME,
    author   =  "Young <",
    version  =  PLUGIN_VERSION,
    url      =  "https://github.com/Classes123/US"
}

public void OnPluginStart()
{
    Server_Loader_Step1();
}

public void OnMapStart()
{
    if(Server_LoaderData.iStep > 3)
    {
        Server_Loader_Step3();
    }
}

public void OnRebuildAdminCache(AdminCachePart ePart)
{
    if(ePart == AdminCache_Groups && Server_LoaderData.iStep > 5)
    {
        Server_Loader_Step5();
    }
}

public Action OnClientPreAdminCheck(int iClient)
{
    return (Server_LoaderData.iStep >= 6 && Server_LoaderData.bReady) ? Plugin_Continue : Plugin_Handled;
}

public void OnClientPostAdminCheck(int iClient)
{
    UTIL_AssignAdminID(iClient);
}

public void OnClientAuthorized(int iClient)
{
    if(!IsFakeClient(iClient))
    {
        Client_Loader_Step1(iClient);
    }
}

public void OnClientDisconnect(int iClient)
{
    Client_LoaderData[iClient].iStep = 0;
    Client_LoaderData[iClient].bReady = false;

    Client_Data[iClient].iAdminID = 0;

    Client_Data[iClient].iFirstLogin = 0;
    Client_Data[iClient].iLastLogin = 0;
    Client_Data[iClient].szLastIP[0] = 0;
}