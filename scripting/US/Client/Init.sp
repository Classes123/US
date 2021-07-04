enum struct Client_DataDecl
{
    int iAdminID;

    int iFirstLogin;
    int iLastLogin;
    
    char szLastIP[16];
}

Client_DataDecl
    Client_Data[MAXPLAYERS+1];


#include "US/Client/Loader.sp"
#include "US/Client/Punish.sp"