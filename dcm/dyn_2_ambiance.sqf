dyn_random_weather = {

    if !(dyn2_weather) exitwith {0};
 
    skipTime -24;
    _overcast = selectRandom [0, 0, 0.1, 0.1, 0.3, 0.5, 0.8, 0.9, 1];
    // _overcast = 1;
    86400 setOvercast _overcast;
    // 86400 setFog [selectRandom [0, 0, 0, 0.05, 0.1, 0.12], 0.01, 250];

    skipTime 24;

    if (overcast >= 0.8) then {
        0 setRain (_overcast - 0.3);
        if (_overcast >= 0.95) then {
            0 setLightnings 0.5;
        };
    };

    4800 setFog 0;
    0 = [] spawn {
        sleep 0.1;
        simulWeatherSync;

        while {true} do {
            _overcast = selectRandom [0, 0.1, 0.3, 0.5, 0.8, 0.9, 1];
            1800 setOvercast _overcast;
            if (overcast >= 0.8) then {
                500 setRain (_overcast - 0.3);
                if (_overcast >= 0.95) then {
                    500 setLightnings 0.5;
                } else {
                    500 setLightnings 0;
                };
            } else {
                500 setRain 0;
                500 setLightnings 0;
            };
            sleep 0.1;
            simulWeatherSync;
            sleep 1800;
        };
    };
};

dyn2_cvivilian_presence = {
    params ["_loc", ["_civAmount", 30], ["_maxParkedCars", 10], ["_maxMovingCars", 6], ["_area", 400]];

    if !(dyn2_Civilians) exitwith {0};

    private _locPos = getPos _loc;
    private _allBuildings = nearestObjects [getPos _loc, ["house"], _area];
    private _allRoads = _locPos nearRoads _area;

    _moduleGrp = createGroup civilian;

    _main = _moduleGrp createUnit ["ModuleCivilianPresence_F", _locPos, [], 0, "NONE"];
    _main setVariable ["#useagents", true];
    _main setVariable ["#unitcount", _civAmount];
    _main setVariable ["#usepanicmode", true];
    _main setVariable ["#debug", false];
    _main setVariable ["objectarea", [_area + 100, _area + 100, 20,false,0]];

    private _limit = 0;
    for "_i" from 0 to (count _allBuildings) step 4 do {

        _building = selectRandom _allBuildings;
        _allBuildings deleteAt (_allBuildings find _building);

        _buildMod = _moduleGrp createUnit ["ModuleCivilianPresenceSafeSpot_F", getPos _building, [], 0, "NONE"];
        _buildMod setVariable ["#capacity", 4];
        _buildMod setVariable ["#usebuilding", true];
        _buildMod setVariable ["#type", 0];
        if (_i % 4 == 0) then {
            _wpMod = _moduleGrp createUnit ["ModuleCivilianPresenceUnit_F", getPos _building, [], 0, "NONE"];
        };
        _limit = _limit + 1;
        if (_limit > 45) exitWith {};
    };

    _limit = 0;
    for "_i" from 0 to (count _allRoads) step 4 do {
        _road = selectRandom _allRoads;
        _allRoads deleteAt (_allRoads find _road);

        _wpMod = _moduleGrp createUnit ["ModuleCivilianPresenceSafeSpot_F", getPos _road, [], 0, "NONE"];
        _wpMod setVariable ["#capacity", 3];
        _wpMod setVariable ["#usebuilding", false];
        _wpMod setVariable ["#type", 2];

        if (_i % 4 == 0) then {
            _wpMod = _moduleGrp createUnit ["ModuleCivilianPresenceUnit_F", getPos _road, [], 0, "NONE"];
        };


        _limit = _limit + 1;
        if (_limit > 45) exitWith {};

    };

    // _furModule = _moduleGrp createUnit ["gm_moduleFurniture", _locPos, [],0 , ""];
    // _furModule setVariable ["objectarea", [500, 500, 20,false,0]];

    _allRoads = _locPos nearRoads _area;
    for "_i" from 1 to _maxParkedCars do {
        _road = selectRandom _allRoads;
        _allRoads deleteAt (_allRoads find _road);
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _vicType = selectRandom dyn2_civilian_cars;

        _car = createVehicle [_vicType, (getPos _road) getPos [_roadWidth / 2, _roadDir + (selectRandom [90, -90])], [], 0, "NONE"];
        _car setDir _roadDir;
        _car enableDynamicSimulation true;
    };

    _allRoads = _locPos nearRoads _area * 2;
    for "_i" from 1 to _maxMovingCars do {
        _road = selectRandom _allRoads;
        _info = getRoadInfo _road;    
        _roadWidth = _info#1;
        _endings = [_info#6, _info#7];
        _roadDir = (_endings#1) getDir (_endings#0);
        _allRoads deleteAt (_allRoads find _road);
        _car = createVehicle [selectRandom dyn2_civilian_cars, getPos _road, [], 0, "NONE"];
        _car setDir _roadDir;
        _car limitSpeed 20;
        _car forceSpeed 20;
        _car enableDynamicSimulation true;
        // _car forceFollowRoad true;
        _carGrp = createVehicleCrew _car;
        _carGrp setBehaviour "SAFE";
        _carGrp enableDynamicSimulation true;

        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad = {
            if ((getPos _x) distance2d (getPos _road) > 300) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad);
        _allRoads = _allRoads call BIS_fnc_arrayShuffle;
        _targetRoad2 = {
            if ((getPos _x) distance2d (getPos _targetRoad) > 300) exitWith {_x};
            objNull
        } forEach _allRoads;
        _allRoads deleteAt (_allRoads find _targetRoad2);

        _wp = _carGrp addWaypoint [getPos _targetRoad, -1];
        // _wp = _carGrp addWaypoint [_targetRoad2, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp = _carGrp addWaypoint [getPos _road, -1];
        _wp setWaypointType "CYCLE";
    };

};
