void API_Forward_ServerLoader_OnStep()
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_ServerLoader_OnStep", ET_Ignore, Param_Cell, Param_Cell);
    }

    Call_StartForward(hForward);

    Call_PushCell(Server_LoaderData.iStep);
    Call_PushCell(Server_LoaderData.bReady);

    Call_Finish();
}

void API_Forward_ClientLoader_OnStep(int iClient)
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_ClientLoader_OnStep", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(hForward);

    Call_PushCell(iClient);
    Call_PushCell(Client_LoaderData[iClient].iStep);
    Call_PushCell(Client_LoaderData[iClient].bReady);

    Call_Finish();
}


/**
 *  Punishments
 */
void API_Forward_OnAdd(int iClient, int iPunishStatus, int iPunishType, int iPunishID, int iCreateDate, int iExpiryDate, const char[] szAdminName, const char[] szReason)
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_Punish_OnAdd", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String);
    }

    Call_StartForward(hForward);

    Call_PushCell(iClient);
    Call_PushCell(iPunishStatus);
    Call_PushCell(iPunishType);
    Call_PushCell(iPunishID);
    Call_PushCell(iCreateDate);
    Call_PushCell(iExpiryDate);
    Call_PushString(szAdminName);
    Call_PushString(szReason);

    Call_Finish();
}

void API_Forward_OnAddPre(int iClient, int iAdmin, int iPunishType, int iSeconds, const char[] szReason)
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_Punish_OnAddPre", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
    }

    Call_StartForward(hForward);

    Call_PushCell(iClient);
    Call_PushCell(iAdmin);
    Call_PushCell(iPunishType);
    Call_PushCell(iSeconds);
    Call_PushString(szReason);

    Call_Finish();
}

void API_Forward_OnPunishRemoved(int iClient, int iPunishType, int iPunishID)
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_Punish_OnRemoved", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(hForward);

    Call_PushCell(iClient);
    Call_PushCell(iPunishType);
    Call_PushCell(iPunishID);

    Call_Finish();
}

void API_Forward_OnPunishRemovedPre(int iClient, int iAdmin, int iPunishType)
{
    static GlobalForward hForward;
    if(!hForward)
    {
        hForward = new GlobalForward("US_Punish_OnRemovedPre", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(hForward);

    Call_PushCell(iClient);
    Call_PushCell(iAdmin);
    Call_PushCell(iPunishType);

    Call_Finish();
}