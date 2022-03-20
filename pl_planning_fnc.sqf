
pl_draw_planed_task_array = [];

pl_task_planer = {
    // plan Task to be executed when reaching a Waypoint

    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan Task!"};
    _group = _wp select 0;
    
    // if Task already planed exit
    if (_group getVariable ["pl_task_planed", false]) exitWith {hint format ["%1 already has a Task planed", groupId _group]};

    // if already on active Task exit
    if (_group getVariable ["onTask", false] and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa")) exitWith {hint format ["%1 already has a Task", groupId _group]};

    // delete following wps
    for "_i" from count waypoints _group - 1 to (_wp select 1) + 1 step -1 do {
            deleteWaypoint [_group, _i];
    };

    // set Variable
    _group setVariable ["pl_task_planed", true];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "resupply" : {[_group, _wp] spawn pl_supply_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"};
        case "recover" : {[_group, _wp] spawn pl_repair; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "mine" : {[_group, _wp] spawn pl_lay_mine_field; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        case "unload" : {[_group, _wp] spawn pl_unload_at_position_planed; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        case "mineclear" : {[_group, _wp] spawn pl_mine_clearing; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {sleep 1; !(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_draw_unload_inf_task_plan_icon_array = [];

pl_unload_inf_follow_up_plan = {
    params ["_group", "_cords"];
    
    waitUntil {inputAction 'zoomTemp' <= 0};

    sleep 0.2;

    missionNamespace setVariable ["pl_unload_inf_group_array", [_group, _cords]];
    showCommandingMenu '#USER:pl_task_plan_menu_unloaded_inf';

    sleep 0.2;

    waitUntil {!(commandingMenu == '#USER:pl_task_plan_menu_unloaded_inf')};

    sleep 0.2;

    if !(_group getVariable ["pl_task_planed", false]) then {
        pl_draw_unload_inf_task_plan_icon_array pushBack [_group, _cords];
    };

};

pl_task_planer_unload_inf = {
    // plan Task to be executed when reaching a Waypoint
    params ["_taskType"];
    private ["_group", "_wp", "_icon"];

    // get _wp and _group
    _group = (missionNamespace getVariable "pl_unload_inf_group_array")#0;
    _cords = (missionNamespace getVariable "pl_unload_inf_group_array")#1;
    _wp = _group addWaypoint [_cords, 0];

    sleep 0.2;

    // set Variable
    _group setVariable ["pl_task_planed", true];
    _group setVariable ["pl_unload_task_planed", true];

    // call task to be executed
    switch (_taskType) do {
        case "addwp" : {[_group, _wp] spawn pl_add_wp_planed; _icon = "\A3\3den\data\Attributes\SpeedMode\normal_ca.paa"};
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "defPos" : {[_group, _wp] spawn pl_take_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "mine" : {[_group, _wp] spawn pl_lay_mine_field; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "clearmine" : {[_group, _wp] spawn pl_mine_clearing; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
        default {}; 
    };

    // add indicator
    pl_draw_planed_task_array pushBack [_wp, _icon];

    // waituntil wp reached then delete indicator
    [_wp, _group, _icon] spawn {
        params ["_wp", "_group", "_icon"];
        waitUntil {!(_group getVariable ["pl_task_planed", true])};
        pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];
    };
};

pl_draw_planed_wps_dic = createHashMap;

pl_add_wp_planed = {
    params ["_group", "_startWp"];

    private _wpPath = [waypointPosition _startWp];
    pl_confirm_wps = false;
    private _i = 0;
    _callsign = groupId _group;
    pl_draw_planed_wps_dic set [_callsign, []];
    while {!pl_confirm_wps} do {

        onMapSingleClick {
            pl_wp_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_confirm_wps = true};
            hintSilent "";
            onMapSingleClick "";
        };


        while {!pl_mapClicked} do {
            sleep 0.05;
        };

        sleep 0.05;
        pl_mapClicked = false;
        _drawArray = pl_draw_planed_wps_dic get _callsign;
        _drawArray pushback [_wpPath#_i, pl_wp_cords];
        pl_draw_planed_wps_dic set [_callsign, _drawArray];
        _i = _i + 1;
        _wpPath pushback pl_wp_cords;
    };

    private _lastWpPos = pl_wp_cords;
    _wpPath deleteAt 0;

        // add Arrow indicator

    waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _startWp)) < 11 and (({vehicle _x != _x} count (units _group)) <= 0)) or !(_group getVariable ["pl_task_planed", false]) or (_group getVariable ["pl_disembark_finished", false])};
    _group setVariable ["pl_disembark_finished", nil];
    
    // remove Arrow indicator
    // pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _startWp, _icon]];

    if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
    _group setVariable ["pl_task_planed", false];

    pl_draw_planed_wps_dic deleteAt _callsign;
    if (pl_cancel_strike) exitwith {};

    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\3den\data\Attributes\SpeedMode\normal_ca.paa"];
    _group setVariable ["pl_on_march", true];

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
    (leader _group) limitSpeed 14;
    // _group setFormation "FILE";
    _group setBehaviour "AWARE";

    {
        _group addWaypoint [_x, 0];
    } forEach _wpPath;

    waitUntil {sleep 0.5; (((leader _group) distance2D _lastWpPos) < 11) or (isNil {_group getVariable ["pl_on_march", nil]})};
    _group setVariable ["pl_on_march", nil];
    _group setVariable ["setSpecial", false];
    {
        _x enableAI "AUTOCOMBAT";
    } forEach (units _group);
    (leader _group) limitSpeed 5000;
};

pl_cancel_planed_task = {
    // cancels planed Task

    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan cancel Task!"};
    _group = _wp select 0;
    _group setVariable ["pl_task_planed", false];


    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _cargo = fullCrew [_vic, "cargo", false];
        _cargoGroups = [];
        {
            _unit = _x select 0;
            if !(_unit in (units _group)) then {
                _cargoGroups pushBack (group (_x select 0));
            };
        } forEach _cargo;

        {
            _x setVariable ["pl_task_planed", false];
            _x setVariable ["pl_unload_task_planed", false];
            [_x, (currentWaypoint _x)] setWaypointType "MOVE";
            [_x, (currentWaypoint _x)] setWaypointPosition [getPosASL (leader _x), -1];
            sleep 0.1;
            deleteWaypoint [_x, (currentWaypoint _x)];
            for "_i" from count waypoints _x - 1 to 0 step -1 do {
                deleteWaypoint [_x, _i];
            };
        } forEach _cargoGroups;
    };
};