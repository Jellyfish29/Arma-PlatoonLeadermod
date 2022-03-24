pl_recon_active = false;
pl_recon_group = grpNull;
pl_recon_area_size_default = 800;
pl_active_recon_groups = [];
pl_enable_vanilla_marta = false;

pl_recon_count = 0;

// designate group as Recon
pl_recon = {
    params [["_group", (hcSelected player) select 0],["_preSet", false]];
    private ["_group", "_markerName", "_intelInterval", "_intelMarkers", "_wp", "_leader", "_distance", "_pos", "_dir", "_markerNameArrow", "_markerNameGroup", "_posOccupied"];

    if (_group == (group player)) exitWith {hint "Player group can´t be designated as Recon Group!";};

    // turn off recon mode
    // if (pl_recon_active and _group == pl_recon_group) exitWith {pl_recon_active = false; pl_recon_group = grpNull};
    // if (_group getVariable ["pl_is_recon", false]) exitWith {_group setVariable ["pl_is_recon", false]};

    // check if another group is in Recon
    // if (pl_recon_active) exitWith {hint "Only one GROUP can be designated as Recon";};
    if (pl_recon_count >= 2) exitWith {hint "Only THREE Groups can be designated as Recon";};

    // pl_recon_active = true;
    // pl_recon_group = _group;

    _group setVariable ["pl_is_recon", true];
    if !(_preSet) then {pl_recon_count = pl_recon_count + 1; if (pl_enable_beep_sound) then {playSound "beep"}};

    // [_group] call pl_reset;
    // sleep 0.2;

    // sealth, holdfire, recon icon
    // _group setBehaviour "STEALTH";
    // if (vehicle (leader _group) != (leader _group)) then {
    //     [_group, "recon_add_pl"] call pl_change_group_icon;
    // } else {
    //     [_group, "recon"] call pl_change_group_icon;
    // };
    _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];

    // _group setCombatMode "GREEN";
    // _group setVariable ["pl_hold_fire", true];
    // _group setVariable ["pl_combat_mode", true];

    // chosse intervall
    _intelInterval = 45;

    // stop leader to get full recon size
    sleep 0.5;
    // doStop (leader _group);
    
    // create Recon area Marker
    _markerName = createMarker [format ["reconArea%1", _group], getPos (leader _group)];
    _markerName setMarkerColor "colorBlue";
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    _markerName setMarkerAlpha 0.3;
    _markerName setMarkerSize [pl_recon_area_size_default, pl_recon_area_size_default];
    pl_active_recon_groups pushBack _group;

    sleep 1;

    _intelMarkers = [];

    // check if group is moving --> change area size + force stealth
    [_group, _markerName] spawn {
    params ["_group", "_markerName"];

        while {_group getVariable ["pl_is_recon", false]} do {
            _bonus = 0;
            _markerName setMarkerPos (getPos (leader _group));
            if !(((currentWaypoint _group) < count (waypoints _group))) then {
                _bonus = 200;
                // Get height of Group and compare to average sorrounding Height to get Bounus Vision Range
                _height = getTerrainHeightASL (getPos (leader _group));
                _interval = 12;
                _diff = 360 / _interval;
                _avHeight = 0;
                // check _interval test location 350m around group and calc average terrain height
                for "_i" from 0 to _interval do {
                    _degree = 1 + _i * _diff;
                    _checkPos = [350 * (sin _degree), 350 * (cos _degree), 0] vectorAdd (getPos leader _group);
                    _checkheight = getTerrainHeightASL _checkPos;
                    _avHeight = _avHeight + _checkheight;
                };
                _reconHeight = _height - (_avHeight / _interval);
                // hintSilent str _reconHeight;
                // if negativ Height no Bonus Range
                if (_reconHeight <= 0) then {_reconHeight = 0};

                // Set Bonus Range
                _group setVariable ["pl_recon_area_size", pl_recon_area_size_default + (_reconHeight * 20) + _bonus];
            }
            else
            {
                _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];
            };
            _h = _group getVariable "pl_recon_area_size";
            _markerName setMarkerSize [_h, _h];
            // if (([_group getVariable ["pl_custom_icon", ""], "add"] call BIS_fnc_inString) and isNull objectParent (leader _group)) then {
            //     [_group, "recon"] call pl_change_group_icon;
            // };
            // if (([_group getVariable ["pl_custom_icon", ""], "recon"] call BIS_fnc_inString) and !(isNull objectParent (leader _group))) then {
            //     [_group, "recon_add_pl"] call pl_change_group_icon;
            // };
            sleep 1;
        };
        _group setVariable ["pl_recon_area_size", nil];
    };

    _reconGrpLeader = leader _group;

    // short delay
    sleep 5;

    // recon logic
    while {sleep 0.5; _group getVariable ["pl_is_recon", false]} do {
        
        {
            _opfGrp = _x;
            _leader = leader _opfGrp;

            if (_leader distance2D _reconGrpLeader < (_group getVariable ["pl_recon_area_size", 1400])) then {
                private _reveal = false;
                if ((_reconGrpLeader knowsAbout _leader) > 0.105) then {_reveal = true};
                [_opfGrp, _reveal] call Pl_marta;
            };
            // else
            // {
            //     if ((_opfGrp getVariable ["pl_active_recon_markers", []]) isNotEqualTo []) then {
            //         {
            //             _x setMarkerAlpha 0.6;
            //             _x setMarkerColor "colorGrey";
            //         } forEach (_opfGrp getVariable "pl_active_recon_markers");
            //     };
            // };
        } forEach (allGroups select {([(side _x), playerside] call BIS_fnc_sideIsEnemy) and alive (leader _x)});

        // intervall
        _time = time + _intelInterval;
        waitUntil {sleep 1; time >= _time or !(_group getVariable ["pl_is_recon", false])};
        // cancel recon if leader dead
        // delete all markers of dead groups


        if !(alive (leader _group)) exitWith {_group setVariable ["pl_is_recon", false]; pl_recon_count = pl_recon_count - 1;};

    };

    // rest variables
    // pl_recon_active = false;
    deleteMarker _markerName;
    pl_active_recon_groups = pl_active_recon_groups - [_group];
    _group setVariable ["MARTA_customIcon", nil];

    // _group setCombatMode "YELLOW";
    // _group setVariable ["pl_hold_fire", false];
    // _group setVariable ["pl_combat_mode", false];
};


pl_mark_targets_on_map = {
    params ["_targets"];
    // _time = time + 20;

    if (pl_enable_vanilla_marta) exitwith {};

    private _targetGroups = [];

    {
        _targetGroups pushBackUnique (group _x);
    } forEach _targets;

    {
        [_x, true] call Pl_marta;
    } forEach _targetGroups;

};

pl_marta_dic = createHashMap;

Pl_marta = {
    params ["_opfGrp", ["_reveal", false]];
    private ["_unitText"];

    if (_opfGrp getVariable ["pl_not_recon_able", false]) exitWith {};

    _leader = leader _opfGrp;
    if (vehicle _leader != _leader and ((assignedVehicleRole _leader)#0) == "cargo") exitWith {};

    _callsign = groupId _opfGrp;
    private _markerNameArrow = format ["intelMarkerArrow%1", _opfGrp];
    private _markerNameGroup = format ["intelMarkerGroup%1", _opfGrp];
    private _markerNameStrength = format ["intelMarkerStrength%1", _opfGrp];
    private _markerNameOpfTactic = format ["interMarkerOpfTactic%1", _opfGrp];

    private _setTacMarker = false;
    private _tacMarkerType = "";
    switch (_opfGrp getVariable ["pl_opf_tac_marker", ""]) do { 
        case "" : {_setTacMarker = false; _tacMarkerType = ""}; 
        case "position" : {_setTacMarker = true; _tacMarkerType = "marker_position_eny"};
        case "attack" : {_setTacMarker = true; _tacMarkerType = "marker_std_atk"};
        default {_setTacMarker = false; _tacMarkerType = ""}; 
    };

    private _sideColor = "colorOpfor";
    private _sideColorRGB = [0.5,0,0,0.5];
    private _side = side _leader;
    switch (_opfGrp getVariable ["pl_opf_side", _side]) do { 
        case west : {_sideColor = "colorBlufor"; _sideColorRGB = [0,0.3,0.6,0.5]}; 
        case east : {_sideColor = "colorOpfor"; _sideColorRGB = [0.5,0,0,0.5]};
        case resistance : {_sideColor = "colorIndependent"; _sideColorRGB = [0,0.5,0,0.5]};
        default {_sideColor = "exit"; _sideColorRGB = [0.5,0,0,0.5];}; 
    };

    if (_sideColor == "exit") exitWith {};


    // 50 % chance to create Marker
    if (((random 1) < 0.5 and (currentWaypoint _opfGrp) < count (waypoints _opfGrp)) or ((random 1) < 0.15 and (currentWaypoint _opfGrp) >= count (waypoints _opfGrp)) or _reveal) then {

        _unitText = getText (configFile >> "CfgVehicles" >> typeOf (vehicle (leader _opfGrp)) >> "textSingular");


        private _status = "f";
        if !(_reveal) then {
            _status = "s";
        };
        // private _markerTypeType = format ["unknown_%1_pl", _status];
        private _markerTypeType = "mil_dot";
        private _markerSize = 1;

        if !(isNull objectParent (leader _opfGrp)) then {
            private _vic = vehicle (leader _opfGrp);

            if (_vic isKindOf "Air") then {_markerTypeType = "", _markerSize = 0};

            switch (_unitText) do {
                case "truck" : {
                    _markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_rep_pl", pl_opfor_prefix, _status]}}};
                };
                case "car" : {
                    _markerTypeType = format ["%1_%2_truck_pl", pl_opfor_prefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_rep_pl", pl_opfor_prefix, _status]}}};
            }; 
                case "tank" : {
                    _markerTypeType = format ["%1_%2_tank_pl", pl_opfor_prefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 6) then {_markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status]};
                };
                case "APC" : {
                    _markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status];
                    if (_vic isKindOf "Car") then {_markerTypeType = format ["%1_%2_apcwe_pl", pl_opfor_prefix, _status]};
                };
                default {_markerTypeType = format ["%1_%2_truck_pl", pl_opfor_prefix, _status]};
            };

            if (_unitText == "tank" and !(["apctr", _markerTypeType] call BIS_fnc_inString)) then {
                if ([_vic] call pl_is_apc) then {_markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status];}
            };
            
            if ((getNumber (configFile >> "CfgVehicles" >> typeOf _vic >> "artilleryScanner")) == 1) then {_markerTypeType = format ["%1_art", pl_opfor_prefix]};


        } else {
            if (count (units _opfGrp) <= 6) then {
                // inf Team
                _markerTypeType = format ["%1_%2_t_inf_pl", pl_opfor_prefix, _status];
            } else {
                // Inf Squad
                _markerTypeType = format ["%1_%2_s_inf_pl", pl_opfor_prefix, _status];
            };
        };

        private _opfDir = -1;
        if ((currentWaypoint _opfGrp) < count (waypoints _opfGrp) and (waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp)) distance2D _leader) > 50) then {
            _wp = waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp));
            _opfDir = _leader getDir _wp;
            _pos = (getPos _leader) getPos [45, _opfDir];
            pl_opfor_wp_dic set [groupId _opfGrp, [getPos _leader, _pos, _sideColorRGB, _opfGrp]];
        } else {
            if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};
        };

        if !(_callsign in pl_marta_dic) then {
            createMarker [_markerNameGroup, getPos _leader];
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
            [_opfGrp, _unitText, _opfDir] spawn pl_marta_spotrep;

            _markerNameGroup setMarkerSize [_markerSize, _markerSize];
            // _markerNameGroup setMarkerColor _sideColor;
            // first time call out
        } else {
            _markerNameGroup setMarkerPos (getPos _leader);
        };

        _markerNameGroup setMarkerType _markerTypeType;
        
        if (_reveal) then {
            _markerNameGroup setMarkerAlpha 0.9;
        } else {
            _markerNameGroup setMarkerAlpha 0.8;
        };

        // if !(_leader checkAIFeature "PATH") then {
        //     _setTacMarker = true;
        //     _opfGrp setVariable ["pl_opf_tac_marker", "position"];
        // };

        if (_setTacMarker) then {

            if !(_markerNameOpfTactic in ((pl_marta_dic get _callsign)#1)) then {


                private _targets = ((getPos _leader) nearEntities [["Man"], 1000]) select {side _x == playerSide};

                if !(_targets isEqualto []) then {

                    _target = ([_targets, [], {_leader distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    private _targetPos = getPos _target;
                    private _targetDir = _leader getDir _targetPos;
                    private _tacMarkerPos = (getPos _leader) getPos [6, _targetDir];
                    if ((_opfGrp getVariable ["pl_opf_tac_marker", ""]) == "attack") then {
                        _tacMarkerPos = (getPos _leader) getPos [((getPos _leader) distance2D _targetPos) / 2, _targetDir];
                    };
                     createMarker [_markerNameOpfTactic, _tacMarkerPos];
                    _markerNameOpfTactic setMarkerType _tacMarkerType;
                    _markerNameOpfTactic setMarkerColor _sideColor;
                    _markerNameOpfTactic setMarkerDir _targetDir;
                    _markerNameOpfTactic setMarkerSize [0.7, 0.7];

                    pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]]];
                };
            } else {
                if ((_opfGrp getVariable ["pl_opf_tac_marker", ""]) == "position") then {_markerNameOpfTactic setMarkerPos (getPos _leader)};
            };     
        } else {
            deleteMarker _markerNameOpfTactic;
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
        };

        _opfGrp setVariable ["pl_active_recon_markers", [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]];
    };
};


pl_marta_spotrep = {
    params ["_grp", "_unitText", "_opfDir"];

    if !(pl_active_recon_groups isEqualTo []) then {
        _group = selectRandom pl_active_recon_groups;
        _grid = toupper (mapGridPosition (getPos (leader _grp)));
        _unitText = toUpper _unitText;
        private _message = format ["SPOTREP: Enemy %1 at %2", _unitText, _grid];
        if !(_opfDir == -1) then {
            _message = _message + format [" Direction %1", round _opfDir];
        };

        if (pl_enable_beep_sound) then {playSound "radioinc"};
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then {(leader _group) sideChat _message};
        if (pl_enable_map_radio) then {[_group, _message, 30] call pl_map_radio_callout};
        sleep 0.5;
        if (pl_enable_beep_sound) then {playSound "radioina"};
        if (pl_enable_beep_sound) then {playSound "beep"};
    };
};

pl_marta_cleanup = {
    params ["_grp"];
    _callsign = groupId _grp;

    if (_callsign in pl_marta_dic) then {
        _markers = (pl_marta_dic get _callsign)#1;
        {
            deleteMarker _x;
        } forEach _markers;
        pl_marta_dic deleteat (_callsign);
    };

    if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat (_callsign)};
};

pl_marta_cleanup_loop = {
    
    while {sleep 0.5; true} do {
        {
            _key = _x;
            _grp = _y#0;
            _markers = _y#1;
            if ({alive _x} count (units _grp) < 1) then {
                {
                    deleteMarker _x;
                } forEach _markers;
                pl_marta_dic deleteat _key;
                if ((groupId _grp) in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat (groupId _grp)};
            };
        } forEach pl_marta_dic;

        sleep 5;
    };
};


if !(pl_enable_vanilla_marta) then {
    [] spawn pl_marta_cleanup_loop;
};


// {
//             hint (_x getVariable ["pl_opf_tac_marker", ""]);
//         } forEach (allGroups select {side _x == east});

// pl_opfor_wp_dic = createHashMap;
// pl_opfor_wp_arrow = {
//     findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
//         _display = _this#0;
//             {
//                 if !(isNull (_y#3)) then {
//                     _pos1 = _y#0;
//                     _pos2 = _y#1;
//                     _color = _y#2;
//                     _display drawArrow [
//                         _pos1,
//                         _pos2,
//                         _color
//                     ];
//                 } else {
//                     pl_opfor_wp_dic deleteat _x;  
//                 };
//             } forEach pl_opfor_wp_dic;
//     "]; // "  
// };

// [] call pl_opfor_wp_arrow;

