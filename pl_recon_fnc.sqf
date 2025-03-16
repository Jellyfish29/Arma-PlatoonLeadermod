pl_recon_active = false;
pl_recon_group = grpNull;
pl_recon_area_size_default = 1000;
pl_active_recon_groups = [];
pl_recon_los_polys = [];
pl_enable_vanilla_marta = false;

pl_recon_count = 0;

// designate group as Recon

pl_recon = {
    params [["_group", (hcSelected player) select 0],["_preSet", false]];
    private ["_group", "_markerName", "_intelInterval", "_intelMarkers", "_wp", "_leader", "_distance", "_pos", "_dir", "_markerNameArrow", "_markerNameGroup", "_posOccupied"];

    if (_group == (group player)) exitWith {hint "Player group can´t be designated as Recon Group!";};

    if (pl_recon_count >= 2) exitWith {hint "Only THREE Groups can be designated as Recon";};

    _group setVariable ["pl_is_recon", true];
    if !(_preSet) then {pl_recon_count = pl_recon_count + 1; if (pl_enable_beep_sound) then {playSound "beep"}};

    private _size = "s";
    if ((count (units _group)) < 6) then {_size = "t"};

    if (vehicle (leader _group) != leader _group) then {
        if !((leader _group) == commander (vehicle (leader _group)) or (leader _group) == driver (vehicle (leader _group)) or (leader _group) == gunner (vehicle (leader _group))) then {
            [_group, format ["f_%1_recon_pl", _size]] call pl_change_group_icon;
            [_group] call pl_hide_group_icon;
        };
    } else {
        [_group, format ["f_%1_recon_pl", _size]] call pl_change_group_icon;
    }; 
    _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];

    _intelInterval = 30;

    sleep 0.5;

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
    // [_group] spawn {
        // params ["_group"];

        private _airBonus = 0;

        if (vehicle (leader _group) isKindOf "AIR") then {_airBonus = 500};

        while {_group getVariable ["pl_is_recon", false]} do {
            _bonus = 0 + _airBonus;
            _markerName setMarkerPos (getPos (leader _group));
            if !(((currentWaypoint _group) < count (waypoints _group))) then {
                _bonus = 400;
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
            } else {
                _group setVariable ["pl_recon_area_size", pl_recon_area_size_default];
            };
            _h = _group getVariable "pl_recon_area_size";
            _markerName setMarkerSize [_h, _h];
            // if (({alive _x} count (units _group)) <= 0) exitWith {};
            if (isNull _group) exitWith {};
                
            sleep 1;
        };
        _group setVariable ["pl_recon_area_size", nil];
    };

    _reconGrpLeader = leader _group;

    // short delay
    sleep 5;

    private _polyLineMarker = "";

    // recon logic
    while {sleep 0.5; _group getVariable ["pl_is_recon", false]} do {
        
        // _reconLOSPolygon = [ASLToATL ([_group] call pl_find_centroid_of_group), _group getVariable ["pl_recon_area_size", 1400], 1, 8, leader _group] call pl_get_vistool_pos;

        // pl_recon_los_polys pushBack (_reconLOSPolygon#0);

         // _lineMarker = createMarker [str (random 3), [0,0,0]];
         // _lineMarker setMarkerShape "POLYLINE";
         // _lineMarker setMarkerPolyline (_reconLOSPolygon#1);
         // _lineMarker setMarkerColor pl_side_color;


        {
            _opfGrp = _x;
            _leader = leader _opfGrp;

            // if ([getPosASL (leader _opfGrp), (_reconLOSPolygon#0)] call pl_isPointInPolygon) then {
            if ((getPos (leader _opfGrp)) inArea _markerName) then {
                private _reveal = false;
                if ((_reconGrpLeader knowsAbout _leader) > 0.105) then {_reveal = true};
                [_opfGrp, _reveal, false, _group] call Pl_marta;
            };
        } forEach (allGroups select {([(side _x), playerside] call BIS_fnc_sideIsEnemy) and alive (leader _x)});

        _time = time + _intelInterval;
        waitUntil {sleep 1; time >= _time or !(_group getVariable ["pl_is_recon", false])};

        // deleteMarker _lineMarker;
        // pl_recon_los_polys = pl_recon_los_polys - [(_reconLOSPolygon#0)];

        if !(alive (leader _group)) exitWith {_group setVariable ["pl_is_recon", false]; pl_recon_count = pl_recon_count - 1};

    };

    pl_recon_count = pl_recon_count - 1;
    deleteMarker _markerName;
    pl_active_recon_groups = pl_active_recon_groups - [_group];
    _group setVariable ["MARTA_customIcon", nil];
};

pl_mark_targets_on_map = {
    params ["_targets", ["_group", grpNull]];
    // _time = time + 20;

    if (pl_enable_vanilla_marta) exitwith {};

    private _targetGroups = [];

    {
        _targetGroups pushBackUnique (group _x);
    } forEach _targets;

    {
        [_x, true, false, _group] call Pl_marta;
    } forEach _targetGroups;

};

pl_marta_dic = createHashMap;

Pl_marta = {
    params ["_opfGrp", ["_reveal", false], ["_destroyed", false], ["_revealerGroup", grpNull]];
    private ["_unitText", "_centoid"];

    if ((_opfGrp getVariable ["pl_not_recon_able", false]) and !_reveal) exitWith {};

    _leader = leader _opfGrp;
    if (vehicle _leader != _leader and ((assignedVehicleRole _leader)#0) == "cargo") exitWith {};

    private _callsign = groupId _opfGrp;
    private _markerNameArrow = format ["intelMarkerArrow%1", _opfGrp];
    private _markerNameGroup = format ["intelMarkerGroup%1", _opfGrp];
    private _markerNameStrength = format ["intelMarkerStrength%1", _opfGrp];
    private _markerNameOpfTactic = format ["interMarkerOpfTactic%1", _opfGrp];

    private _sideColor = "colorOpfor";
    private _sideColorRGB = [0.5,0,0,0.5];
    private _side = side _leader;
    private _sidePrefix = "o";

    switch (_opfGrp getVariable ["pl_opf_side", side _opfGrp]) do { 
        case west : {_sideColor = "colorBlufor"; _sideColorRGB = [0,0.3,0.6,0.5]; _sidePrefix = "b"}; 
        case east : {_sideColor = "colorOpfor"; _sideColorRGB = [0.5,0,0,0.5]; _sidePrefix = "o"};
        case resistance : {_sideColor = "colorIndependent"; _sideColorRGB = [0,0.5,0,0.5]; _sidePrefix = "n"};
        default {_sideColor = "exit"; _sideColorRGB = [0.5,0,0,0.5];}; 
    };

    if (_sideColor == "exit") exitWith {};

    _centoid = [_opfGrp] call pl_find_centroid_of_group;
    private _chance = 0.05;
    if ([_centoid] call pl_is_city) then {_chance = 0.01};
    if ([_centoid] call pl_is_forest) then {_chance = 0.03};

    if (((random 1) < (_chance + (_chance * 0.5)) and (currentWaypoint _opfGrp) < count (waypoints _opfGrp)) or ((random 1) < _chance and (currentWaypoint _opfGrp) >= count (waypoints _opfGrp)) or _reveal) then {

        _unitText = getText (configFile >> "CfgVehicles" >> typeOf (vehicle (leader _opfGrp)) >> "textSingular");
        private _exit = false;

        private _status = "f";
        if !(_reveal) then {
            _status = "s";
        };
        // private _markerTypeType = format ["unknown_%1_pl", _status];
        private _markerTypeType = "mil_dot";
        private _markerSize = 1;

        if !(isNull objectParent (leader _opfGrp)) then {
            private _vic = vehicle (leader _opfGrp);

            if !((leader _opfGrp) == commander (vehicle (leader _opfGrp)) or (leader _opfGrp) == driver (vehicle (leader _opfGrp)) or (leader _opfGrp) == gunner (vehicle (leader _opfGrp))) exitwith {_exit = true;};
            if (_vic isKindOf "Air") then {
                if !(_vic getVariable ["pl_marta_air_spotted", false]) then {
                    switch (_unitText) do { 
                        case "fast mover" : {_markerTypeType = format ["%1_f_air_fixed_pl", _sidePrefix]}; 
                        case "gunship" : {_markerTypeType = format ["%1_f_air_rotary_atk_pl", _sidePrefix]};
                        case "helicopter" : {_markerTypeType = format ["%1_f_air_rotary_pl", _sidePrefix]};
                        case "UAV" : {_markerTypeType = format ["%1_f_air_uav_pl", _sidePrefix]}; 
                        default {_markerTypeType = format ["%1_f_air_rotary_pl", _sidePrefix]}; 
                    };

                    _vic setVariable ["pl_marta_air_spotted", true];

                    [_vic, _markerTypeType, _sideColor] spawn {
                        params ["_vic", "_markerTypeType", "_sideColor"];
                            _markerNameVic = createMarker [str (random 4), getPos _vic];
                            _markerNameVic setMarkerType _markerTypeType;
                            _markerNameVic setMarkerSize [1.1, 1.1];
                            _markerNameVic setMarkerColor _sideColor;

                            while {alive _vic and !(isNull _vic)} do {
                                sleep 1;
                                _markerNameVic setMarkerPos (getPos _vic);
                            };

                            deleteMarker _markerNameVic

                    };
                };

                _exit = true;
            };
            
            switch (_unitText) do {
                case "truck" : {
                    _markerTypeType = format ["%1_%2_truck_pl", _sidePrefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]}}};
                };
                case "car" : {
                    _markerTypeType = format ["%1_%2_truck_pl", _sidePrefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", _sidePrefix, _status]}}};
                }; 
                case "tank" : {
                    _markerTypeType = format ["%1_%2_tank_pl", _sidePrefix, _status];
                    if (((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) >= 2 or getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair") > 0) and !([_vic] call pl_is_tank)) then {
                        if ([_vic] call pl_is_ifv) then {
                            _markerTypeType = format ["%1_%2_ifvtr_pl", _sidePrefix, _status];
                        } else {
                            _markerTypeType = format ["%1_%2_apctr_pl", _sidePrefix, _status];
                        };
                    };
                };
                case "APC" : {
                    if ([_vic] call pl_is_ifv) then {
                        _markerTypeType = format ["%1_%2_ifvtr_pl", _sidePrefix, _status];
                        if (_vic isKindOf "Car") then {_markerTypeType = format ["%1_%2_ifvwe_pl", _sidePrefix, _status]};
                    } else {
                        _markerTypeType = format ["%1_%2_apctr_pl", _sidePrefix, _status];
                        if (_vic isKindOf "Car") then {_markerTypeType = format ["%1_%2_apcwe_pl", _sidePrefix, _status]};
                    };
                };
                case "IFV" : {
                    _symbolType = format ["%1_%2_ifvtr_pl", pl_side_prefix, _status];
                    if (_vic isKindOf "Car") then {_symbolType = format ["%1_%2_ifvwe_pl", pl_side_prefix, _status]};
                };
                default {_markerTypeType = format ["%1_%2_unknown_eq_pl", _sidePrefix, _status]};
            };

            // if (isVehicleRadarOn _vic) then {
            //     _symbolType = format ["%1_%2_tankaa_pl", pl_side_prefix, _status];
            // };
            // if ((getNumber (configFile >> "CfgVehicles" >> typeOf _vic >> "artilleryScanner")) == 1 and !_force) then {
            //     _symbolType = format ["%1_%2_artgun_pl", pl_side_prefix, _status];
            // };
                
            // if ((getNumber (configFile >> "CfgVehicles" >> typeOf _vic >> "artilleryScanner")) == 1) then {_markerTypeType = format ["%1_art", _sidePrefix]};


        } else {
            if (count (units _opfGrp) <= 6) then {
                // inf Team
                _markerTypeType = format ["%1_%2_t_inf_pl", _sidePrefix, _status];
            } else {
                // Inf Squad
                _markerTypeType = format ["%1_%2_s_inf_pl", _sidePrefix, _status];
            };
        };

        if (_exit) exitwith {};

        private _opfDir = -1;
        if ((currentWaypoint _opfGrp) < count (waypoints _opfGrp) and (waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp)) distance2D _leader) > 50 and !_destroyed) then {
            _wp = waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp));
            _opfDir = _leader getDir _wp;
            _pos = _centoid getPos [45, _opfDir];
            pl_opfor_wp_dic set [groupId _opfGrp, [_centoid, _pos, _sideColorRGB, _opfGrp]];
        } else {
            if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};
        };

        if !(_callsign in pl_marta_dic) then {
            createMarker [_markerNameGroup, _centoid];
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
            [_opfGrp, _unitText, _opfDir, _revealerGroup] spawn pl_marta_spotrep;

            _markerNameGroup setMarkerSize [_markerSize, _markerSize];
            _markerNameGroup setMarkerColor _sideColor;
            // first time call out
        } else {
            _markerNameGroup setMarkerPos _centoid;
            
        };

        _opfGrp setVariable ["pl_spot_time", time];
        _markerNameGroup setMarkerType _markerTypeType;
        
        if (_reveal) then {
            _markerNameGroup setMarkerAlpha 0.9;
        } else {
            _markerNameGroup setMarkerAlpha 0.7;
        };

        // if !(_leader checkAIFeature "PATH") then {
        //     _setTacMarker = true;
        //     _opfGrp setVariable ["pl_opf_tac_marker", "position"];
        // };

        if (_opfGrp getVariable ["pl_opf_in_pos", false] and !_destroyed) then {

            if !(_markerNameOpfTactic in ((pl_marta_dic get _callsign)#1)) then {


                private _targets = ((getPos _leader) nearEntities [["Man"], 1000]) select {side _x == playerSide};

                if !(_targets isEqualto []) then {

                    _target = ([_targets, [], {_leader distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    private _targetPos = getPos _target;
                    private _targetDir = _leader getDir _targetPos;
                    private _tacMarkerPos = _centoid getPos [6, _targetDir];
                     createMarker [_markerNameOpfTactic, _tacMarkerPos];
                    _markerNameOpfTactic setMarkerType "marker_position_eny";
                    _markerNameOpfTactic setMarkerColor _sideColor;
                    _markerNameOpfTactic setMarkerDir _targetDir;
                    _markerNameOpfTactic setMarkerSize [0.85, 0.85];

                    pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]]];
                };
            } else {
                _markerNameOpfTactic setMarkerPos _centoid;
            };     
        } else {
            deleteMarker _markerNameOpfTactic;
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
        };

        // _opfGrp setVariable ["pl_active_recon_markers", [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]];

        if (_destroyed) then {

            _markerNameDestroyed = createMarker [str (random 4), getMarkerPos _markerNameGroup];
            _markerNameDestroyed setMarkerSize [0.8, 0.8];
            _markerNameDestroyed setMarkerType "mil_destroy";
            _markerNameDestroyed setMarkerColor _sideColor;
            _markerNameDestroyed setMarkerShadow false;
            _markerNameDestroyed setMarkerDir 45;

            _markerNameGroup setMarkerAlpha 0.5;

            [_markerNameDestroyed, _markerNameGroup, _opfGrp] spawn {
                params ["_markerNameDestroyed", "_markerNameGroup", "_grp"];
                _callsign = groupId _grp;

                pl_marta_dic deleteat (_callsign);
                if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};

                sleep 600;

                _markerNameGroup setMarkerAlpha 0.6;
                _markerNameGroup setMarkerColor "colorGrey";
                _markerNameGroup setMarkerSize [0.7, 0.7];


                // deleteMarker _markerName;
                _markerNameDestroyed setMarkerColor "colorGrey";
                _markerNameDestroyed setMarkerAlpha 0.45;
                _markerNameDestroyed setMarkerSize [0.6, 0.6];
                // deleteGroup _grp;
                // _grp setVariable ["pl_marta_no_delete", nil];


            };
        };
    };
};


pl_marta_spotrep = {
    params ["_grp", "_unitText", "_opfDir", "_group"];

    if !(isNull _group) then {
        // _group = selectRandom pl_active_recon_groups;
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
    params ["_grp", ["_report", false]];
    _callsign = groupId _grp;

    if (_callsign in pl_marta_dic) then {
        _markers = (pl_marta_dic get _callsign)#1;
        if (_report) then {
            [_grp, _markers, _callsign] spawn {
                params ["_grp", "_markers", "_callsign"];
                private _sideColor = "colorOpfor";
                switch (_grp getVariable ["pl_opf_side", side _grp]) do { 
                    case west : {_sideColor = "colorBlufor"}; 
                    case east : {_sideColor = "colorOpfor"};
                    case resistance : {_sideColor = "colorIndependent"};
                    default {_sideColor = "colorOpfor";}; 
                };

                _markerName = createMarker [format ["%1_%2", random 4, _callsign], getMarkerPos (_markers#0)];
                _markerName setMarkerSize [0.8, 0.8];
                _markerName setMarkerType "mil_destroy";
                _markerName setMarkerColor _sideColor;
                _markerName setMarkerShadow false;
                _markerName setMarkerDir 45;
                {
                    _x setMarkerAlpha 0.5;
                } forEach _markers;

                pl_marta_dic deleteat (_callsign);
                if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};

                sleep 600;

                {
                    _x setMarkerAlpha 0.6;
                    _x setMarkerColor "colorGrey";
                    _x setMarkerSize [0.7, 0.7];
                } forEach _markers;
                // deleteMarker _markerName;
                _markerName setMarkerColor "colorGrey";
                _markerName setMarkerAlpha 0.45;
                _markerName setMarkerSize [0.6, 0.6];
                // deleteGroup _grp;
                // _grp setVariable ["pl_marta_no_delete", nil];

            };
        } else {
            {
                deleteMarker _x;
            } forEach _markers;
            pl_marta_dic deleteat (_callsign);
            if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};
        };
    } else {
        if (_report) then {
            [_grp, true, true] call Pl_marta;
        };
    };
    // if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat (_callsign)};
};

pl_marta_cleanup_loop = {
    
    while {true} do {
        
        [] call pl_marta_cleanup_loop_function;
        sleep 15;
    };
};

pl_marta_cleanup_loop_function = {
    {
        _key = _x;
        _grp = _y#0;
        _markers = _y#1;
        // if ((({alive _x} count (units _grp) < 1 and !(_grp getvariable ["pl_marta_clean", false])) or (isNull _grp))) then {
        if (((({alive _x} count (units _grp) < 1) or !(alive (vehicle (leader _grp))) or (isNull _grp)) or (side (leader _grp)) == civilian or (_grp getvariable ["pl_has_surrendered", false])) and !(_grp getVariable ["pl_marta_no_delete", false])) then {
            {
                deleteMarker _x;
            } forEach _markers;
            pl_marta_dic deleteat _key;
            if ((groupId _grp) in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat (groupId _grp)};
        };

        // turn back to supected if not spetted for 120 sec
        if ((_grp getvariable ["pl_spot_time", 0]) < (time - 80)) then {
            _type = markertype (_markers#0);
            _newType = [_type, "_f_", "_s_"] call pl_stringReplace;
            (_markers#0) setMarkerType _newType;
            (_markers#0) setMarkerAlpha 0.7;
        };

    } forEach pl_marta_dic;
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

