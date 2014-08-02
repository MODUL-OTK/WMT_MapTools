/*
 	Name: WMT_fnc_InitModuleTaskArrived
 	
 	Author(s):
		Ezhuk
*/

#include "defines.sqf"

PR(_logic) = [_this,0,objNull,[objNull]] call BIS_fnc_param;
PR(_units) = [_this,1,[],[[]]] call BIS_fnc_param;
PR(_activated) = [_this,2,true,[true]] call BIS_fnc_param;

if(_activated) then {

	//===============================================================
	// 							Server part
	//===============================================================
	if(isServer) then {
		[_logic, _units, DELAY] spawn {
			PR(_logic) = _this select 0;
			PR(_units) = _this select 1;
			PR(_delay) = _this select 2;
			
			PR(_marker) = _logic getVariable "Marker";
			PR(_message)= _logic getVariable "Message";
			PR(_count)  = _logic getVariable "Count";
			PR(_winner)	= [east,west,resistance,civilian,sideLogic] select (_logic getVariable "Winner");
			
			PR(_c) = 0;
			PR(_objs) = _units;

			sleep _delay;
			
			while {_c < _count} do {
				PR(_o) = _objs;
				
				{
					if ([_x,_marker] call WMT_fnc_IsTheUnitInsideMarker) then {
						private ["_name", "_text"];
						_c = _c + 1;
						_objs = _objs - [_x];

						WMT_Global_Notice_ObjectArrived = [_winner, _x];
						publicVariable "WMT_Global_Notice_ObjectArrived";

						_name = _x getVariable ["WMT_DisplayName", getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName")];
						_text = _name + " " + localize "STR_WMT_Arrived";

						[_winner, _text] call WMT_fnc_ShowTaskNotification;

					};
				} foreach _o;

				sleep 4.13;
			};

			// End mission
			[[[_winner, _message], {_this call WMT_fnc_EndMission;}], "bis_fnc_spawn"] call bis_fnc_mp;
		};
	};
};