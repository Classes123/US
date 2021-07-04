enum struct Server_LoaderDataDecl
{
    int iStep;
    bool bReady;
}

Server_LoaderDataDecl
    Server_LoaderData;

void Server_Loader_RegisterStep(int iStep, bool bReady = false)
{
    Server_LoaderData.iStep = iStep;
    Server_LoaderData.bReady = bReady;

    API_Forward_ServerLoader_OnStep();
}


/**
 *  STEP #1
 *  Fast initialization.
 */
void Server_Loader_Step1()
{
    Server_Loader_RegisterStep(1);

    Server_Data.hAdminIDS = new StringMap();

    Server_Loader_Step2();
}

/**
 *  STEP #2
 *  Connecting database.
 */
void Server_Loader_Step2()
{
    Server_Loader_RegisterStep(2);

    Database.Connect(Server_Loader_Step2_Connect, "uni_sys");
}

public void Server_Loader_Step2_Connect(Database hDatabase, const char[] szError, any data)
{
    if (hDatabase == null || szError[0])
    {
        SetFailState(PLUGIN_NAME...": Database failure: \"%s\", aborting.", szError);
    }

    if(Server_Data.hDatabase)
    {
        delete Server_Data.hDatabase;
    }
    Server_Data.hDatabase = hDatabase;
    Server_Data.hDatabase.SetCharset("utf8");

    Server_Loader_Step3();
}


/**
 *  STEP #3
 *  Loading config.
 */
void Server_Loader_Step3()
{
    Server_Loader_RegisterStep(3);

    char szPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, szPath, sizeof szPath, "configs/us/core.ini");

    if(Server_Data.hConfig)
    {
        delete Server_Data.hConfig;
    }

    Server_Data.hConfig = new KeyValues("uni_sys");
    if(!Server_Data.hConfig.ImportFromFile(szPath))
    {
        SetFailState(PLUGIN_NAME..." : Error read \"%s\", aborting.", szPath);
    }

    Server_Loader_Step4();
}


/**
 *  STEP #4
 *  Synchronizing server.
 */
void Server_Loader_Step4()
{
    Server_Loader_RegisterStep(4);

    Server_Data.hConfig.Rewind();

    char
        szQuery[512],
        szHostname[256],
        szAddress[32];

    int
        iServerID = Server_Data.hConfig.GetNum("server_id"),
        iPort = UTIL_GetServerPort();

    UTIL_GetServerHostname(szHostname, sizeof szHostname);
    UTIL_GetServerAddress(szAddress, sizeof szAddress);

    DataPack hPack = new DataPack();
    hPack.WriteString(szHostname);
    hPack.WriteString(szAddress);
    hPack.WriteCell(iPort);

    if(!iServerID)
    {
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT `server_id` FROM `us_server` WHERE `address` = INET_ATON('%s') AND `port` = %i", szAddress, iPort);
        UTIL_Query(Server_Loader_Step4_UnsignedServer, szQuery, "Server_Loader_Step4()", hPack, DBPrio_High);
    }
    else
    {
        hPack.WriteCell(iServerID);

        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT EXISTS(SELECT 1 FROM us_server WHERE server_id = %i LIMIT 1)", iServerID);
        UTIL_Query(Server_Loader_Step4_CheckServer, szQuery, "Server_Loader_Step4()", hPack, DBPrio_High);
    }
}

public void Server_Loader_Step4_UnsignedServer(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    char
        szHostname[256],
        szAddress[32];

    hPack.Reset();
    hPack.ReadString(szHostname, sizeof szHostname);
    hPack.ReadString(szAddress, sizeof szAddress);

    int iPort = hPack.ReadCell();

    delete hPack;


    if(szError[0])
    {
        LogError("Server_Loader_Step4_UnsignedServer: %s", szError);
        return;
    }

    char szQuery[512];
    if(results.HasResults && results.FetchRow())
    {
        int iServerID = results.FetchInt(0);

        Server_Data.iServerID = iServerID;

        Server_Data.hConfig.Rewind();
        Server_Data.hConfig.SetNum("server_id", iServerID);
        Server_Data.hConfig.ExportToFile("addons/sourcemod/configs/us/core.ini");

        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "UPDATE `us_server` SET `address` = INET_ATON('%s'), `port` = %i, `hostname` = '%s', `lastsync` = UNIX_TIMESTAMP() WHERE `server_id` = %i", szAddress, iPort, szHostname, iServerID);
    }
    else
    {
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "INSERT INTO `us_server` (`address`, `port`, `hostname`, `lastsync`) VALUES (INET_ATON('%s'), %i, '%s', UNIX_TIMESTAMP())", szAddress, iPort, szHostname);
    }
    
    UTIL_Query(Server_Loader_Step4_SyncServer, szQuery, "Server_Loader_Step4_UnsignedServer()");
}

public void Server_Loader_Step4_CheckServer(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    char
        szHostname[256],
        szAddress[32];

    hPack.Reset();
    hPack.ReadString(szHostname, sizeof szHostname);
    hPack.ReadString(szAddress, sizeof szAddress);

    int 
        iPort = hPack.ReadCell(),
        iServerID = hPack.ReadCell();
        
    delete hPack;


    if(szError[0]) 
    {
        LogError("Server_Loader_Step4_UnsignedServer: %s", szError);
        return;
    }

    if(results.HasResults && results.FetchRow() && results.FetchInt(0))
    {
        Server_Data.iServerID = iServerID;

        char szQuery[512];
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "UPDATE `us_server` SET `address` = INET_ATON('%s'), `port` = %i, `hostname` = '%s', `lastsync` = UNIX_TIMESTAMP() WHERE `server_id` = %i", szAddress, iPort, szHostname, iServerID);
        UTIL_Query(Server_Loader_Step4_SyncServer, szQuery, "Server_Loader_Step4_CheckServer()");
    }
    else
    {
        SetFailState(PLUGIN_NAME...": Server %i not found!", iServerID);
    }
}

public void Server_Loader_Step4_SyncServer(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
    if(szError[0])
    {
        LogError("Server_Loader_Step4_SyncServer: %s", szError);
        return;
    }

    int iInsertID = results.InsertId;
    if(iInsertID)
    {
        Server_Data.hConfig.Rewind();
        Server_Data.hConfig.SetNum("server_id", iInsertID);
        Server_Data.hConfig.ExportToFile("addons/sourcemod/configs/us/core.ini");
    }

    Server_Loader_Step5();
}


/**
 *  STEP #5
 *  Loading groups.
 */
void Server_Loader_Step5()
{
    Server_Loader_RegisterStep(5);

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT `name`, `flags`, `immunity` FROM `us_admin_group`");
    UTIL_Query(Server_Loader_Step5_LoadGroups, szQuery, "Server_Loader_Step5()");
}

public void Server_Loader_Step5_LoadGroups(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
    if(szError[0]) 
    {
        LogError("Server_Loader_Step5_LoadGroup: %s", szError);
        return;
    }

    if(results.HasResults)
    {
        char szGroupname[256];
        GroupId eGroup;
        while (results.FetchRow())
        {
            results.FetchString(0, szGroupname, sizeof szGroupname);

            eGroup = FindAdmGroup(szGroupname);
            if (eGroup == INVALID_GROUP_ID)
            {
                eGroup = CreateAdmGroup(szGroupname);
            }

            UTIL_AssignGroupPermissions(eGroup, results.FetchInt(1));
            eGroup.ImmunityLevel = results.FetchInt(2);
        }
    }

    Server_Loader_Step6();
}


/**
 *  STEP #6
 *  Loading admins.
 */
void Server_Loader_Step6()
{
    Server_Loader_RegisterStep(6);

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT \
                                                                `auth`, \
                                                                `us_admin`.`admin_id`, \
                                                                `us_admin`.`name` AS `admin_name`, \
                                                                `us_admin_group`.`name` AS `group_name` \
                                                            FROM `us_admin_data` \
                                                            INNER JOIN `us_admin_group` \
                                                                ON `us_admin_data`.`group_id` = `us_admin_group`.`group_id` \
                                                            INNER JOIN `us_admin` \
                                                                ON `us_admin_data`.`admin_id` = `us_admin`.`admin_id` \
                                                            WHERE \
                                                                    (`expiry_date` > UNIX_TIMESTAMP() OR `expiry_date` = 0) \
                                                                AND \
                                                                    (`server_id` = %i OR `server_id` = 0)", Server_Data.iServerID);
                                                                    
    UTIL_Query(Server_Loader_Step6_LoadAdmins, szQuery, "Server_Loader_Step6()");
}

public void Server_Loader_Step6_LoadAdmins(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
    if(szError[0]) 
    {
        LogError("Server_Loader_Step6_LoadAdmins: %s", szError);
        return;
    }

    if(Server_Data.hAdminIDS.Size)
    {
        Server_Data.hAdminIDS.Clear();
    }

    if(results.HasResults)
    {
        char
            szAdminname[256],
            szGroupname[256],
            szSteamID[32];

        AdminId eAdmin;
        GroupId eGroup;

        while(results.FetchRow())
        {
            results.FetchString(3, szGroupname, sizeof szGroupname);

            eGroup = FindAdmGroup(szGroupname);
            if(eGroup != INVALID_GROUP_ID)
            {
                results.FetchString(2, szAdminname, sizeof szAdminname);

                int iAccountID = results.FetchInt(0);

                UTIL_Steam32toSteamID(iAccountID, szSteamID, sizeof szSteamID);

                eAdmin = CreateAdmin(szAdminname);
                eAdmin.BindIdentity("steam", szSteamID);
                eAdmin.InheritGroup(eGroup);

                //Adding admin_id to our map. This format is a temporary solution.
                IntToString(iAccountID, szSteamID, sizeof szSteamID);
                Server_Data.hAdminIDS.SetValue(szSteamID, results.FetchInt(1));
            }
        }
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(UTIL_IsValidClient(i))
        {
            RunAdminCacheChecks(i);
            NotifyPostAdminCheck(i);

            UTIL_AssignAdminID(i);
        }
    }

    Server_Loader_RegisterStep(6, true);
}