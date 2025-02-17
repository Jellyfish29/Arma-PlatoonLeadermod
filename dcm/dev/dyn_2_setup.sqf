

dyn2_main = {
    private _allTownLocations = nearestLocations [dyn2_map_center, ["NameCity", "NameVillage"], worldSize];
    dyn2_all_towns = _allTownLocations;
    private _largeTownLocations = [];
    private _smallTownLocations = [];
    {
        _loc = _x;
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


    _allAirFields = [] call dyn2_get_all_airports;


    {
        _loc = _x;
    } forEach _allOtherLocations;

    private _allObjectiveTypes = ["field_assault"];
    if !(_allAirFields isEqualTo []) then {_allObjectiveTypes pushBack "air_field_assault"};
    if !(_largeTownLocations isEqualTo []) then {_allObjectiveTypes pushBack "town_assault"};
    if !(_smallTownLocations isEqualTo []) then {_allObjectiveTypes pushBack "small_town_assault"};
    dyn2_missionType = selectRandom _allObjectiveTypes;

    // dyn2_missionType = "air_field_assault";

    switch (dyn2_missionType) do { 
        case "town_assault" : {[selectRandom _largeTownLocations] spawn dyn2_town_assault};
        case "small_town_assault" : {[selectRandom _smallTownLocations] spawn dyn2_small_town_assault}; 
        case "field_assault" : {[] spawn dyn2_field_assault};
        case "air_field_assault" : {[(selectRandom _allAirFields)#0] spawn dyn2_air_field_assault}; 
        default {[] spawn dyn2_field_assault}; 
    };

    [] spawn dyn_random_weather;

    [] spawn dyn2_random_day_time;

    sleep 4;

    {  
        _x addCuratorEditableObjects [allUnits, true];  
        _x addCuratorEditableObjects [vehicles, true];   
    } forEach allCurators; 

};

[] spawn dyn2_main;

// test = [getMarkerPos "comp_0" , 20, true] call BIS_fnc_objectsGrabber;

// systemChat str _comp_0;




