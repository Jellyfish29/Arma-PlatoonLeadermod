pl_unload_at_position_planed = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];

    if (vehicle (leader _group) == leader _group) exitWith {hint "Vehicle Only Task!"};

    _vic = vehicle (leader _group);
    _driver = driver _vic;
    _vicGroup = group _driver;
    _cargo = fullCrew [_vic, "cargo", false];

    _cargoGroups = [];
    {
        _unit = _x select 0;
        if !(_unit in (units _vicGroup)) then {
            _cargoGroups pushBack (group (_x select 0));
        };
    } forEach _cargo;

    _cargoGroups = _cargoGroups arrayIntersect _cargoGroups;

    if (_cargoGroups isEqualTo []) exitWith {hint "No Cargo to Unload"};

    if (count _taskPlanWp != 0) then {

        pl_draw_unload_inf_task_plan_icon_array pushBack [_cargoGroups#0, waypointPosition _taskPlanWp];

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 20) or !(_group getVariable ["pl_task_planed", false])};

        deleteWaypoint [_group, _taskPlanWp#1];

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    doStop _vic;
    {
        _unit = _x select 0;
        if !(_unit in (units _vicGroup)) then {
            unassignVehicle _unit;
            doGetOut _unit;
            [_unit] allowGetIn false;
        };
    } forEach _cargo;

    {
        [_x] call pl_show_group_icon;
        _x leaveVehicle _vic;
    } forEach _cargoGroups;

    playSound "beep";
    // _commander sideChat format ["Roger, %1 beginning unloading, over", groupId _group];
    waitUntil {sleep 0.1; ((count (fullCrew [_vic, "cargo", false])) == 0) or (!alive _vic)};
    playSound "beep";
    // _commander sideChat format ["%1 finished unloading, over", groupId _group];
    _vic setVariable ["pl_on_transport", nil];
    (group (driver _vic)) setVariable ["setSpecial", false];
    _vic doFollow _vic;
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


pl_draw_unload_inf_task_plan_icon = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos = [0, 15, 0] vectorAdd (_x#1);
                _color = [0.9,0.9,0,1];
                _display drawIcon [
                    '\A3\ui_f\data\map\markers\nato\b_inf.paa',
                    _color,
                    _pos,
                    15,
                    15,
                    0,
                    '',
                    2
                ];

                _mpos = _display ctrlMapScreenToWorld getMousePosition;
                if (inputAction 'zoomTemp' > 0 and (_mpos distance2D _pos) < 15) then {
                    pl_draw_unload_inf_task_plan_icon_array = pl_draw_unload_inf_task_plan_icon_array - [[_x#0, _x#1]];
                    [_x#0, _x#1] spawn pl_unload_inf_follow_up_plan;
                };

            } forEach pl_draw_unload_inf_task_plan_icon_array;
    "]; // "
};

[] call pl_draw_unload_inf_task_plan_icon;

pl_task_plan_menu_unloaded_inf = [
    ['Task Plan', true],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa'/><t> Assault Position</t>", [2], '', -5, [['expression', '["assault"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\AFP.paa'/><t> Defend Position</t>", [3], '', -5, [['expression', '["defend"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\SFP.paa'/><t> Take Position</t>", [4], '', -5, [['expression', '["defPos"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Lay Mine Field</t>', [6], '', -5, [['expression', '["mine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>', [7], '', -5, [['expression', '["charge"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1']
];


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
        case "assault" : {[_group, _wp] spawn pl_assault_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "defPos" : {[_group, _wp] spawn pl_take_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "mine" : {[_group, _wp] spawn pl_lay_mine_field; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"};
        case "charge" : {[_group, _wp] spawn pl_place_charge; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"};
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






pl_reset = {
    params ["_group", ["_isNotWp", true]];
    // resets and stops Group

    // reset individual units variables
    {
        _unit = _x;
        if ((currentCommand _unit) isEqualTo "SUPPORT") then {
            [_unit] spawn pl_hard_reset;
        };
        if !(_group getVariable ["pl_on_hold", false]) then {_unit enableAI "PATH"};
        _unit enableAI "AUTOCOMBAT";
        _unit enableAI "AUTOTARGET";
        _unit enableAI "TARGET";
        _unit enableAI "SUPPRESSION";
        _unit enableAI "COVER";
        _unit enableAI "ANIM";
        _unit enableAI "FSM";
        _unit setUnitPos "AUTO";
        // sleep 0.5;
        _unit limitSpeed 5000;
        _unit forceSpeed -1;
        _unit doWatch objNull;
        if (vehicle _unit == _unit) then {
            _unit doFollow (leader _group);
        };
    } forEach (units _group);
    
    // rejoin group hack
    _leader = leader _group;
    (units _group) joinSilent _group;
    _group selectLeader _leader;

    // if player group select player as leader
    if (_group isEqualTo (group player)) then {
        _group selectLeader player;
    };

    // reset Healing
    // _group setVariable ["pl_healing_active", nil];

    // if group is not leading a formation reset Task
    if !(!(_isNotWp) and (_group getVariable ["pl_formation_leader", false])) then {

        _group setVariable ["onTask", false];

        // if group is not transporting Infantry reset special Icon
        if !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa") then {
            if !(_group getVariable ["pl_on_hold", false]) then {
                _group setVariable ["setSpecial", false];
            };
        };
    };

    // reenable map info
    // _group setVariable ["pl_show_info", true];
    // reset convoc indicator
    _group setVariable ["pl_draw_convoy", false];

    // cancel planed Task
    _group setVariable ["pl_task_planed", false];

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        _vic forceSpeed -1;
        if (_vic getVariable ["pl_on_transport", false]) then {
            _vic setVariable ["pl_on_transport", nil];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa"];
        };

        // cancel planend tasks for loaded inf groups
        _cargo = fullCrew [_vic, "cargo", false];
        _cargoGroups = [];
        {
            _unit = _x select 0;
            if !(_unit in (units _group)) then {
                _cargoGroups pushBack (group (_x select 0));
            };
        } forEach _cargo;

        {
            [_x] spawn pl_reset;
        } forEach _cargoGroups;

    };

    // stop suppression

    if (_group getVariable ["pl_is_suppressing", false]) then {_group setVariable ["pl_is_suppressing", false]};

    // only delete Waypoints when not called from Move or MoveAdd
    if (_isNotWp) then {
        _group setSpeedMode "NORMAL";
        _group setBehaviour "AWARE";
        [_group, (currentWaypoint _group)] setWaypointType "MOVE";
        [_group, (currentWaypoint _group)] setWaypointPosition [getPosASL (leader _group), -1];
        sleep 0.1;
        deleteWaypoint [_group, (currentWaypoint _group)];
        for "_i" from count waypoints _group - 1 to 0 step -1 do {
            deleteWaypoint [_group, _i];
        };
    };
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
            [_x] spawn pl_reset;
        } forEach _cargoGroups;
    };
};
