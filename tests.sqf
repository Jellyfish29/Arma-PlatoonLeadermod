pl_get_on_map_arty = {
    private ["_mortars"];

    pl_arty_groups = [];
    {
        if ((getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "artilleryScanner")) == 1) then {
            _grp = group (gunner _x);

            _grpGuns = _grp getVariable ["pl_active_arty_guns", []];
            _grpGuns pushBackUnique _x;
            _grp setVariable ["pl_active_arty_guns", _grpGuns];

            pl_arty_groups pushBackUnique _grp;
        };
    } forEach (vehicles select {(side _x) isEqualTo playerSide});

    if (count pl_arty_groups == 0) exitWith {0};
    pl_active_arty_group_idx = 0;
    1
};

pl_arty_rounds = 9;
pl_arty_dispersion = 200;
pl_arty_delay = 10;

pl_str_cas = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Air Support</t>';
pl_str_arty = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Long Range Artillery</t>';
pl_str_mortar = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Short Range Artillery</t>';
pl_str_status = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa"/><t> STATUS</t>';

pl_show_fire_support_menu = {
    call compile format ["
     HC_Custom_0 = [
        ['Fire Support',true],
        [parseText '%4', [2], '', -5, [['expression', '[] spawn pl_show_cas_menu']], '1', '%1'],
        [parseText '%5', [3], '', -5, [['expression', '[] spawn pl_show_arty_menu']], '1', '%2'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        [parseText '%6', [4], '', -5, [['expression', '[] spawn pl_show_on_map_arty_menu']], '1', '%3'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        [parseText '%7', [5], '', -5, [['expression', '[] spawn pl_support_status']], '1', '1']
    ];", pl_cas_enabled, pl_arty_enabled, [] call pl_get_on_map_arty, pl_str_cas, pl_str_arty, pl_str_mortar, pl_str_status];
    // showCommandingMenu "#USER:pl_mortar_menu";
};
[] call pl_show_fire_support_menu;


pl_show_on_map_arty_menu = {
call compile format ["
pl_on_map_arty_menu = [
    ['Artillery',true],
    ['Call Artillery Strike', [2], '', -5, [['expression', '[] spawn pl_fire_on_map_arty']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Choose Battery:   %5', [3], '', -5, [['expression', '[] spawn pl_show_battery_menu']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Rounds:               %1', [4], '#USER:pl_arty_round_menu', -5, [['expression', '']], '1', '1'],
    ['Dispersion:       %2 m', [5], '#USER:pl_arty_dispersion_menu', -5, [['expression', '']], '1', '1'],
    ['Min Delay:               %3 s', [6], '#USER:pl_arty_delay_menu', -5, [['expression', '']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0']
];", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, pl_arty_enabled, groupId (pl_arty_groups#pl_active_arty_group_idx)];
showCommandingMenu "#USER:pl_on_map_arty_menu";
};

pl_show_battery_menu = {
    private ["_menuScript"];
    _menuScript = "pl_arty_group_menu = [['Artillery Batteries',true],";

    _n = 0;
    {
        _callsign = groupId _x;
        _menuScript = _menuScript + format ["[parseText '%1', [%2], '', -5, [['expression', 'pl_active_arty_group_idx = %3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],", _callsign, _n + 2, _n];
        _n = _n + 1;
    } forEach pl_arty_groups;
    _menuScript = _menuScript + "['', [], '', -5, [['expression', '']], '0', '0']]";

    call compile _menuScript;
    showCommandingMenu "#USER:pl_arty_group_menu";
};
// pl_arty_group_menu = [
//     ['Artillery Batteries',true],
//     ['%1', [2], '', -5, [['expression', 'pl_active_arty_group = %3']], '1', '1'],
//     ['', [], '', -5, [['expression', '']], '1', '0']
// ];

pl_fire_on_map_arty = {
    private ["_cords", "_ammoType", "_eh", "_markerName", "_centerMarkerName", "_eta", "_battery", "_guns", "_volleys"];

    if (visibleMap) then {

        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _markerName = createMarker [str (random 4), pl_arty_cords];
        _markerName setMarkerColor "colorRed";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "BDiagonal";
        _markerName setMarkerAlpha 0.9;
        _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];
        pl_cancel_strike = false;
        onMapSingleClick {
            pl_arty_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hint "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
    }
    else
    {
        pl_arty_cords = screenToWorld [0.5,0.5];
    };

    _markerName setMarkerAlpha 0.4;
    _centerMarkerName = createMarker [str (random 4), pl_arty_cords];
    _centerMarkerName setMarkerType "mil_destroy";
    _centerMarkerName setMarkerText format ["%1 R / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay];

    _cords = pl_arty_cords;
    _battery = pl_arty_groups#pl_active_arty_group_idx;
    _guns = _battery getVariable ["pl_active_arty_guns", []];
    if (_guns isEqualTo []) exitWith {Hint "No active Guns"};

    _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
    _eta = (_guns#0) getArtilleryETA [_cords, _ammoType];
    if (_eta == -1) exitWith {
        hint "Not in Range";
        deleteMarker _markerName;
        deleteMarker _centerMarkerName;
    };

    _eta = _eta + 5;

    [_eta, _centerMarkerName] spawn {
        params ["_eta", "_centerMarkerName"];
        _time = time +_eta;
        while {time < _time} do {
            _centerMarkerName setMarkerText format ["%1 R / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time)];
            sleep 1;
        };
        _centerMarkerName setMarkerText "";
    };

    if (pl_enable_beep_sound) then {playSound "beep"};
    if (pl_enable_chat_radio) then {(gunner (_guns#0)) sideChat format ["...Fire Mission Confimed ETA: %1s", round _eta]};
    if (pl_enable_map_radio) then {[group (gunner (_guns#0)), format ["...Fire Mission Confimed ETA: %1s", round _eta], 25] call pl_map_radio_callout};

    _volleys = round (pl_arty_rounds / (count _guns));
    _dispersion = pl_arty_dispersion;
    _delay = pl_arty_delay;

    sleep 1;


    for "_i" from 1 to _volleys do {
        {
            _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
            _firePos = [[[_cords, _dispersion + 20]],[]] call BIS_fnc_randomPos;
            _x setVariable ["pl_waiting_for_fired", true];
            _x commandArtilleryFire [_firePos, _ammoType, 1];
            _eh = _x addEventHandler ["Fired", {
                params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
                _unit setVariable ["pl_waiting_for_fired", false];
            }];
            sleep 1;
        } forEach _guns;


        sleep 1;
        _MaxDelay = time + 40;
        _minDelay = time + _delay;
        waitUntil {({_x getVariable ["pl_waiting_for_fired", true]} count _guns == 0 and time >= _minDelay) or time >= _MaxDelay};
        sleep 2;
    };

    sleep 20;
    deleteMarker _markerName;
    deleteMarker _centerMarkerName;

    {
        _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
        _x addMagazineTurret [_ammoType, [-1]];
        _x removeEventHandler ["Fired", _eh];
    } forEach _guns;
};