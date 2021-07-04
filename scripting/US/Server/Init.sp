enum struct Server_DataDecl
{
    Database hDatabase;
    KeyValues hConfig;
    StringMap hAdminIDS;

    int iServerID;
}

Server_DataDecl
    Server_Data;


#include "US/Server/Loader.sp"