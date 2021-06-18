enum struct Server_LoaderDataDecl
{
    bool bIsReady;
    int iStep;
}

Server_LoaderDataDecl
    Server_LoaderData;


/**
 *  STEP #1
 *  Registrating commands.
 */
void Server_Loader_Step1(bool bNext = false)
{
    Server_LoaderData.iStep = 1;
    Server_LoaderData.bIsReady = false;

    //Server_Commands_Load();

    Server_LoaderData.bIsReady = true;
    if(bNext) Server_Loader_Step2(true);
}

/**
 *  STEP #2
 *  Connecting database.
 */
void Server_Loader_Step2(bool bNext = false)
{
    Server_LoaderData.iStep = 2;
    Server_LoaderData.bIsReady = false;

    Database.Connect(Server_Loader_Step2_Connect, "uni_sys", bNext);
}

public void Server_Loader_Step2_Connect(Database hDatabase, const char[] szError, bool bNext)
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

    Server_LoaderData.bIsReady = true;
    if(bNext) Server_Loader_Step3(true);
}


/**
 *  STEP #3
 *  Loading config.
 */
void Server_Loader_Step3(bool bNext = false)
{
    Server_LoaderData.iStep = 3;
    Server_LoaderData.bIsReady = false;

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

    Server_LoaderData.bIsReady = true;
    if(bNext) Server_Loader_Step4(true);
}


/**
 *  STEP #4
 *  Synchronizing server.
 */
void Server_Loader_Step4(bool bNext = false)
{
    Server_LoaderData.iStep = 4;
    Server_LoaderData.bIsReady = false;

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
    hPack.WriteCell(bNext);
    hPack.WriteString(szHostname);
    hPack.WriteString(szAddress);
    hPack.WriteCell(iPort);

    if(!iServerID)
    {
        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT `server_id` FROM `us_server` WHERE `address` = INET_ATON('%s') AND `port` = %i", szAddress, iPort);
        UTIL_Query(Server_Loader_Step4_UnsignedServer, szQuery, hPack, DBPrio_High);
    }
    else
    {
        hPack.WriteCell(iServerID);

        Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT EXISTS(SELECT 1 FROM us_server WHERE server_id = %i LIMIT 1)", iServerID);
        UTIL_Query(Server_Loader_Step4_CheckServer, szQuery, hPack, DBPrio_High);
    }
}

public void Server_Loader_Step4_UnsignedServer(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    if(!szError[0])
    {
        hPack.Reset();

        bool bNext = hPack.ReadCell();

        char
            szHostname[256],
            szAddress[32];

        hPack.ReadString(szHostname, sizeof szHostname);
        hPack.ReadString(szAddress, sizeof szAddress);

        if(results.HasResults && results.FetchRow())
        {
            int iServerID = results.FetchInt(0);

            Server_Data.hConfig.Rewind();
            Server_Data.hConfig.SetNum("server_id", iServerID);
            Server_Data.hConfig.ExportToFile("addons/sourcemod/configs/us/core.ini");

            char szQuery[512];
            Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "UPDATE `us_server` SET `address` = INET_ATON('%s'), `port` = %i, `hostname` = '%s', `lastsync` = UNIX_TIMESTAMP() WHERE `server_id` = %i", szAddress, hPack.ReadCell(), szHostname, iServerID);
            UTIL_Query(Server_Loader_Step4_SyncServer, szQuery, bNext);
        }
        else
        {
            char szQuery[512];
            Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "INSERT INTO `us_server` (`address`, `port`, `hostname`, `lastsync`) VALUES (INET_ATON('%s'), %i, '%s', UNIX_TIMESTAMP())", szAddress, hPack.ReadCell(), szHostname);
            UTIL_Query(Server_Loader_Step4_SyncServer, szQuery, bNext);
        }
    }
    else
    {
        LogError("Server_Loader_Step4_UnsignedServer: %s", szError);
    }

    delete hPack;
}

public void Server_Loader_Step4_CheckServer(Database hDatabase, DBResultSet results, const char[] szError, DataPack hPack)
{
    if(!szError[0]) 
    {
        hPack.Reset();

        bool bNext = hPack.ReadCell();

        char
            szHostname[256],
            szAddress[32];

        hPack.ReadString(szHostname, sizeof szHostname);
        hPack.ReadString(szAddress, sizeof szAddress);

        int iPort = hPack.ReadCell();
        int iServerID = hPack.ReadCell();

        if(results.HasResults && results.FetchRow() && results.FetchInt(0))
        {
            char szQuery[512];
            Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "UPDATE `us_server` SET `address` = INET_ATON('%s'), `port` = %i, `hostname` = '%s', `lastsync` = UNIX_TIMESTAMP() WHERE `server_id` = %i", szAddress, iPort, szHostname, iServerID);
            UTIL_Query(Server_Loader_Step4_SyncServer, szQuery, bNext);
        }
        else
        {
            SetFailState(PLUGIN_NAME...": Server %i not found!", iServerID);
        }
    }
    else
    {
        LogError("Server_Loader_Step4_UnsignedServer: %s", szError);
    }

    delete hPack;
}

public void Server_Loader_Step4_SyncServer(Database hDatabase, DBResultSet results, const char[] szError, bool bNext)
{
    if(!szError[0])
    {
        int iInsertID = results.InsertId;
        if(iInsertID)
        {
            Server_Data.hConfig.Rewind();
            Server_Data.hConfig.SetNum("server_id", iInsertID);
            Server_Data.hConfig.ExportToFile("addons/sourcemod/configs/us/core.ini");
        }

        Server_LoaderData.bIsReady = true;
        if(bNext) Server_Loader_Step5(true);
    }
    else
    {
        LogError("Server_Loader_Step4_SyncServer: %s", szError);
    }
}


/**
 *  STEP #5
 *  Loading groups.
 */
void Server_Loader_Step5(bool bNext = false)
{
    Server_LoaderData.iStep = 5;
    Server_LoaderData.bIsReady = false;

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery, "SELECT `groupname`, `flags`, `immunity` FROM `us_group`");
    UTIL_Query(Server_Loader_Step5_LoadGroups, szQuery, bNext);
}

public void Server_Loader_Step5_LoadGroups(Database hDatabase, DBResultSet results, const char[] szError, bool bNext)
{
    if(!szError[0]) 
    {
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

        Server_LoaderData.bIsReady = true;
        if(bNext) Server_Loader_Step6(true);
    }
    else
    {
        LogError("Server_Loader_Step5_LoadGroup: %s", szError);
    }
}


/**
 *  STEP #6
 *  Loading admins.
 */
void Server_Loader_Step6(bool bNext = false)
{
    Server_LoaderData.iStep = 6;
    Server_LoaderData.bIsReady = false;

    Server_Data.hConfig.Rewind();

    char szQuery[512];
    Server_Data.hDatabase.Format(szQuery, sizeof szQuery,   "SELECT `client_id`, `adminname`, `groupname` \
                                                            FROM `us_admin` \
                                                            INNER JOIN `us_group` \
                                                                ON `us_admin`.`group_id` = `us_group`.`group_id` \
                                                            WHERE \
	                                                            (`expire_date` > UNIX_TIMESTAMP() OR `expire_date` = 0) \
	                                                            AND `server_id` = %i", Server_Data.hConfig.GetNum("server_id"));
    UTIL_Query(Server_Loader_Step6_LoadAdmins, szQuery, bNext);
}

public void Server_Loader_Step6_LoadAdmins(Database hDatabase, DBResultSet results, const char[] szError, bool bNext)
{
    if(!szError[0]) 
    {
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
                results.FetchString(2, szGroupname, sizeof szGroupname);

                eGroup = FindAdmGroup(szGroupname);
                if(eGroup != INVALID_GROUP_ID)
                {
                    results.FetchString(1, szAdminname, sizeof szAdminname);

                    UTIL_Steam32toSteamID(results.FetchInt(0), szSteamID, sizeof szSteamID);

                    eAdmin = CreateAdmin(szAdminname);
                    eAdmin.BindIdentity("steam", szSteamID);
                    eAdmin.InheritGroup(eGroup);
                }
            }
        }

        for(int i = 1; i <= MaxClients; i++)
        {
            if(UTIL_IsValidClient(i))
            {
                RunAdminCacheChecks(i);
                NotifyPostAdminCheck(i);
            }
        }

        Server_LoaderData.bIsReady = true;
    }
    else
    {
        LogError("Server_Loader_Step6_LoadAdmins: %s", szError);
    }
}