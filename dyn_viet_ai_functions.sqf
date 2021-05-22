
dyn_valid_cover = ["TREE", "SMALL TREE", "BUSH", "FOREST BORDER", "FOREST TRIANGLE", "FOREST SQUARE", "CHAPEL", "CROSS", "FOUNTAIN", "QUAY", "FENCE", "WALL", "HIDE", "BUSSTOP", "FOREST", "TRANSMITTER", "STACK", "RUIN", "TOURISM", "WATERTOWER", "ROCK", "ROCKS", "POWER LINES", "POWERSOLAR", "POWERWAVE", "POWERWIND", "SHIPWRECK"];
dyn_covers = [];

dyn_find_cover = {
    params ["_unit", "_watchDir", "_radius", "_moveBehind", ["_covers",  []]];

    (group _unit) setVariable ["onTask", true];
    _addCovers = nearestTerrainObjects [getPos _unit, dyn_valid_cover, _radius, true, true];
    _covers = _covers + _addCovers;
    // _unit enableAI "AUTOCOMBAT";
    _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd (getPos _unit);
    _unit setUnitPos "AUTO";
    if ((count _covers) > 0) then {
        {
            if !(_x in dyn_covers) exitWith {
                dyn_covers pushBack _x;
                _unit doMove (getPos _x);
                waitUntil {sleep 0.1; (unitReady _unit) or (!alive _unit)};
                _unit setUnitPos "MIDDLE";
                sleep 1;
                if (_moveBehind) then {
                    _moveDir = _watchDir - 180;
                    _coverPos =  [2*(sin _moveDir), 2*(cos _moveDir), 0] vectorAdd (getPos _unit);
                    _unit doMove _coverPos;
                    sleep 1;
                    waitUntil {sleep 0.1; (unitReady _unit) or (!alive _unit)};
                    doStop _unit;
                    _unit doWatch _watchPos;
                _unit disableAI "PATH";
                }
                else
                {
                    doStop _unit;
                    _unit doWatch _watchPos;
                };
            };
        } forEach _covers;
        if ((unitPos _unit) == "Auto") then {
            _unit setUnitPos "DOWN";
            doStop _unit;
            _unit doWatch _watchPos;
            _unit disableAI "PATH";
        };
    }
    else
    {
        _unit setUnitPos "DOWN";
        if (_moveBehind) then {
            _checkPos = [15*(sin _watchDir), 15*(cos _watchDir), 0.25] vectorAdd (getPosASL _unit);

            // _helper = createVehicle ["Sign_Sphere25cm_F", _checkPos, [], 0, "none"];
            // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
            // _helper setposASL _checkPos;
            // _cansee = [_helper, "VIEW"] checkVisibility [(eyePos _unit), _checkPos];

            _unitPos = [0, 0, 0.25] vectorAdd (getPosASL _unit);
            _cansee = [_unit, "VIEW"] checkVisibility [_unitPos, _checkPos];
            // _unit sideChat str _cansee;
            if (_cansee < 0.6) then {
                _unit setUnitPos "MIDDLE";
            };
        };
        doStop _unit;
        _unit doWatch _watchPos;
        _unit disableAI "PATH";
    };
};


dyn_garrison_building = {
    params ["_building", "_grp", "_dir"];
    private ["_validPos", "_allPos", "_bPos", "_units", "_watchPos", "_pos", "_unit"];
    _validPos = [];
    _allPos = [];
    _bPos = [_building] call BIS_fnc_buildingPositions;
    _units = units _grp;
    {
        _allPos pushBack _x;
        _watchPos = [10*(sin _dir), 10*(cos _dir), 1.7] vectorAdd _x;
        _standingPos = [0, 0, 1.7] vectorAdd _x;
        _standingPos = ATLToASL _standingPos;
        _watchPos = ATLToASL _watchPos;

        // _helper = createVehicle ["Sign_Sphere25cm_F", _x, [], 0, "none"];
        // _helper setObjectTexture [0,'#(argb,8,8,3)color(1,0,1,1)'];
        // _helper setposASL _standingPos;

        _cansee = [objNull, "VIEW"] checkVisibility [_standingPos, _watchPos];
        if (_cansee == 1) then {
            _validPos pushBack _x;
        };
    } forEach _bPos;

    _watchPos = [500 * (sin _dir), 500 * (cos _dir), 0] vectorAdd (getPos _building);
    _validPos = [_validPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;
    _allPos = _allPos - _validPos;
    _allPos = [_allPos, [], {_x distance2D _watchPos}, "ASCEND"] call BIS_fnc_sortBy;

    for "_i" from 0 to (count _units) - 1 step 1 do {

        if (_i < (count _validPos)) then {
            _pos = _validPos#_i;
            _unit = _units#_i;
        }
        else
        {
            _pos = _allPos#_i;
            _unit = _units#_i;
        };
        _pos = ATLToASL _pos;
        private _unitPos = "UP";
        _checkPos = [7*(sin _dir), 7*(cos _dir), 1.7] vectorAdd _pos;
        _crouchPos = [0, 0, 0.6] vectorAdd _pos;
        if (([objNull, "VIEW"] checkVisibility [_crouchPos, _checkPos]) == 1) then {
            _unitPos = "MIDDLE";
        };
        if (([objNull, "VIEW"] checkVisibility [_pos, _checkPos]) == 1) then {
            _unitPos = "DOWN";
        };

        _pos = ASLToATL _pos;

        _unit setPos _pos;
        _unit doWatch _watchPos;
        doStop _unit;
        _unit setUnitPos _unitPos;
        _unit disableAI "PATH";
    };
};

dyn_attack_nearest_enemy = {
    params ["_trg", "_grps"];

    if !(isNull _trg) then {
        waitUntil { sleep 1, triggerActivated _trg };
    };

    {
        _grp = _x;
        {
            _x enableAI "PATH";
            _x doFollow (leader _grp);
            _x setUnitPos "Auto";
            _x disableAI "AUTOCOMBAT"
        } forEach (units _grp);

        _grp setSpeedMode "Full";
        _grp setBehaviour "AWARE";

        [_grp] spawn {
            params ["_grp"];

            while {({alive _x} count (units _grp)) > 0} do {

                _units = allUnits+vehicles select {side _x == playerSide};
                _units = [_units, [], {_x distance2D (leader _grp)}, "ASCEND"] call BIS_fnc_sortBy;
                _atkPos = getPos (_units#0);

                [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
                [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
                sleep 0.1;
                deleteWaypoint [_grp, (currentWaypoint _grp)];
                for "_i" from count waypoints _grp - 1 to 0 step -1 do {
                    deleteWaypoint [_grp, _i];
                };

                _wp = _grp addWaypoint [_atkPos, 20];
                _wp setWaypointType "SAD";

                sleep 60;
            };
        };
    } forEach _grps;
};

dyn_suppressing_grps = 0;

dyn_select_atk_mode = {
    params ["_grp"];

    waitUntil { sleep 10; ((leader  _grp) distance2D ((leader  _grp) findNearestEnemy (leader  _grp))) < 450};

    _nearestGrp = {
        if ((group _x) != _grp) exitWith {group _x};
        grpNull
    } forEach (nearestObjects [getPos (leader _grp), ["Man"], 400, true]);
    if !(isNull _nearestGrp) then {
        if (_nearestGrp getVariable ["dyn_is_suppressing", false]) then {
            [_grp] spawn dyn_auto_attack;
        }
        else
        {
            [_grp] spawn dyn_auto_suppress;
        };
    }
    else
    {
        [_grp] spawn dyn_auto_suppress;
    };

};

dyn_auto_suppress = {
    params ["_grp", ["_range", 400], ["_cover", true]];

    _units = units _grp;
    _grp setVariable ["dyn_is_suppressing", true];

    waitUntil { sleep 2; ((leader  _grp) distance2D ((leader  _grp) findNearestEnemy (leader  _grp))) < _range};

    if (_cover) then {
        {
            [_x, getDir _x, 10, true] spawn dyn_find_cover;
        } forEach _units;

        sleep 15;
    };

    while {({alive _x} count _units) > 2} do {
        _target = (leader  _grp) findNearestEnemy (leader  _grp);
        {
            if !((currentCommand _x) isEqualTo "Suppress") then {
                _targetPos = [[[getPos _target, 30]], []] call BIS_fnc_randomPos;
                _targetPos = ATLToASL _targetPos;
                _vis = lineIntersectsSurfaces [eyePos _x, _targetPos, _x, vehicle _x, true, 1];
                if !(_vis isEqualTo []) then {
                    _targetPos = (_vis select 0) select 0;
                };
                _x doSuppressiveFire _targetPos;
            };
        } forEach _units;
        sleep 8;
        if (_grp getVariable ["dyn_is_retreating", false]) exitWith {};
    };
    _grp setVariable ["dyn_is_suppressing", false];
};

dyn_auto_attack = {
    params ["_grp"];

    _units = units _grp;
    // [_grp] call dyn_spawn_smoke;

    // waitUntil { sleep 10; ((leader  _grp) distance2D ((leader  _grp) findNearestEnemy (leader  _grp))) < 650};

    _grp setSpeedMode "FULL";
    {   
        _X setUnitPos "UP";
        _X disableAI "AUTOCOMBAT";
        _X disableAI "SUPPRESSION";
        _X disableAI "COVER";
        _x setSuppression 0;
        // _X disableAI "TARGET";
        _x setStamina 240;
        // _X disableAI "AUTOTARGET";
    } forEach (units _grp);

    [_grp, (currentWaypoint _grp)] setWaypointType "MOVE";
    [_grp, (currentWaypoint _grp)] setWaypointPosition [getPosASL (leader _grp), -1];
    sleep 0.1;
    deleteWaypoint [_grp, (currentWaypoint _grp)];
    for "_i" from count waypoints _grp - 1 to 0 step -1 do {
        deleteWaypoint [_grp, _i];
    };

    _targetPos = getPos ((leader  _grp) findNearestEnemy (leader  _grp));
    _wp = _grp addWaypoint [_targetPos, 20];
    _wp setWaypointType "SAD";

    waitUntil { sleep 2; ((leader  _grp) distance2D ((leader  _grp) findNearestEnemy (leader  _grp))) < 40 or _grp getVariable ["dyn_is_retreating", false]};

    {   
        _X setUnitPos "UP";
        _X enableAI "AUTOCOMBAT";
        _X enableAI "SUPPRESSION";
        _X enableAI "COVER";
    } forEach (units _grp);
    _grp setCombatMode "YELLOW";

};

dyn_garbage_clear = {

    sleep 240;

    {
        if (side _x != playerSide) then {
            deleteVehicle _x;
        };
    } forEach allDeadMen; 

    sleep 1;
    {
        deleteVehicle _x;
    } forEach (allMissionObjects "WeaponHolder");

    sleep 1;
    {
        if ((count units _x) isEqualTo 0) then {
            deleteGroup _x;
        };
    } forEach allGroups;

    sleep 1;
    {
        deleteVehicle _x;
    } forEach (allMissionObjects "CraterLong");

    sleep 1;
    _deadVicLimiter = 0;
    {
        if ((_x distance2D player) > 2000 and _deadVicLimiter <= 8) then {
            deleteVehicle _x;
            _deadVicLimiter = _deadVicLimiter + 1;
        };
    } forEach (allDead - allDeadMen);

    sleep 1;
    {
        if ((count (crew _x)) == 0) then {
            deleteVehicle _x;
        };
    } forEach (allMissionObjects "StaticWeapon");
};


dyn_forget_targets = {
    params ["_units"];

    {
        _wGrp = _x;
        {
            _wGrp forgetTarget _x;
        } forEach _units;
    } forEach (allGroups select {side _x == playerSide});  
};

dyn_get_cardinal = {
    params ["_ang"];
    private ["_compass"];
    _ang = _this select 0;
    _ang = _ang + 11.25; 
    if (_ang > 360) then {_ang = _ang - 360};
    _points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
    _num = floor (_ang / 22.5);
    _compass = _points select _num;
    _compass  
};

dyn_is_forest = {
    params ["_pos"];

    _trees = nearestTerrainObjects [_pos, ["Tree"], 50];

    if (count _trees > 25) exitWith {true};

    false
};


dyn_spawn_group_woraround = {
    
/*
    File: spawnGroup.sqf
    Author: Joris-Jan van 't Land, modified by Thomas Ryan

    Description:
    Function which handles the spawning of a dynamic group of characters.
    The composition of the group can be passed to the function.
    Alternatively a number can be passed and the function will spawn that
    amount of characters with a random type.

    Parameter(s):
    _this select 0: the group's starting position (Array)
    _this select 1: the group's side (Side)
    _this select 2: can be three different types:
        - list of character types (Array)
        - amount of characters (Number)
        - CfgGroups entry (Config)
    _this select 3: (optional) list of relative positions (Array)
    _this select 4: (optional) list of ranks (Array)
    _this select 5: (optional) skill range (Array)
    _this select 6: (optional) ammunition count range (Array)
    _this select 7: (optional) randomization controls (Array)
        0: amount of mandatory units (Number)
        1: spawn chance for the remaining units (Number)
    _this select 8: (optional) azimuth (Number)
    _this select 9: (optional) force precise position (Bool, default: true).
    _this select 10: (optional) max. number of vehicles (Number, default: 10e10).

    Returns:
    The group (Group)
*/

//Validate parameter count
if ((count _this) < 3) exitWith {debugLog "Log: [spawnGroup] Function requires at leat 3 parameters!"; grpNull};

private ["_pos", "_side"];
_pos = _this param [0, [], [[]]];
_side = _this param [1, sideUnknown, [sideUnknown]];

private ["_chars", "_charsType", "_types"];
_chars = _this param [2, [], [[], 0, configFile]];
_charsType = typeName _chars;
if (_charsType == (typeName [])) then
{
    _types = _chars;
}
else
{
    if (_charsType == (typeName 0)) then
    {
        //Only a count was given, so ask this function for a good composition.
        _types = [_side, _chars] call BIS_fnc_returnGroupComposition;
    }
    else
    {
        if (_charsType == (typeName configFile)) then
        {
            _types = [];
        };
    };
};

private ["_positions", "_ranks", "_skillRange", "_ammoRange", "_randomControls","_precisePosition","_maxVehicles"];
_positions = _this param [3, [], [[]]];
_ranks = _this param [4, [], [[]]];
_skillRange = _this param [5, [], [[]]];
_ammoRange = _this param [6, [], [[]]];
_randomControls = _this param [7, [-1, 1], [[]]];
_precisePosition = _this param [9,true,[true]];
_maxVehicles = _this param [10,10e10,[123]];

//Fetch the random controls.
private ["_minUnits", "_chance"];
_minUnits = _randomControls param [0, -1, [0]];
_chance = _randomControls param [1, 1, [0]];

private ["_azimuth"];
_azimuth = _this param [8, 0, [0]];

//Check parameter validity.
//TODO: Check for valid skill and ammo ranges?
if ((typeName _pos) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] Position (0) should be an Array!"; grpNull};
if ((count _pos) < 2) exitWith {debugLog "Log: [spawnGroup] Position (0) should contain at least 2 elements!"; grpNull};
if ((typeName _side) != (typeName sideEnemy)) exitWith {debugLog "Log: [spawnGroup] Side (1) should be of type Side!"; grpNull};
if ((typeName _positions) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] List of relative positions (3) should be an Array!"; grpNull};
if ((typeName _ranks) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] List of ranks (4) should be an Array!"; grpNull};
if ((typeName _skillRange) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] Skill range (5) should be an Array!"; grpNull};
if ((typeName _ammoRange) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] Ammo range (6) should be an Array!"; grpNull};
if ((typeName _randomControls) != (typeName [])) exitWith {debugLog "Log: [spawnGroup] Random controls (7) should be an Array!"; grpNull};
if ((typeName _minUnits) != (typeName 0)) exitWith {debugLog "Log: [spawnGroup] Mandatory units (7 select 0) should be a Number!"; grpNull};
if ((typeName _chance) != (typeName 0)) exitWith {debugLog "Log: [spawnGroup] Spawn chance (7 select 1) should be a Number!"; grpNull};
if ((typeName _azimuth) != (typeName 0)) exitWith {debugLog "Log: [spawnGroup] Azimuth (8) should be a Number!"; grpNull};
if ((_minUnits != -1) && (_minUnits < 1)) exitWith {debugLog "Log: [spawnGroup] Mandatory units (7 select 0) should be at least 1!"; grpNull};
if ((_chance < 0) || (_chance > 1)) exitWith {debugLog "Log: [spawnGroup] Spawn chance (7 select 1) should be between 0 and 1!"; grpNull};
if (((count _positions) > 0) && ((count _types) != (count _positions))) exitWith {debugLog "Log: [spawnGroup] List of positions (3) should contain an equal amount of elements to the list of types (2)!"; grpNull};
if (((count _ranks) > 0) && ((count _types) != (count _ranks))) exitWith {debugLog "Log: [spawnGroup] List of ranks (4) should contain an equal amount of elements to the list of types (2)!"; grpNull};

//Convert a CfgGroups entry to types, positions and ranks.
if (_charsType == (typeName configFile)) then
{
    _ranks = [];
    _positions = [];

    for "_i" from 0 to ((count _chars) - 1) do
    {
        private ["_item"];
        _item = _chars select _i;

        if (isClass _item) then
        {
            _types = _types + [getText(_item >> "vehicle")];
            _ranks = _ranks + [getText(_item >> "rank")];
            _positions = _positions + [getArray(_item >> "position")];
        };
    };
};

private ["_grp","_vehicles","_isMan","_type"];
_grp = createGroup _side;
_vehicles = 0;      //spawned vehicles count

//Create the units according to the selected types.
for "_i" from 0 to ((count _types) - 1) do
{
    //Check if max. of vehicles was already spawned
    _type = _types select _i;
    _isMan = getNumber(configFile >> "CfgVehicles" >> _type >> "isMan") == 1;

    if !(_isMan) then
    {
        _vehicles = _vehicles + 1;
    };

    if (_vehicles > _maxVehicles) exitWith {};

    //See if this unit should be skipped.
    private ["_skip"];
    _skip = false;
    if (_minUnits != -1) then
    {
        //Has the mandatory minimum been reached?
        if (_i > (_minUnits - 1)) then
        {
            //Has the spawn chance been satisfied?
            if ((random 1) > _chance) then {_skip = true};
        };
    };

    if (!_skip) then
    {
        private ["_unit"];

        //If given, use relative position.
        private ["_itemPos"];
        if ((count _positions) > 0) then
        {
            private ["_relPos"];
            _relPos = _positions select _i;
            _itemPos = call compile format ["[(_pos select 0) + (_relPos select 0), (_pos select 1) + %1]", (_relPos select 1)];
        }
        else
        {
            _itemPos = _pos;
        };

        //Is this a character or vehicle?
        if (_isMan) then
        {
            _unit = _grp createUnit [_type, _itemPos, [], 0, "FORM"];
            _unit setDir _azimuth;
        }
        else
        {
            _unit = ([_itemPos, _azimuth, _type, _grp, _precisePosition] call BIS_fnc_spawnVehicle) select 0;
        };

        //If given, set the unit's rank.
        if ((count _ranks) > 0) then
        {
            [_unit,_ranks select _i] call bis_fnc_setRank;
        };

        //If a range was given, set a random skill.
        if ((count _skillRange) > 0) then
        {
            private ["_minSkill", "_maxSkill", "_diff"];
            _minSkill = _skillRange select 0;
            _maxSkill = _skillRange select 1;
            _diff = _maxSkill - _minSkill;

            _unit setUnitAbility (_minSkill + (random _diff));
        };

        //If a range was given, set a random ammo count.
        if ((count _ammoRange) > 0) then
        {
            private ["_minAmmo", "_maxAmmo", "_diff"];
            _minAmmo = _ammoRange select 0;
            _maxAmmo = _ammoRange select 1;
            _diff = _maxAmmo - _minAmmo;

            _unit setVehicleAmmo (_minAmmo + (random _diff));
        };
    };
};


//--- Sort group members by ranks (the same as 2D editor does it)
private ["_newGrp"];
_newGrp = createGroup _side;
while {count units _grp > 0} do {
    private ["_maxRank","_unit"];
    _maxRank = -1;
    _unit = objnull;
    {
        _rank = rankid _x;
        if (_rank > _maxRank || (_rank == _maxRank && (group effectivecommander vehicle _unit == _newGrp) && effectivecommander vehicle _x == _x)) then {_maxRank = _rank; _unit = _x;};
    } foreach units _grp;
    [_unit] joinsilent _newGrp;
};
_newGrp selectleader (units _newGrp select 0);
deletegroup _grp;

_newGrp
};