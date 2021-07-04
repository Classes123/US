#include "US/API/Forward.sp"
#include "US/API/Native.sp"

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] sError, int iErrMax)
{
    CreateNative("US_Server_GetID", API_Native_ServerGetID);

    CreateNative("US_Client_GetFirstLogin", API_Native_ClientGetFirstLogin);
    CreateNative("US_Client_GetLastLogin", API_Native_ClientGetLastLogin);
    CreateNative("US_Client_GetLastIP", API_Native_ClientGetLastIP);
    CreateNative("US_Client_GetAdminID", API_Native_ClientGetAdminID);
    
    CreateNative("US_ServerLoader_GetStep", API_Native_ServerLoaderGetStep);
    CreateNative("US_ServerLoader_IsReady", API_Native_ServerLoaderIsReady);
    CreateNative("US_ClientLoader_GetStep", API_Native_ClientLoaderGetStep);
    CreateNative("US_ClientLoader_IsReady", API_Native_ClientLoaderIsReady);

    CreateNative("US_Punish_Register", API_Native_PunishRegister);
    CreateNative("US_Punish_Add", API_Native_PunishAdd);
    CreateNative("US_Punish_AddSave", API_Native_PunishAddSave);
    CreateNative("US_Punish_Remove", API_Native_PunishRemove);
    CreateNative("US_Punish_RemoveSave", API_Native_PunishRemoveSave);

    RegPluginLibrary("us_core");
}