

dyn_base_loc = getPos Player;
dyn_ao_markers = ["ao_0", "ao_1", "ao_2", "ao_3", "ao_4", "ao_5", "ao_6"];
dyn_map_center = [worldSize / 2, worldsize / 2, 0];
dyn_all_locations = nearestLocations [dyn_map_center, ["NameVillage", "Namecity"], 15000];
dyn_valid_locations = [];


dyn_add_locations = {
	{
		_loc = _x;
		{
			if ((getPos _loc) inArea _x) exitWith{
				dyn_valid_locations pushBack ["location", _loc];

				if (dyn_debug) then {
					_m = createMarker [str (random 2), getPos _loc];
					_m setMarkerType "mil_dot";
				};
			};
		} forEach dyn_ao_markers;
	} forEach dyn_all_locations;
};

dyn_add_random = {
	for "_i" from 0 to 25 do {

		private _randPoses = [];
		for "_j" from 0 to 3 do {
			_randPos = [[format ["ao_%1", _j]], ["water"]] call BIS_fnc_randomPos;
			_randPoses pushBack _randPos;
		};
		_r = selectRandom _randPoses;
		dyn_all_locations pushBack ["random", _r];

		if (dyn_debug) then {
			_m = createMarker [str (random 2), _r];
			_m setMarkerType "mil_dot";
			_m setMarkerColor "colorRED";
		};
	};
};

dyn_add_hill = {
	for "_i" from 0 to 7 do {
		_marker = format ["hill_%1", _i];
		_hillPos = getMarkerPos _marker;
		deleteMarker _marker;

		dyn_all_locations pushBack ["hill", _hillPos];

		if (dyn_debug) then {
			_m = createMarker [str (random 2), _hillPos];
			_m setMarkerType "mil_dot";
			_m setMarkerColor "colorORANGE";
		};

	};
};

[] call dyn_add_locations;
// [] call dyn_add_random;
// [] call dyn_add_hill:

dyn_main = {
	private ["_type", "_objPos", "_objLoc", "_objType", "_objInfo", "_endTrg", "_objMarker", "_taskText", "_taskName"];

	while {true} do {

		dyn_obj_loc = selectRandom dyn_valid_locations;
		_type = dyn_obj_loc#0;

		switch (_type) do { 
			case "random" : {
				_objPos = dyn_obj_loc#1;
				_objType = selectRandom [];
			}; 
			case "location" : {
				_objPos = getPos (dyn_obj_loc#1); 
				_objLoc = dyn_obj_loc#1;
				_objType = selectRandom ["sad_village"];
			};
			case "hill" : {
				_objPos = dyn_obj_loc#1;
				_objType = selectRandom [];
			}; 
			default {_objPos = dyn_obj_loc#1}; 
		};

		if (dyn_debug) then {
			_m = createMarker [str (random 2), _objPos];
			_m setMarkerType "mil_objective";
			_m setMarkerColor "colorRED";
		};

		// spawn objective
		switch (_objType) do { 
			case "sad_village" : {
				_objInfo = [_objPos] call dyn_sad_village;
				_taskText = format ["SAD VC around %1", text _objLoc];
			}; 
			case "sad_chache" : {  /*...code...*/ }; 
			case "defend_op" : {  /*...code...*/ }; 
			case "sad_patrol" : {  /*...code...*/ }; 
			case "kill_hvt" : {  /*...code...*/ }; 
			case "ambush" : {  /*...code...*/ }; 
			default {  /*...code...*/ }; 
		};

		_endTrg = _objInfo#0;
		_objMarker = _objInfo#1;
		_taskName = format ["task_%1", random 2];

		sleep 10;

		[west, _taskName, ["Offensive", _taskText, ""], _objPos, "ASSIGNED", 1, true, "attack", false] call BIS_fnc_taskCreate;

		sleep 1;
        { 
            _x addCuratorEditableObjects [allUnits, true]; 
            _x addCuratorEditableObjects [vehicles, true];  
        } forEach allCurators; 

		waitUntil {sleep 1; triggerActivated _endTrg};

		[_taskName, "SUCCEEDED", true] call BIS_fnc_taskSetState;
		deleteMarker _objMarker;

		_rtbTaskName = format ["RTB_task_%1", random 2];

		[west, _rtbTaskName , ["Offensive", "RTB", ""], dyn_base_loc, "ASSIGNED", 1, true, "move", false] call BIS_fnc_taskCreate;
	};
};

[] call dyn_main;