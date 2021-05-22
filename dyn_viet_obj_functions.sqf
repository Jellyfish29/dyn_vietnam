dyn_sad_village = {
	params ["_objPos"];
	private ["_endTrg", "_allGroups"];

	_aoSize = [400, 700] call BIS_fnc_randomInt;

    _endTrg = createTrigger ["EmptyDetector", _objPos, true];
    _endTrg setTriggerActivation ["WEST SEIZED", "PRESENT", false];
    _endTrg setTriggerStatements ["this", " ", " "];
    _endTrg setTriggerArea [_aoSize, _aoSize, 0, false];
    _endTrg setTriggerTimeout [120, 180, 240, false];

    _sadMarker = createMarker [format ["sad%1", _objPos], _objPos];
    _sadMarker setMarkerShape "ELLIPSE";
    _sadMarker setMarkerSize [_aoSize, _aoSize];
    _sadMarker setMarkerBrush "DiagGrid";
    _sadMarker setMarkerColor "colorOPFOR";
    _sadMarker setMarkerAlpha 0.5;

	_allGrps = [];
	_grps = [_objPos] call dyn_spawn_garrison_surrounding;
	_allGrps append _grps;

	_grps = [_objPos, 2, _aoSize] call dyn_spawn_large_patrols;
	_allGrps append _grps;

	_grps = [_objPos, 3, _aoSize] call dyn_spawn_small_patrols;
	_allGrps append _grps;

	_grps = [_objPos, 1] call dyn_spawn_ambush;
	_allGrps append _grps;

	[_endTrg, _sadMarker]
};

dyn_sad_chache = {
	
};

dyn_defend_op = {
	
};

dyn_sad_patrol = {
	
};

dyn_kill_hvt = {
	
};