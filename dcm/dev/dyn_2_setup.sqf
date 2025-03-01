

dyn2_main = {
    private _allTownLocations = nearestLocations [dyn2_map_center, ["NameCity", "NameVillage"], worldSize];
    dyn2_all_towns = _allTownLocations;
    private _largeTownLocations = [];
    private _smallTownLocations = [];
    private _blacklist = ["dcm_blk_marker_1", "dcm_blk_marker_2", "dcm_blk_marker_3"];
    private _allSrategicLocations = nearestLocations [dyn2_map_center, ["NameLocal"], worldSize];
    private _strategicLocations = [];


    {
        _loc = _x;
        {
            if ((toUpper (text _loc)) find (toUpper _x) != -1) then {
                _strategicLocations pushBackUnique _loc;
            };
        } forEach ["factory", "airbase", "terminal", "storage", "power", "port", "quarry", "plant"]; // "military"
    } forEach _allSrategicLocations;

    pl_debug_array = +_strategicLocations;

    {
        _loc = _x;

        _valid = {
            if ((getPos _loc) inArea _x) exitWith {false};
            true
        } forEach _blacklist;

        if !(_valid) then {continue};

        if (count (nearestObjects [getPos _loc, ["house"], 200]) >= 30) then {
            _largeTownLocations pushBack _loc;
            [getPos _loc, 600] spawn dyn2_hide_fences;

            // _m = createMarker [str (random 1), getPos _loc];
            // _m setMarkerType "mil_circle";
            // _m setMarkerColor "colorBlue";
        } else {
            _smallTownLocations pushBack _loc;
            [getPos _loc, 300] spawn dyn2_hide_fences;
        };
    } forEach _allTownLocations;

    private _allOtherLocations = nearestLocations [dyn2_map_center, ["NameLocal"], worldSize];


    _allAirFields = [_blacklist] call dyn2_get_all_airports;


    {
        _loc = _x;
    } forEach _allOtherLocations;

    private _allObjectiveTypes = ["field_assault"];
    if !(_allAirFields isEqualTo []) then {_allObjectiveTypes pushBack "air_field_assault"; _allObjectiveTypes pushBackUnique "defence";};// _allObjectiveTypes pushBack "air_assault_attack"; _allObjectiveTypes pushBackUnique "air_assault_defend";};
    if !(_largeTownLocations isEqualTo []) then {_allObjectiveTypes pushBack "town_assault"; _allObjectiveTypes pushBackUnique "defence";};
    if !(_smallTownLocations isEqualTo []) then {_allObjectiveTypes pushBack "small_town_assault"; _allObjectiveTypes pushBackUnique "defence";};
    // if !(_strategicLocations isEqualTo []) then {_allObjectiveTypes pushBack "air_assault_attack";};// _allObjectiveTypes pushBackUnique "air_assault_defend"};
    dyn2_missionType = selectRandom _allObjectiveTypes;

    // dyn2_missionType = "defence";

    switch (dyn2_missionType) do { 
        case "town_assault" : {[selectRandom _largeTownLocations] spawn dyn2_town_assault};
        case "small_town_assault" : {[selectRandom _smallTownLocations] spawn dyn2_small_town_assault}; 
        case "field_assault" : {[_blacklist] spawn dyn2_field_assault};
        case "air_field_assault" : {[(selectRandom _allAirFields)#0] spawn dyn2_air_field_assault};
        case "defence" : {[selectRandom (_largeTownLocations + _smallTownLocations)] spawn dyn2_defence}; 
        case "air_assault_attack" : {[selectRandom (_strategicLocations + _smallTownLocations)] spawn dyn2_air_assault_attack};
        case "air_assault_defend" : {[selectRandom (_strategicLocations + _smallTownLocations)] spawn dyn2_air_assault_defend}; 
        default {[] spawn dyn2_field_assault}; 
    };

    [] spawn dyn_random_weather;

    [] spawn dyn2_random_day_time;

    sleep 4;

    {
        deletemarker _x;
    } forEach _blacklist;

    {  
        _x addCuratorEditableObjects [allUnits, true];  
        _x addCuratorEditableObjects [vehicles, true];   
    } forEach allCurators; 

};

[] spawn dyn2_main;

// test = [getMarkerPos "comp_0" , 20, true] call BIS_fnc_objectsGrabber;

// systemChat str _comp_0;




