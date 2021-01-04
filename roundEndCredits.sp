#include <shop>
#include <sourcemod>
#include <vip_core>
#include <csgocolors_fix>
#include <mapchooser_extended>

bool g_bVIPLoaded = false;

char currentMap[128] = "";

ConVar  g_cVVIPBonus,
		g_cVMinPlayers,
		g_cVMedMapMinPlayers,
		g_cVBigMapMinPlayers,
		g_cVSmallMapCredits,
		g_cVMedMapCredits,
		g_cVBigMapCredits;

//Set default values incase convars dont load for whatever reason
int g_iVIPBonus = 50,
	g_iMinPlayers = 10,
	g_iMedMapMinPlayers = 20,
	g_iBigMapMinPlayers = 30,
	g_iSmallMapCredits = 25,
	g_iMedMapCredits = 50,
	g_iBigMapCredits = 75;

public Plugin myinfo =
{
	name = "Round End Credits",
	author = "tilgep",
	description = "Gives CTs credits if they win",
	version = "1.0",
	url = "github.com/tilgep"
}

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);

	g_cVVIPBonus = 			CreateConVar("rndEnd_creds_vip_bonus", "50", "Number of extra credits VIPs get if they win as CT");
	g_cVMinPlayers = 		CreateConVar("rndEnd_creds_minplayers", "10", "Minimum number of players needed to give out credits");
	g_cVMedMapMinPlayers = 	CreateConVar("rndEnd_creds_medmap_min", "20", "If the mapchooser MinPlayers is higher than this, it will use rndEnd_cred_med_credits");
	g_cVBigMapMinPlayers = 	CreateConVar("rndEnd_creds_bigmap_min", "30", "If the mapchooser MinPlayers is higher than this, it will use rndEnd_cred_big_credits");
	g_cVSmallMapCredits = 	CreateConVar("rndEnd_creds_small_credits", "25", "Number of credits a player gets if they win a small map");
	g_cVMedMapCredits =		CreateConVar("rndEnd_creds_med_credits", "50", "Number of credits a player gets if they win a medium map");
	g_cVBigMapCredits = 	CreateConVar("rndEnd_creds_big_credits", "75", "Number of credits a player gets if they win a big map");

	g_iVIPBonus = 			GetConVarInt(g_cVVIPBonus);
	g_iMinPlayers = 		GetConVarInt(g_cVMinPlayers);
	g_iMedMapMinPlayers = 	GetConVarInt(g_cVMedMapMinPlayers);
	g_iBigMapMinPlayers = 	GetConVarInt(g_cVBigMapMinPlayers);
	g_iSmallMapCredits = 	GetConVarInt(g_cVSmallMapCredits);
	g_iMedMapCredits =		GetConVarInt(g_cVMedMapCredits);
	g_iBigMapCredits =		GetConVarInt(g_cVBigMapCredits);

	HookConVarChange(g_cVVIPBonus, 			Cvar_Changed);
	HookConVarChange(g_cVMinPlayers, 		Cvar_Changed);
	HookConVarChange(g_cVMedMapMinPlayers, 	Cvar_Changed);
	HookConVarChange(g_cVBigMapMinPlayers, 	Cvar_Changed);
	HookConVarChange(g_cVSmallMapCredits, 	Cvar_Changed);
	HookConVarChange(g_cVMedMapCredits, 		Cvar_Changed);
	HookConVarChange(g_cVBigMapCredits, 		Cvar_Changed);

	if(VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();

	AutoExecConfig(true, "Roundend_Credits");
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_cVVIPBonus)
		g_iVIPBonus = 	GetConVarInt(convar);
	else if(convar == g_cVMinPlayers)
		g_iMinPlayers = GetConVarInt(convar);
	else if(convar == g_cVMedMapMinPlayers)
		g_iMedMapMinPlayers = GetConVarInt(convar);
	else if(convar == g_cVBigMapMinPlayers)
		g_iBigMapMinPlayers = GetConVarInt(convar);
	else if(convar == g_cVSmallMapCredits)
		g_iSmallMapCredits = GetConVarInt(convar);
	else if(convar == g_cVMedMapCredits)
		g_iMedMapCredits = GetConVarInt(convar);
	else if(convar == g_cVBigMapCredits)
		g_iBigMapCredits = GetConVarInt(convar);
}

public void OnMapStart()
{
	GetCurrentMap(currentMap, sizeof(currentMap));
	GetMapMinPlayers(currentMap);
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	//Only allow CT wins to give credits
	if(GetEventInt(event, "winner") != 3)
		return Plugin_Continue;

	if(CountPlayers() < g_iMinPlayers)
	{
		CPrintToChatAll("{green}[Shop]{lightblue} Not enough players to give out credits for winning.");
		return Plugin_Continue;
	}

	for(int i = 1; i < MaxClients; i++)
	{
		int amountToGive = GetCreditAmount();
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == 3 && GetClientHealth(i) > 0)
			{
				if(g_bVIPLoaded)
				{
					if(VIP_IsClientVIP(i))
					{
						char group[64];
						VIP_GetClientVIPGroup(i, group, sizeof(group))
						if(!StrEqual(group, "MEMBER", false))
						{
							amountToGive += g_iVIPBonus;
						}
					}
				}
				GiveTheCredits(i, amountToGive);
			}
		}
	}
	return Plugin_Continue;
}

public int GetCreditAmount()
{
	char checkCurrentMap[128];
	GetCurrentMap(checkCurrentMap, sizeof(checkCurrentMap));
	if(StrEqual(currentMap, checkCurrentMap))
	{
		int mapMinPlayers = GetMapMinPlayers(currentMap);
		if(mapMinPlayers < g_iMedMapMinPlayers)
		{
			return g_iSmallMapCredits;
		}
		else if(mapMinPlayers >= g_iMedMapMinPlayers && mapMinPlayers < g_iBigMapMinPlayers)
		{
			return g_iMedMapCredits;
		}
		else
		{
			return g_iBigMapCredits;
		}
	}
	return 0;
}

public void GiveTheCredits(int client, int amount)
{
	Shop_GiveClientCredits(client, amount);
	CPrintToChat(client, "{green}[Shop] {lightblue}You have been given {green}%d {lightblue}credits for winning the round as human!", amount);
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
    {
        return false; 
    }
    return IsClientInGame(client); 
}

public void VIP_OnVIPLoaded()
{
	g_bVIPLoaded = true;
}

public int CountPlayers()
{
	int players = 0;
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i))
			players++;
	}
	return players;
}