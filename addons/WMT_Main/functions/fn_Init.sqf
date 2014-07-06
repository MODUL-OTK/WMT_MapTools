/*
 	Name: WMT_fnc_Init
 
 	Author(s):
		Ezhuk

 	Description:
		Initialize all  
*/
#include "defines.sqf"

if(isNil "wmt_param_ViewDistance") then {
	if(isNumber (MissionConfigFile >> "WMT_Params" >> "ViewDistance")) then {
		wmt_param_ViewDistance = getNumber (MissionConfigFile >> "WMT_Params" >> "ViewDistance");
	} else {
		wmt_param_ViewDistance = 2500;
	};
};
if(isNil "wmt_param_TI") then {
	wmt_param_TI = getNumber (MissionConfigFile >> "WMT_Params" >> "EnableTI");
};
if(isNil "wmt_param_NameTag") then {
	if(isNumber (MissionConfigFile >> "WMT_Params" >> "WinnerByTime")) then {
		wmt_param_NameTag = getNumber (MissionConfigFile >> "WMT_Params" >> "WinnerByTime");
	} else {
		wmt_param_NameTag = 1;
	}
};
if(isNil "wmt_param_MissionTime") then {
	wmt_param_MissionTime = getNumber (MissionConfigFile >> "WMT_Params" >> "MissionTime");
};
if(isNil "wmt_param_WinnerByTime") then {
	PR(_txt) = getText (MissionConfigFile >> "WMT_Params" >> "WinnerByTime");
	if(_txt != "") then {
		wmt_param_WinnerByTime = call compile _txt;
	}else {
		wmt_param_WinnerByTime = sideLogic;
	};
};
if(isNil "wmt_param_WinnerByTimeText") then {
	if(isText (MissionConfigFile >> "WMT_Params" >> "MessageOfEnd")) then {
		wmt_param_WinnerByTimeText = getText (MissionConfigFile >> "WMT_Params" >> "MessageOfEnd");
	} else {
		wmt_param_WinnerByTimeText = localize "STR_WMT_EndTime";
	};
};	
if(isNil "wmt_param_PrepareTime") then {
	wmt_param_PrepareTime = getNumber (MissionConfigFile >> "WMT_Params" >> "PrepareTime");
};
if(isNil "wmt_param_StartZone") then {
	if(isNumber (MissionConfigFile >> "WMT_Params" >> "StartZone")) then {
		wmt_param_StartZone = getNumber (MissionConfigFile >> "WMT_Params" >> "StartZone");
	} else {
		wmt_param_StartZone = 100;
	};
};
if(isNil "wmt_param_RemoveBots") then {
	wmt_param_RemoveBots = getNumber (MissionConfigFile >> "WMT_Params" >> "RemoveBots");
};
if(isNil "wmt_param_HeavyLossesCoeff") then {
	if(isNumber (MissionConfigFile >> "WMT_Params" >> "HeavyLossesCoeff")) then {
		wmt_param_HeavyLossesCoeff = getNumber (MissionConfigFile >> "WMT_Params" >> "HeavyLossesCoeff");
	} else {
		wmt_param_HeavyLossesCoeff = 0.1;
	};
};
if(isNil "wmt_param_ShowEnemyVehiclesInNotes") then {
	wmt_param_ShowEnemyVehiclesInNotes = getNumber (MissionConfigFile >> "WMT_Params" >> "ShowEnemyVehiclesInNotes");
};
if(isNil "wmt_param_GenerateFrequencies") then {
	wmt_param_GenerateFrequencies =  getNumber (MissionConfigFile >> "WMT_Params" >> "GenerateFrequencies");
};
if(isNil "wmt_param_DisableAI") then {
	if(isNumber (MissionConfigFile >> "WMT_Params" >> "StartZone")) then {
		wmt_param_DisableAI = getNumber (MissionConfigFile >> "WMT_Params" >> "DisableAI");
	} else {
		wmt_param_DisableAI = 1;
	};
};


// Check variables 
wmt_param_ViewDistance = 10 max wmt_param_ViewDistance;
wmt_param_TI = 0 max (2 min wmt_param_TI);
wmt_param_NameTag = 0 max (1 min wmt_param_NameTag);
wmt_param_MissionTime = 0 max wmt_param_MissionTime;
wmt_param_PrepareTime = 0 max wmt_param_PrepareTime;
wmt_param_StartZone = 10 max wmt_param_StartZone;
wmt_param_RemoveBots = 0 max wmt_param_RemoveBots;
wmt_param_HeavyLossesCoeff = 0.01 max wmt_param_HeavyLossesCoeff;
wmt_param_ShowEnemyVehiclesInNotes = 0 max (1 min wmt_param_ShowEnemyVehiclesInNotes);
wmt_param_GenerateFrequencies = 0 max (1 min wmt_param_GenerateFrequencies);

//================================================
//					ALL
//================================================
[] call WMT_fnc_DisableAI;

//================================================
//					SERVER
//================================================
if(isServer || isDedicated) then {
	[] spawn {
		if (wmt_param_GenerateFrequencies == 1) then {[] spawn WMT_fnc_DefaultFreqsServer;};
		["vehicle", [(wmt_param_TI==1)]] call WMT_fnc_DisableTI;
		[wmt_param_PrepareTime] call WMT_fnc_PrepareTime_server;
		if(wmt_param_MissionTime>0) then {
			[wmt_param_MissionTime,wmt_param_WinnerByTime,wmt_param_WinnerByTimeText] call WMT_fnc_EndMissionByTime;
		};
		[wmt_param_HeavyLossesCoeff, wmt_param_PrepareTime] call WMT_fnc_HeavyLossesCheck;
		if (wmt_param_RemoveBots > 0 ) then { [wmt_param_RemoveBots*60] spawn WMT_fnc_RemoveBots; };
	};

}; 

//================================================
//					CLIENT
//================================================
if(hasInterface) then {
	[] spawn {
		waitUntil{player==player};
		waitUntil{alive player};
		waitUntil{local player};

		WMT_Local_Killer = [];
		WMT_Local_Kills = [];
		WMT_Local_PlayerName = name player;
		WMT_Local_PlayerSide = side player;

		player setVariable ["WMT_PlayerName",WMT_Local_PlayerName,true];
		player setVariable ["WMT_PlayerSide",WMT_Local_PlayerSide,true];

		// Control veiw distance 
		["loop"] spawn WMT_fnc_handlerOptions;

		// Update information about admin (1 time in 15s)
		["loop"] spawn WMT_fnc_handlerFeedback;

		// Disable TI with using RscTitle 
		if(wmt_param_TI == 2) then {
			IDD_DISABLETI cutRsc ["RscDisableTI","PLAIN"];
		};

		// Show tag with name for near unit
		if(wmt_param_NameTag>0) then {
			IDD_NAMETAG cutRsc ["RscNameTag","PLAIN"];
		};

		// Add rating to disable change side to ENEMY 
		if(rating player < 100000) then {
			[] spawn {sleep 1;player addRating 500000;};
		};

		[] spawn {
			waitUntil {!(isNull (findDisplay 46))};
			(findDisplay 46) displayAddEventHandler ["KeyDown", "_this call WMT_fnc_KeyDown"];
		};

		player addEventHandler ["killed", "_this spawn WMT_fnc_PlayerKilled"];

		// Public variable handlers 
		"WMT_Global_EndMission" addPublicVariableEventHandler { (_this select 1) call WMT_fnc_EndMission };
		"WMT_Global_Announcement" addPublicVariableEventHandler { (_this select 1) call WMT_fnc_Announcement };
		"WMT_Global_AddKills" addPublicVariableEventHandler { WMT_Local_Kills=WMT_Local_Kills+(_this select 1) };

		// briefing
		[wmt_param_ShowEnemyVehiclesInNotes] call WMT_fnc_BriefingVehicles;
		[] call WMT_fnc_BriefingSquads;

		[wmt_param_PrepareTime,wmt_param_StartZone] spawn WMT_fnc_PrepareTime_client;
		
		// Draw markers on start position vehicles and groups
		[] spawn {
			PR(_markerPool) = [] call WMT_fnc_SpotMarkers;
			sleep 0.1;
			waitUntil{sleep 1.05; WMT_pub_frzState>=3};
			sleep 30;
			{deleteMarkerLocal _x;} foreach _markerPool;
		};
		if (wmt_param_GenerateFrequencies == 1) then {[] spawn WMT_fnc_DefaultFreqsClient;};
		if (wmt_param_RemoveBots > 0 ) then { [wmt_param_RemoveBots*60] spawn WMT_fnc_RemoveBots; };
	};
};