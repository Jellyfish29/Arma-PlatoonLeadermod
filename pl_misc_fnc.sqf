#include "\a3\editor_f\Data\Scripts\dikCodes.h"
pl_follow_active = false;
pl_follow_array = [];


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
    _group setVariable ["pl_show_info", true];
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
    };

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

pl_spawn_reset = {
    {
        [_x] spawn pl_reset;
    } forEach hcSelected player;
};

pl_hold = {
    // disables pathfinding on group

    params ["_group"];
    playSound "beep";

    // set Variable
    _group setVariable ["pl_on_hold", true];

    // if not already having special set, set special
    if !(_group getVariable ["setSpecial", false]) then {
        _group setVariable ["setSpecial", true];
        // if not on Transportmission
        if !((vehicle (leader _group)) getVariable ["pl_on_transport", false]) then {
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa"];
        };
    };

    // disable "PATH" for each unit
    {
        _x disableAI "PATH";   
    } forEach (units _group);  
};

pl_spawn_hold = {
    {
        [_x] spawn pl_hold;
    } forEach hcSelected player;
};

pl_execute = {
    params ["_group"];
    playSound "beep";
    _group setVariable ["pl_on_hold", false];

    // if icon == "wait" disable icon
    if ((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa") then {
        _group setVariable ["setSpecial", false];
    };

    // if group not on task and not on transport mission disable icon
    if (!(_group getVariable "onTask") and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa")) then {
        _group setVariable ["setSpecial", false];
    };

    // if on transport mission set land icon
    if ((vehicle (leader _group)) getVariable ["pl_on_transport", false]) then {
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa"];
    };

    // reeanable "PATH"
    {
        _x enableAI "PATH";
        // _x doFollow (leader _group);
    } forEach (units _group);

    // (units _group) joinSilent _group;
};

pl_spawn_execute = {
    {
        [_x] spawn pl_execute;
    } forEach hcSelected player;
};

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
    if (_group getVariable "pl_task_planed") exitWith {hint format ["%1 already has a Task planed", groupId _group]};

    // if already on active Task exit
    if (_group getVariable "onTask" and !((_group getVariable "specialIcon") isEqualTo "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa")) exitWith {hint format ["%1 already has a Task", groupId _group]};

    // delete following wps
    for "_i" from count waypoints _group - 1 to (_wp select 1) + 1 step -1 do {
            deleteWaypoint [_group, _i];
    };

    // set Variable
    _group setVariable ["pl_task_planed", true];

    // call task to be executed
    switch (_taskType) do { 
        case "assault" : {[_group, [0,0,0], _wp] spawn pl_attack; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa"};
        case "defend" : {[_group, _wp] spawn pl_defend_position; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "cover" : {[_group, _wp] spawn pl_take_cover; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"};
        case "360" : {[_group, 15, _wp] spawn pl_360_at_mappos; _icon = "\A3\ui_f\data\map\markers\military\circle_CA.paa"};
        case "clear" : {[_group, _wp] spawn pl_sweep_area; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"};
        case "buildings" : {[_group, _wp] spawn pl_garrison_area_building; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa"};
        case "resupply" : {[_group, _wp] spawn pl_resupply; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"};
        case "recover" : {[_group, _wp] spawn pl_repair; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
        case "maintenance" : {[_group, _wp] spawn pl_maintenance_point; _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"};
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

pl_cancel_planed_task = {
    // cancels planed Task

    _logic = player getvariable "BIS_HC_scope";
    _wp = _logic getvariable "WPover";
    if ((count _wp) == 1) exitWith {hint "Keep Mouse over Waypoint to plan cancel Task!"};
    _group = _wp select 0;
    _group setVariable ["pl_task_planed", false];
};



pl_select_group = {
    // select hcGroup form player cursorTraget

    _target = cursorTarget;
    _group = group _target;
    player hcSelectGroup [_group];
    sleep 2;
};


pl_remote_camera_in = {
    params ["_leader"];

    _leader switchCamera "GROUP";  
};

pl_spawn_cam = {
    [leader (hcSelected player select 0)] call pl_remote_camera_in;
};

pl_remote_camera_out = {

    player switchCamera "EXTERNAL";  
};

pl_angle_switcher = {
    params ["_a"];
    if (_a > 360) then {
        _a = _a - 360;
    }
    else
    {
        _a = _a + 360;
    };
    _a
};

pl_watch_dir = {
    // order group to watch direction and vehicles to turn in direction

    params ["_group"];
    private ["_watchPos"];


    playSound "beep";
    _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    _groupPos = getPos (leader _group);
    _watchDir = [_cords, _groupPos] call BIS_fnc_dirTo;

    _leader = leader _group;
        if (_leader == vehicle _leader) then {
        _group setFormDir _watchDir;
        _watchDir = [(_watchDir - 180)] call pl_angle_switcher;
        _watchPos = [1000*(sin _watchDir), 1000*(cos _watchDir), 0] vectorAdd _groupPos;
        {
            _x doWatch _watchPos;
        } forEach (units _group);
    }
    else
    {
        _vic = vehicle _leader;
        _pos = [_vic, (_watchDir - 180)] call pl_get_turn_vehicle;
        _vic doMove _pos;
    };
};


pl_get_turn_vehicle = {
    params ["_vic", "_turnDir"];

    private _pos = [];
    private _min = 20;      // Minimum range
    private _i = 0;         // iterations

    while {_pos isEqualTo []} do {
        _pos = (_vic getPos [_min, _turnDir]) findEmptyPosition [0, 2.2, typeOf _vic];

        // water
        if !(_pos isEqualTo []) then {if (surfaceIsWater _pos) then {_pos = []};};

        // update
        _min = _min + 15;
        _i = _i + 1;
        if (_i > 6) exitWith {_pos = _vic modelToWorldVisual [0, -100, 0]};
    };
    _pos
};
pl_spawn_watch_dir = {
    {
        [_x] spawn pl_watch_dir;
    } forEach hcSelected player;  
};

pl_set_unit_pos = {
    params ["_group", "_stance"];

    {
        _x setUnitPos _stance;
    } forEach (units _group);
};

pl_spawn_set_unit_pos = {
    params ["_stance"];

    {
        [_x, _stance] spawn pl_spawn_set_unit_pos;
    } forEach hcSelected player;  
};

pl_hold_fire = {
    params ["_group"];

    playSound "beep";

    _group setCombatMode "GREEN";
    _group setVariable ["pl_hold_fire", true];
    _group setVariable ["pl_combat_mode", true];
};

pl_open_fire = {
    params ["_group"];

    playSound "beep";

    _group setCombatMode "YELLOW";
    _group setVariable ["pl_hold_fire", false];
    _group setVariable ["pl_combat_mode", false];
};

pl_follow = {
    params ["_arrayId"];
    private ["_formDir", "_posOffset", "_pGroup", "_pSpeed", "_pBehaviour"];
    pl_follow_array append hcSelected player;
    pl_follow_active = true;
    _formDir = getDir player;
    {
        if (_x != (group player)) then {
            [_x] call pl_reset;

            sleep 0.2;

            _x setVariable ["onTask", true];
            _x setVariable ["setSpecial", true];
            _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
            playSound "beep";
            // leader _x sideChat format ["%1 is forming up on %2, over",(groupId _x), (groupId (group player))];
            _pos1 = getPos (leader _x);
            _pos2 = getPos player;
            _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
            _x setVariable ["pl_rel_pos", _relPos];
            {
                _x disableAI "AUTOCOMBAT";
            } forEach (units _x);
            _x setFormDir _formDir;
        };
    } forEach pl_follow_array;
    _pGroup = (group player);
    _pGroup setVariable ["onTask", true];
    _pGroup setVariable ["setSpecial", true];
    _pGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\whiteboard_ca.paa"];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _pGroup);
    pl_follow_array = pl_follow_array - [_pGroup];

    if (pl_follow_active) then {
        while {pl_follow_active} do {
            _pos1 = getPos player;
            sleep 2;
            _pos2 = getPos player;
            _posOffset = [(_pos2 select 0) - (_pos1 select 0), (_pos2 select 1) - (_pos1 select 1)];
            _pBehaviour = behaviour player;
            // _pSpeed = speed player + 1;
            // if (_pSpeed < 12) then {
            //     _pSpeed = 12;
            // };
            {
                _x setBehaviour _pBehaviour;
                if (!(_x getVariable "onTask") or ((count (waypoints _x) > 0))) then {
                    pl_follow_array = pl_follow_array - [_x];
                    _x setVariable ["onTask", false];
                    _x setVariable ["setSpecial", false];
                    {
                        _x enableAI "AUTOCOMBAT";
                    } forEach (units _x);
                }
                else
                {
                    _leader = leader _x;
                    _relPos = _x getVariable "pl_rel_pos";
                    if (vehicle _leader != _leader) then {
                        (vehicle _leader) limitSpeed 18;
                        if ((speed (vehicle _leader)) < 1) then {
                            _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                            driver (vehicle _leader) doMove _newPos;
                        };
                        if ((speed player) < 1) then {
                            _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                            driver (vehicle _leader) doMove _newPos;
                        };
                    }
                    else
                    {
                        _newPos = [((getPos player) select 0) + (_relPos select 0), ((getPos player) select 1) + (_relPos select 1)];
                        _leader limitSpeed 15;
                        _leader doMove _newPos;
                        {
                            if (_x != _leader) then {
                                _x doFollow _leader;
                            };
                        } forEach (units _x);
                    };
                };
            } forEach pl_follow_array;
            if ((count pl_follow_array) == 0) exitWith {pl_follow_active = false};
            if !((group player) getVariable "onTask") exitWith {pl_follow_active = false};
        };
        {
            _x setVariable ["onTask", false];
            _x setVariable ["setSpecial", false];
            {
                _x enableAI "AUTOCOMBAT";
            } forEach (units _x);
        } forEach pl_follow_array;
        _pGroup setVariable ["onTask", false];
        _pGroup setVariable ["setSpecial", false];
    };
};



pl_follow_array_other = [];
pl_follow_array_other_setup = [];

pl_follow_other = {
    params ["_group"];
    private ["_leadGroup", "_formDir", "_posOffset", "_pGroup", "_pSpeed", "_pBehaviour"];

    if !(visibleMap) exitWith {hint "Opne Map"};
    if (_group getVariable ["pl_formation_leader", false]) exitWith {hint format ["%1 is already leading a Formation", groupId _group]};

    _message = "Select Group to follow <br /><br />
    <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t> <br />";
    hint parseText _message;

    pl_follow_array_other_setup = pl_follow_array_other_setup + [_group];

    missionNamespace setVariable ["pl_select_formation_leader", true];
    waitUntil {!(missionNamespace getVariable ["pl_select_formation_leader", true])};

    pl_follow_array_other_setup = pl_follow_array_other_setup - [_group];

    hintSilent "";
    _leadGroup =  missionNamespace getVariable "pl_formation_leader";
    if (_leadGroup isEqualTo (group player)) exitWith {hint "Select 'Form on Commander' instead"};
    if (_leadGroup getVariable ["pl_following_formation", false]) exitWith {hint format ["%1 is already following a Formation", groupId _leadGroup]};
    if (missionNamespace getVariable ["pl_formation_cancel", false]) exitWith {};
    if (_group isEqualTo _leadGroup) exitWith {};


    [_group] call pl_reset;

    sleep 0.2;

    _formDir = getDir (leader _leadGroup);
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa"];
    _group setVariable ["pl_following_formation", true];
    playSound "beep";

    _pos1 = getPos (leader _group);
    _pos2 = getPos (leader _leadGroup);
    _relPos = [(_pos1 select 0) - (_pos2 select 0), (_pos1 select 1) - (_pos2 select 1)];
    _group setVariable ["pl_rel_pos", _relPos];
    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _group);
     _group setFormDir _formDir;
    
    if !(_leadGroup getVariable ["pl_formation_leader", false]) then {
        [_leadGroup] call pl_reset;

        sleep 0.2;

        _leadGroup setVariable ["onTask", true];
        _leadGroup setVariable ["setSpecial", true];
        _leadGroup setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\whiteboard_ca.paa"];
        _leadGroup setVariable ["pl_formation_leader", true];
    };

    {
        _x disableAI "AUTOCOMBAT";
    } forEach (units _leadGroup);

    pl_follow_array_other = pl_follow_array_other + [[_leadGroup, _group]];

    while {(_leadGroup getVariable ["onTask", true]) and (_group getVariable ["onTask", true])} do {
        _pos1 = getPos (leader _leadGroup);
        sleep 2;
        _pos2 = getPos (leader _leadGroup);
        _posOffset = [(_pos2 select 0) - (_pos1 select 0), (_pos2 select 1) - (_pos1 select 1)];

        _pBehaviour = behaviour (leader _leadGroup);
        _group setBehaviour _pBehaviour;

        _pSpeed = speedMode _leadGroup;
        _group setSpeedMode _pSpeed;

        private _leader = leader _group;
        _relPos = _group getVariable "pl_rel_pos";
        if (vehicle _leader != _leader) then {
            (vehicle _leader) limitSpeed 18;
            if ((speed (vehicle _leader)) < 1) then {
                _newPos = [((getPos _leader) select 0) + ((_posOffset select 0) * 15), ((getPos _leader) select 1) + ((_posOffset select 1) * 15)];
                driver (vehicle _leader) doMove _newPos;
            };
            if ((speed (leader _leadGroup)) < 1) then {
                _newPos = [((getPos (leader _leadGroup)) select 0) + (_relPos select 0), ((getPos (leader _leadGroup)) select 1) + (_relPos select 1)];
                driver (vehicle _leader) doMove _newPos;
            };
        }
        else
        {
            _newPos = [((getPos (leader _leadGroup)) select 0) + (_relPos select 0), ((getPos (leader _leadGroup)) select 1) + (_relPos select 1)];
            _leader limitSpeed 15;
            _leader doMove _newPos;
            {
                if (_x != _leader) then {
                    _x doFollow _leader;
                };
            } forEach (units _group);
        };
    };
    pl_follow_array_other = pl_follow_array_other - [[_leadGroup, _group]];
    _group setVariable ["pl_following_formation", false];
    [_group] call pl_reset;
    sleep 0.2;
    if !(_leadGroup getVariable ["onTask", true]) then {
        _leadGroup setVariable ["pl_formation_leader", false];
    };
};

pl_march = {
    params ["_group"];
    private ["_cords", "_f"], "_mwp";

    if (visibleMap) then {
        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
    }
    else
    {
        _cords = screenToWorld [0.5,0.5];
    };


    if (isNil {_group getVariable "pl_on_march"}) then {
        [_group] call pl_reset;
        sleep 0.2;

        playSound "beep";

        _group setVariable ["onTask", true];
        _group setVariable ["setSpecial", true];
        _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa"];
        _group setVariable ["pl_on_march", true];

        {
            _x disableAI "AUTOCOMBAT";
        } forEach (units _group);
        (leader _group) limitSpeed 14;
        _f = formation _group;
        _group setFormation "STAG COLUMN";
        _group setBehaviour "AWARE";
        if ((vehicle (leader _group)) != (leader _group)) then {
            _group setBehaviour "SAFE";
            // if (((count (hcSelected player)) > 1) and (_group isEqualTo ((hcSelected player) select 0))) then {
            //     [true] call pl_spawn_getOut_vehicle;
            // };
        };

        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];

        sleep 3;
        waitUntil {!(_group getVariable ["onTask", true]) or (((leader _group) distance2D (waypointPosition (_group getVariable ["pl_mwp", (currentWaypoint _group)]))) < 11)};
        _group setFormation _f;
        _group setVariable ["pl_on_march", nil];

        if (_group getVariable ["onTask", true] and !(_group getVariable ["pl_task_planed", false])) then {[_group] call pl_reset;};
        
    }
    else
    {
        _mwp = _group addWaypoint [_cords, 0];
        _group setVariable ["pl_mwp", _mwp];
    };
};
// {[_x] spawn pl_march}forEach (hcSelected player)

pl_recon_active = false;
pl_recon_group = grpNull;

// designate group as Recon
pl_recon = {
    private ["_group", "_markerName", "_intelInterval", "_intelMarkers", "_wp", "_leader", "_distance", "_pos", "_dir", "_markerNameArrow", "_markerNameGroup", "_posOccupied"];

    _group = (hcSelected player) select 0;

    // turn off recon mode
    if (pl_recon_active and _group == pl_recon_group) exitWith {pl_recon_active = false; pl_recon_group = grpNull};

    // check if another group is in Recon
    if (pl_recon_active) exitWith {hint "Only one GROUP can be designated as Recon"};

    pl_recon_active = true;
    pl_recon_group = _group;


    // [_group] call pl_reset;
    // sleep 0.2;

    playSound "beep";

    // sealth, holdfire, recon icon
    _group setBehaviour "STEALTH";
    _group setVariable ["MARTA_customIcon", ["b_recon"]];
    _group setVariable ["pl_recon_area_size", 1400];

    // _group setCombatMode "GREEN";
    // _group setVariable ["pl_hold_fire", true];
    // _group setVariable ["pl_combat_mode", true];

    // chosse intervall
    _intelInterval = 30;
    // if  infantry slower recon Interval
    if (leader _group == vehicle (leader _group)) then {
        _intelInterval = 60;
    }
    // if Vehicle faster recon interval
    else
    {
        _intelInterval = 30;
    };

    // stop leader to get full recon size
    sleep 0.5;
    doStop (leader _group);
    
    // create Recon are Marker
    _markerName = createMarker ["reconArea", getPos (leader _group)];
    _markerName setMarkerColor "colorBlue";
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha 0.3;
    _markerName setMarkerSize [1400, 1400];

    sleep 1;

    _intelMarkers = [];

    // check if group is moving --> change area size + force stealth
    [_group, _markerName] spawn {
    params ["_group", "_markerName"];

        while {pl_recon_active} do {
            _group setBehaviour "STEALTH";
            _markerName setMarkerPos (getPos (leader _group));
            if (((currentWaypoint _group) < count (waypoints _group))) then {
                _group setVariable ["pl_recon_area_size", 800];
                _markerName setMarkerSize [800, 800];
            }
            else
            {
                _group setVariable ["pl_recon_area_size", 1400];
                _markerName setMarkerSize [1400, 1400];
            };
            sleep 1;
        };
        _group setBehaviour "AWARE";
        _group setVariable ["pl_recon_area_size", nil];
    };

    // short delay
    sleep 5;

    // recon logic
    while {pl_recon_active} do {
        
        {
            // check if group has active WP and within reconarea
            if (((leader _x) distance2D (leader _group) < (_group getVariable ["pl_recon_area_size", 1400])) and alive (leader _x)) then {

                _markerNameArrow = format ["intelMarkerArrow%1", _x];
                _markerNameGroup = format ["intelMarkerGroup%1", _x];

                if ((currentWaypoint _x) < count (waypoints _x)) then {
                    _wp = waypointPosition ((waypoints _x) select (currentWaypoint _x));
                    _leader = leader _x;
                    _distance = _wp distance2D _leader;

                    // if distance to wp > 100 create Markers
                    if (_distance > 100) then {

                        _dir = _leader getDir _wp;
                        _pos = [(_distance * 0.1)*(sin _dir), (_distance * 0.1)*(cos _dir), 0] vectorAdd (getPos _leader);

                        // check if marker already exists at pos --> avoid clutter
                        _posOccupied = false;
                        if ((count _intelMarkers) == 0) then {
                            _posOccupied = false;
                        }
                        else
                        {
                            _posOccupied = {
                                if ((_pos distance2D (markerPos (_x#0))) < 100) exitWith {true};
                                false
                            } forEach _intelMarkers;
                        };

                        // 80 % chance to create Marker
                        if (!_posOccupied and (random 1) > 0.2) then {
                            createMarker [_markerNameArrow, _pos];
                            _markerNameArrow setMarkerDir _dir;
                            _markerNameArrow setMarkerType "mil_arrow2";
                            _markerNameArrow setMarkerSize [0.3, 0.3];
                            _markerNameArrow setMarkerAlpha 0.7;
                            _markerNameArrow setMarkerColor "COLOROPFOR";

                            createMarker [_markerNameGroup, getPos _leader];
                            _markerType = "o_unknown";
                            _markerSize = 0.4;
                            if (vehicle (leader _x) != leader _x) then {
                                _markerType = "o_recon";
                                _markerSize = 0.5;
                            };

                            _markerNameGroup setMarkerType _markerType;
                            _markerNameGroup setMarkerSize [_markerSize, _markerSize];
                            _markerNameGroup setMarkerAlpha 0.7;

                            _intelMarkers pushBack [_markerNameArrow , _markerNameGroup];
                        };
                    };
                }
                else
                {
                    // 45 % chance to discover static groups
                    if ((random 1) > 0.55) then {
                        createMarker [_markerNameGroup, getPos (leader _x)];
                        _markerType = "o_unknown";
                        _markerSize = 0.4;
                        if (vehicle (leader _x) != leader _x) then {
                            _markerType = "o_recon";
                            _markerSize = 0.5;
                        };
                        _markerNameGroup setMarkerType _markerType;
                        _markerNameGroup setMarkerSize [_markerSize, _markerSize];
                        _markerNameGroup setMarkerAlpha 0.7;

                        _intelMarkers pushBack ["" , _markerNameGroup];
                    };
                };
            };

            // if enemy closer then 300 m --> reveal enemy
            if ((leader _x) distance2D (leader _group) < 300) then {
                _group reveal [leader _x, 3.5];
            };

        } forEach (allGroups select {side _x != playerSide});

        // intervall
        _time = time + _intelInterval;
        waitUntil {time >= _time or !pl_recon_active};
        // cancel recon if leader dead
        if !(alive (leader pl_recon_group)) exitWith {pl_recon_active = false; pl_recon_group = grpNull};

        // delete all markers after Intervall
        {
            deleteMarker (_x#0);
            deleteMarker (_x#1);
        } forEach _intelMarkers;
        _intelMarkers = [];
    };

    // rest variables
    pl_recon_active = false;
    deleteMarker _markerName;
    _group setVariable ["MARTA_customIcon", nil];

    // _group setCombatMode "YELLOW";
    // _group setVariable ["pl_hold_fire", false];
    // _group setVariable ["pl_combat_mode", false];
};





["Platoon Leader","Select HC Group", "Selects the HCGroup of the Unit the player aims at", {_this spawn pl_select_group}, "", [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadIn_key", "Remote View Leader of HC Group", {_this spawn pl_spawn_cam }, "", [DIK_HOME, [false, false, false]]] call CBA_fnc_addKeybind;
["Platoon Leader","hcSquadOut_key", "Release Remote View", {_this spawn pl_remote_camera_out}, "", [DIK_END, [false, false, false]]] call CBA_fnc_addKeybind;