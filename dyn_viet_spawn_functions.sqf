

dyn_spawn_garrison_surrounding = {
    params ["_pos", ["_area", 250], ["_grpAmount", 1]];
    private ["_buildings", "_buildingPositions", "_grp", "_grps"];

    _buildings = nearestTerrainObjects [_pos, ["House"], _area];
    _buildingPositions = [];

    {
        _bPos = [_x] call BIS_fnc_buildingPositions;
        _buildingPositions append _bPos;
    } forEach _buildings;

    _grps = [];
    for "_i" from 1 to _grpAmount do {
        _infType = selectRandom dyn_standart_squads;
        _grp = [_pos, east, _infType] call dyn_spawn_group_woraround;
        _grps pushBack _grp;
        {
            if ((count _buildingPositions) > 0) then {
                _bPos = selectRandom _buildingPositions;
                _buildingPositions deleteAt (_buildingPositions find _bPos);
                _x setPos _bPos;
                _x disableAI "PATH";
            };
        } forEach (units _grp);
    };
    _grps
};

dyn_spawn_large_patrols = {
    params ["_pos", ["_grpAmount", 2], ["_area", 600]];
    private ["_patrolPath", "_grp", "_grps", "_wp"];

    _grps = [];
    for "_i" from 1 to _grpAmount do {
        _infType = selectRandom dyn_standart_squads;
        _sp = [[[_pos, _area]], ["water"]] call BIS_fnc_randomPos;
        _grp = [_sp, east, _infType] call dyn_spawn_group_woraround;
        _grp setBehaviour "SAFE";
        _grp setFormation "Column";
        _grps pushBack _grp;
        for "_j" from 0 to 4 do {
            _p = [[[_pos, _area]], ["water"]] call BIS_fnc_randomPos;
            _wp = _grp addWaypoint [_p, 0];
            if (_j == 4) then { 
                _wp setWaypointType "CYCLE";
            };
        };
    };
    _grps
};

dyn_spawn_small_patrols = {
    params ["_pos", ["_grpAmount", 2], ["_area", 600], ["_outerArea", 600]];
    private ["_patrolPath", "_grp", "_grps", "_wp"];

    _atkTrg = createTrigger ["EmptyDetector", _pos, true];
    _atkTrg setTriggerActivation ["WEST", "PRESENT", false];
    _atkTrg setTriggerStatements ["this", " ", " "];
    _atkTrg setTriggerArea [_area + _outerArea, _area + _outerArea, 0, false];

    _grps = [];
    for "_i" from 1 to _grpAmount do {
        _sp = [[[_pos, _area + _outerArea]], ["water", [_pos, _area]]] call BIS_fnc_randomPos;
        _grp = [_sp, east, dyn_small_squad] call dyn_spawn_group_woraround;
        _grp setBehaviour "SAFE";
        _grp setFormation "Column";
        _grps pushBack _grp;
        for "_j" from 0 to 2 do {
            _p = [[[_sp, 200]], ["water"]] call BIS_fnc_randomPos;
            _wp = _grp addWaypoint [_p, 0];
            if (_j == 2) then { 
                _wp setWaypointType "CYCLE";
            };
        };
    };
    [_atkTrg, _grps] spawn dyn_attack_nearest_enemy;
    _grps
};

dyn_spawn_ambush = {
    params ["_pos", ["_grpAmount", 2], ["_distance", 600]];
    private ["_grps", "_ambTrg"];

    _ambTrg = createTrigger ["EmptyDetector", _pos, true];
    _ambTrg setTriggerActivation ["WEST", "PRESENT", false];
    _ambTrg setTriggerStatements ["this", " ", " "];
    _ambTrg setTriggerArea [_distance * 2, _distance * 2, 0, false];

    _grps = [];
    for "_i" from 1 to _grpAmount do {
        _infType = selectRandom dyn_standart_squads;
        _sp = [[[_pos, 100]], ["water"]] call BIS_fnc_randomPos;
        _grp = [_sp, east, _infType] call dyn_spawn_group_woraround;
        _grp setFormation "Line";
        _grps pushBack _grp;
    };
    [_grps, _ambTrg, _pos, _distance] spawn {
        params ["_grps", "_ambTrg", "_defPos", "_distance"];

        waitUntil {sleep 1; triggerActivated _ambTrg};

        _units = allUnits+vehicles select {side _x == playerSide};
        _units = [_units, [], {_x distance2D _defPos}, "ASCEND"] call BIS_fnc_sortBy;
        _westPos = getPos (_units#0);

        _ambushDir = _defPos getDir _westPos;
        _ambushPos = [_distance * (sin _ambushDir), _distance * (cos _ambushDir), 0] vectorAdd _defPos;
        {
            _grp = _x;
            {
                _x setPos ([[[_ambushPos, 30]], ["water"]] call BIS_fnc_randomPos);
            } forEach (units _grp);
            _grp setFormDir _ambushDir;
        } forEach _grps;
        sleep 10;
        {
            _grp = _x;
            {
                [_x, _ambushDir, 10, false] spawn dyn_find_cover; 
            } forEach (units _grp);
            _grp setFormDir _ambushDir;
            [_grp, 300] spawn dyn_auto_suppress;
        } forEach _grps;
    };
    _grps
};