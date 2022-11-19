pl_arty_mission = "SUP";

pl_fire_on_map_arty = {
    private ["_mpos", "_cords", "_ammoTypes", "_ammoType", "_eh", "_markerName", "_centerMarkerName", "_eta", "_battery", "_guns", "_volleys", "_isHc", "_ammoTypestr", "_ammoType"];

    // if (pl_arty_ammo < pl_arty_rounds) exitWith {
    //     // if (pl_enable_beep_sound) then {playSound "beep"};
    //     hint "Not enough ammunition left!";
    // };

    _markerName = createMarker [str (random 4), [0,0,0]];
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    // _markerName setMarkerAlpha 1;
    _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];

    switch (pl_arty_round_type) do { 
        case 1 : {_ammoTypestr = "HE"}; 
        case 2 : {_ammoTypestr = "SMK"}; 
        case 3 : {_ammoTypestr = "IL"};
        case 4 : {_ammoTypestr = "GUI"};
        case 5 : {_ammoTypestr = "MINE"};
        case 6 : {_ammoTypestr = "CLT"};
        default {_ammoTypestr = "HE"}; 
    };

    _markerName setMarkerAlpha 0.4;
    _centerMarkerName = createMarker [str (random 4), [0,0,0]];
    _centerMarkerName setMarkerType "mil_destroy";
    _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];
    _centerMarkerName setMarkerColor pl_side_color;

    if (visibleMap or !(isNull findDisplay 2000)) then {

        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        pl_cancel_strike = false;
        onMapSingleClick {
            pl_arty_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hint "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _markerName setMarkerPos _mPos;
            _centerMarkerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
    }
    else
    {
        pl_arty_cords = screenToWorld [0.5,0.5];
        _markerName setMarkerPos pl_arty_cords;
        _centerMarkerName setMarkerPos pl_arty_cords;
    };


    _cords = pl_arty_cords;
    _battery = pl_arty_groups#pl_active_arty_group_idx;

    _isHc = false;
    if (hcLeader _battery == player) then {
        _isHc = true;
        player hcRemoveGroup _battery;
        if (_battery getVariable "setSpecial") then {
            _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"];
        };
    };

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

    // [_eta, _centerMarkerName, _ammoTypestr] spawn {
    //     params ["_eta", "_centerMarkerName", "_ammoTypestr"];
    //     _time = time +_eta;
    //     while {time < _time} do {
    //         _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
    //         sleep 1;
    //     };
    //     _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
    // };

    if (pl_enable_beep_sound) then {playSound "beep"};
    if (pl_enable_chat_radio) then {(gunner (_guns#0)) sideChat format ["...Fire Mission Confimed ETA: %1s", round _eta]};
    if (pl_enable_map_radio) then {[group (gunner (_guns#0)), format ["...Fire Mission Confimed ETA: %1s", round _eta], 25] call pl_map_radio_callout};

    _volleys = round (pl_arty_rounds / (count _guns));
    _dispersion = pl_arty_dispersion;
    _delay = pl_arty_delay;
    _missionType = pl_arty_mission;

    _weapon = (getArray (configfile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "weapons"))#0;
    // _allMagazines = getArray (configfile >> "CfgWeapons" >> _weapon >> "Magazines");
    _allMagazines = magazines (_guns#0) + [currentMagazine (_guns#0)];

    // player sideChat (str _allMagazines);

    _ammoType = "";

    switch (pl_arty_round_type) do { 
        case 1 : {_ammoTypes = _allMagazines select {["he", _x] call BIS_fnc_inString}}; 
        case 2 : {_ammoTypes = (_allMagazines select {["smoke", _x] call BIS_fnc_inString}) + (_allMagazines select {["smk", _x] call BIS_fnc_inString})}; 
        case 3 : {_ammoTypes = _allMagazines select {["illum", _x] call BIS_fnc_inString}};
        case 4 : {_ammoTypes = _allMagazines select {["guid", _x] call BIS_fnc_inString}};
        case 5 : {_ammoTypes = _allMagazines select {["mine", _x] call BIS_fnc_inString}};
        case 6 : {_ammoTypes = (_allMagazines select {["cluster", _x] call BIS_fnc_inString}) + _allMagazines select {["icm", _x] call BIS_fnc_inString}};
        default {_ammoType = (currentMagazine (_guns#0))}; 
    };

    if ((count _ammoTypes) > 0) then {
        _ammoType = ([_ammoTypes, [], {parseNumber _x}, "DESCEND"] call BIS_fnc_sortBy)#0;
    };

    if (_ammoType isEqualTo "") exitWith {format ["Battery cant Fire %1 Rounds", _ammoTypestr]};

    // private _availableMagazinesLeader = magazinesAmmo [_guns#0, true];
    // {
    //     private _availableMagazines = magazinesAmmo [_x, true];

    //     for "_i" from 0 to (count _availableMagazinesLeader) - 1 do{
    //         if (((_availableMagazinesLeader#_i)#0) isEqualTo ((_availableMagazines#_i)#0)) then {
    //             (_availableMagazinesLeader#_i) set [1, ((_availableMagazinesLeader#_i)#1) + ((_availableMagazines#_i)#1)]
    //         };
    //     }
    // } forEach (_guns - [_guns#0]);

    // private _ammoAmount = 0;

    // player sideChat (str _availableMagazinesLeader);
    // {
    //     if (_ammoType isEqualTo (_x#0)) then {
    //         _ammoAmount = _x#1;
    //     };
    // } forEach _all;

    _allAmmo = [_guns] call pl_get_arty_ammo;

    private _ammoAmount = _allAmmo get _ammoType;

    if (_ammoAmount <= 0) exitWith {hint "No Ammo Left"};

    sleep 1;

    if !(_ammoType isEqualTo (currentMagazine (_guns#0))) then {
        // Force Reolad Hack
        {

            // player sideChat _ammoType;
            // player sideChat (currentMagazine _x);

            // _x doArtilleryFire [_cords, _ammoType, 1];

            _x loadMagazine [[0], _weapon, _ammoType];
            _x setWeaponReloadingTime [gunner _x, _weapon, 0];
            // sleep 1;
        } forEach _guns;

        sleep 1;

        if (((weaponState [_guns#0, [0]])#6) > 0) then {

                _reloadMarker = createMarker [str (random 4), getPos (_guns#0)];
                _reloadMarker setMarkerType "mil_circle";
                _reloadMarker setMarkerText format ["%1 %", round ((1 - ((weaponState [_guns#0, [0]])#6)) * 100)];
                _reloadMarker setMarkerColor pl_side_color;

            waitUntil {sleep 1; _reloadMarker setMarkerText format ["Reload: %1 %", round ((1 - ((weaponState [_guns#0, [0]])#6)) * 100)];; ((weaponState [_guns#0, [0]])#6) <= 0};

            deleteMarker _reloadMarker;

            sleep 5;
        };

    };

    [_eta, _centerMarkerName, _ammoTypestr] spawn {
        params ["_eta", "_centerMarkerName", "_ammoTypestr"];
        _time = time +_eta;
        while {time < _time} do {
            _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
            sleep 1;
        };
        _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
    };

    switch (_missionType) do { 
        case "SUP" : {

            for "_i" from 1 to _volleys do {
                {
                    _firePos = [[[_cords, _dispersion + 20]],[]] call BIS_fnc_randomPos;
                    _x setVariable ["pl_waiting_for_fired", true];
                    _x doArtilleryFire [_firePos, _ammoType, 1];
                    _eh = _x addEventHandler ["Fired", {
                        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
                        _unit setVariable ["pl_waiting_for_fired", false];
                    }];
                    // sleep 1;
                } forEach _guns;


                _MaxDelay = time + 40;
                _minDelay = time + _delay;
                waitUntil {({_x getVariable ["pl_waiting_for_fired", true]} count _guns == 0 and time >= _minDelay) or time >= _MaxDelay};
                _centerMarkerName setMarkerColor "colorOrange";
                // waitUntil {time >= _minDelay or time >= _MaxDelay};

                // pl_arty_ammo = pl_arty_ammo - 1;
            };

            {
                // _x addMagazineTurret [_ammoType, [-1]];
                _x removeEventHandler ["Fired", _eh];
                // _x setVehicleAmmo 1;
            } forEach _guns;
        }; 
        case "ANI" : {
            {
                _firePos = [[[_cords, 30]],[]] call BIS_fnc_randomPos;
                _x doArtilleryFire [_firePos, _ammoType, _volleys];
                sleep 1;
            } forEach _guns;
            _centerMarkerName setMarkerColor "colorOrange";
        }; 
        case "BLK" : {
            
        }; 
        default {}; 
    };
    

    if (_isHc) then {
        player hcSetGroup [_battery];
        if (_battery getVariable "setSpecial") then {
            _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
        };
    };

    sleep (_eta + 20);
    deleteMarker _markerName;
    deleteMarker _centerMarkerName;


};

pl_show_on_map_arty_menu = {
call compile format ["
pl_on_map_arty_menu = [
    ['Artillery',true],
    ['Call Artillery Strike', [2], '', -5, [['expression', '[] spawn pl_fire_on_map_arty']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Choose Battery:   %5', [3], '', -5, [['expression', '[] spawn pl_show_battery_menu']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Mission:     %7', [4], '#USER:pl_arty_mission_menu', -5, [['expression', '']], '1', '1'],
    ['Type:          %6', [5], '#USER:pl_arty_round_type_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Rounds:        %1', [6], '#USER:pl_arty_round_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Dispersion:    %2 m', [7], '#USER:pl_arty_dispersion_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Min Delay:     %3 s', [8], '#USER:pl_arty_delay_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0']
];", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, pl_arty_enabled, groupId (pl_arty_groups#pl_active_arty_group_idx), [pl_arty_round_type] call pl_get_type_str, pl_arty_mission];
showCommandingMenu "#USER:pl_on_map_arty_menu";
};


pl_arty_mission_menu = 
[
    ['Fire Mission',true],
    ['SUPPRESS', [2], '', -5, [['expression', 'pl_arty_mission = "SUP"; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['ANIHILATE', [3], '', -5, [['expression', 'pl_arty_mission = "ANI"; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['BLOCK', [4], '', -5, [['expression', 'pl_arty_mission = "BLK"; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

pl_get_type_str = {
    params ["_type"];

    private _return = "";
    switch (_type) do { 
          case 1 : {_return = "HE"}; 
          case 2 : {_return = "SMOKE"}; 
          case 3 : {_return = "ILLUM"};
          case 4 : {_return = "GUIDED"};
          case 5 : {_return = "MINE"};
          case 6 : {_return = "CLUSTER"};
          default {};
      };
    _return
};

pl_get_arty_ammo = {
    params ["_guns"];

    private _availableMagazinesLeader = magazinesAmmo [_guns#0, true];
    {
        private _availableMagazines = magazinesAmmo [_x, true];

        for "_i" from 0 to (count _availableMagazinesLeader) - 1 do {
            if (((_availableMagazinesLeader#_i)#0) isEqualTo ((_availableMagazines#_i)#0)) then {
                (_availableMagazinesLeader#_i) set [1, ((_availableMagazinesLeader#_i)#1) + ((_availableMagazines#_i)#1)]
            };
        }
    } forEach (_guns - [_guns#0]);

    private _allAmmoCount = createHashMap;

    {
        if !((_x#0) in _allAmmoCount) then {
            _allAmmoCount set [_x#0, _x#1];
        } else {
            _a = _allAmmoCount get (_x#0);
            _allAmmoCount set [_x#0, _a + (_x#1)];
        };
    } forEach _availableMagazinesLeader;

    _allAmmoCount
};

pl_get_arty_type_to_name = {
    params ["_typeName"];

        private _r = {
            if ([_x#0, _typeName] call BIS_fnc_inString) exitWith {_x#1};
            ""
        } forEach [["he", "HE"], ["smoke", "SMOKE"], ["smk", "SMOKE"], ["il", "ILLUM"], ["illum", "ILLUM"], ["guid", "GUIDED"], ["gui", "GUIDED"], ["cluster", "CLUSTER"], ["icm", "CLUSTER"], ["mine", "MINE"]];
    _r
};

pl_arty_round_type_menu_on_map = 
[
    ['Type',true],
    ['HE', [2], '', -5, [['expression', 'pl_arty_round_type = 1; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['SMOKE', [3], '', -5, [['expression', 'pl_arty_round_type = 2; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['ILLUM', [4], '', -5, [['expression', 'pl_arty_round_type = 3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['GUIDED', [5], '', -5, [['expression', 'pl_arty_round_type = 4; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['MINE', [6], '', -5, [['expression', 'pl_arty_round_type = 5; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['CLUSTER', [7], '', -5, [['expression', 'pl_arty_round_type = 6; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

// pl_show_battery_ammo_status = {
//     private ["_menuScript"];
//     _menuScript = "pl_arty_round_type_menu_on_map = [['Artillery Batteries',true],";
//     player sideChat (str count _ammo);

//     _n = 0;
//     {
//         _text = format ["%1 (%2)", [_x#0] call pl_get_arty_type_to_name, _x#1];
//         _menuScript = _menuScript + format ["[parseText '%1', [%2], '', -5, [['expression', 'pl_arty_round_type = %3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],", _text, _n + 2, _n];
//         _n = _n + 1;
//     } forEach _ammo;
//     _menuScript = _menuScript + "['', [], '', -5, [['expression', '']], '0', '0']]";

//     call compile _menuScript;
//     showCommandingMenu "#USER:pl_arty_round_type_menu_on_map";
// };
// "gm_mlrs_110mm_launcher"
// magazines[] = {"gm_36Rnd_mlrs_110mm_he_dm21","gm_36Rnd_mlrs_110mm_icm_dm602","gm_36Rnd_mlrs_110mm_mine_dm711","gm_36Rnd_mlrs_110mm_smoke_dm15"};

// _allMagazines = getArray (configfile >> "CfgWeapons" >> "gm_mlrs_110mm_launcher" >> "Magazines");


_weapon = (getArray (configfile >> "CfgVehicles" >> typeOf this >> "Turrets" >> "MainTurret" >> "weapons"))#0;
_allMagazines = getArray (configfile >> "CfgWeapons" >> _weapon >> "Magazines");

{
    this removeMagazines _x;
} forEach _allMagazines;

this addMagazine ["gm_36Rnd_mlrs_110mm_he_dm21", 36]; 
this addMagazine ["gm_36Rnd_mlrs_110mm_icm_dm602", 36]; 
this addMagazine ["gm_36Rnd_mlrs_110mm_mine_dm711", 36];

// getText (configFile >> "CfgAmmo" >> "gm_1Rnd_155mm_he_dm21" >> "displayName");

    // ["gm_1Rnd_155mm_he_dm21","gm_1Rnd_155mm_he_dm111","gm_1Rnd_155mm_icm_dm602","gm_1Rnd_155mm_smoke_dm105","gm_1Rnd_155mm_illum_dm106","gm_1Rnd_155mm_he_m107","gm_1Rnd_155mm_he_m795","gm_1Rnd_155mm_smoke_m116","gm_1Rnd_155mm_smoke_m110","gm_1Rnd_155mm_illum_m485","gm_10Rnd_155mm_he_dm21","gm_10Rnd_155mm_he_dm111","gm_10Rnd_155mm_icm_dm602","gm_10Rnd_155mm_smoke_dm105","gm_10Rnd_155mm_illum_dm106","gm_10Rnd_155mm_he_m107","gm_10Rnd_155mm_he_m795","gm_10Rnd_155mm_smoke_m116","gm_10Rnd_155mm_smoke_m110","gm_10Rnd_155mm_illum_m485","gm_20Rnd_155mm_he_dm21","gm_20Rnd_155mm_he_dm111","gm_20Rnd_155mm_icm_dm602","gm_20Rnd_155mm_smoke_dm105","gm_20Rnd_155mm_illum_dm106","gm_20Rnd_155mm_he_m107","gm_20Rnd_155mm_he_m795","gm_20Rnd_155mm_smoke_m116","gm_20Rnd_155mm_smoke_m110","gm_20Rnd_155mm_illum_m485","gm_4Rnd_155mm_he_dm21","gm_4Rnd_155mm_he_dm111","gm_4Rnd_155mm_icm_dm602","gm_4Rnd_155mm_smoke_dm105","gm_4Rnd_155mm_illum_dm106","gm_4Rnd_155mm_he_m107","gm_4Rnd_155mm_he_m795","gm_4Rnd_155mm_smoke_m116","gm_4Rnd_155mm_smoke_m110","gm_4Rnd_155mm_illum_m485"]

// [["gm_20Rnd_155mm_he_dm21",60],["gm_4Rnd_155mm_smoke_dm105",12],["gm_4Rnd_155mm_illum_dm106",12],["gm_1Rnd_155mm_he_dm21",3],["gm_1Rnd_155mm_he_dm111",3],
// ["gm_1Rnd_155mm_icm_dm602",3],["gm_1Rnd_155mm_smoke_dm105",3],["gm_1Rnd_155mm_illum_dm106",3],["gm_1Rnd_155mm_he_m107",3],["gm_1Rnd_155mm_he_m795",3],
// ["gm_1Rnd_155mm_smoke_m116",3],["gm_1Rnd_155mm_smoke_m110",3],["gm_1Rnd_155mm_illum_m485",3],["gm_10Rnd_155mm_he_dm21",30],["gm_10Rnd_155mm_he_dm111",30],["gm_10Rnd_155mm_icm_dm602",30],
// ["gm_10Rnd_155mm_smoke_dm105",30],["gm_10Rnd_155mm_illum_dm106",30],["gm_10Rnd_155mm_he_m107",30],["gm_10Rnd_155mm_he_m795",30],["gm_10Rnd_155mm_smoke_m116",30],
// ["gm_10Rnd_155mm_smoke_m110",30],["gm_10Rnd_155mm_illum_m485",30],["gm_20Rnd_155mm_he_dm21",60],["gm_20Rnd_155mm_he_dm111",60],["gm_20Rnd_155mm_icm_dm602",60],
// ["gm_20Rnd_155mm_smoke_dm105",60],["gm_20Rnd_155mm_illum_dm106",60],["gm_20Rnd_155mm_he_m107",60],["gm_20Rnd_155mm_he_m795",60],["gm_20Rnd_155mm_smoke_m116",60],
// ["gm_20Rnd_155mm_smoke_m110",60],["gm_20Rnd_155mm_illum_m485",60],["gm_4Rnd_155mm_he_dm21",12],["gm_4Rnd_155mm_he_dm111",12],["gm_4Rnd_155mm_icm_dm602",12],
// ["gm_4Rnd_155mm_smoke_dm105",12],["gm_4Rnd_155mm_illum_dm106",12],["gm_4Rnd_155mm_he_m107",12],["gm_4Rnd_155mm_he_m795",4],["gm_4Rnd_155mm_smoke_m116",12],
// ["gm_4Rnd_155mm_smoke_m110",12],["gm_4Rnd_155mm_illum_m485",12]]

// this addMagazine ["gm_20Rnd_155mm_he_dm21", 20];
// this addMagazine ["gm_20Rnd_155mm_he_dm21", 20];
// this addMagazine ["gm_20Rnd_155mm_smoke_m116", 20];

// [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",10],["gm_20Rnd_155mm_smoke_m116",10]];

// [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",10],["gm_20Rnd_155mm_smoke_m116",10]]

// [["gm_36Rnd_mlrs_110mm_he_dm21",72],["gm_36Rnd_mlrs_110mm_he_dm21",10],["gm_36Rnd_mlrs_110mm_icm_dm602",10],["gm_36Rnd_mlrs_110mm_mine_dm711",10],["gm_36Rnd_mlrs_110mm_smoke_dm15",10]]

// this addMagazine ["gm_36Rnd_mlrs_110mm_he_dm21", 36];
// this addMagazine ["gm_36Rnd_mlrs_110mm_icm_dm602", 36];
// this addMagazine ["gm_36Rnd_mlrs_110mm_mine_dm711", 36];
// [["gm_20Rnd_155mm_he_dm21",40],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_he_dm21",40],["gm_20Rnd_155mm_he_dm21",40],["gm_20Rnd_155mm_smoke_m116",40]]
// [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",40]]

// [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",36]]
// [["gm_20Rnd_155mm_he_dm21",120],["gm_4Rnd_155mm_smoke_dm105",8],["gm_4Rnd_155mm_illum_dm106",8],["gm_20Rnd_155mm_smoke_m116",40]] apply {[[_x#0] call pl_get_arty_type_to_name, _x#1]};

pl_support_status = {
    _gunCd = "ON STATION";
    _gunColor = "#66ff33";
    _gunRocketCd = "ON STATION";
    _gunRocketColor = "#66ff33";
    _clusterCd = "ON STATION";
    _clusterColor = "#66ff33";
    _jdamCd = "ON STATION";
    _jdamColor = "#66ff33";
    _sadPlaneCd = "ON STATION";
    _sadPlaneColor = "#66ff33";
    _sadHeloCd = "ON STATION";
    _sadHeloColor = "#66ff33";
    _sadUavCd = "ON STATION";
    _sadUavColor = "#66ff33";
    _sadMedevacCd = "ON STATION";
    _sadMedevacColor = "#66ff33";
    _time = time + 8;
    while {time < _time} do {
        if (time < pl_cas_cd) then {
            _gunCd = format ["%1s", round (pl_cas_cd - time)];
            _gunColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _gunRocketCd = format ["%1s", round (pl_cas_cd - time)];
            _gunRocketColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _clusterCd = format ["%1s", round (pl_cas_cd - time)];
            _clusterColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _jdamCd = format ["%1s", round (pl_cas_cd - time)];
            _jdamColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _sadPlaneCd = format ["%1s", round (pl_cas_cd - time)];
            _sadPlaneColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _sadHeloCd = format ["%1s", round (pl_cas_cd - time)];
            _sadHeloColor = '#b20000';
        };
        if (time < pl_uav_sad_cd) then {
            _sadUavCd = format ["%1s", round (pl_uav_sad_cd - time)];
            _sadUavColor = '#b20000';
        };
        if (time < pl_medevac_sad_cd) then {
            _sadMedevacCd = format ["%1s", round (pl_medevac_sad_cd - time)];
            _sadMedevacColor = '#b20000';
        };
        _batteryRounds = [(pl_arty_groups#pl_active_arty_group_idx) getVariable ["pl_active_arty_guns", []]] call pl_get_arty_ammo;

        _batteryRoundsFinal = createHashMap;
        {
            _batteryRoundsFinal set [[_x] call pl_get_arty_type_to_name, _y];
        } forEach _batteryRounds;
        // _batteryRounds = _batteryRounds apply {[_x] call pl_get_arty_type_to_name};
         _message = format ["
            <t color='#004c99' size='1.3' align='center' underline='1'>CAS</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Sorties:</t><t color='#00ff00' size='0.8' align='right'>%10</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Viper 1 (Gun Run)</t><t color='%1' size='0.8' align='right'>%2</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Viper 4 (Attack Run)</t><t color='%3' size='0.8' align='right'>%4</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Black Knight 1-2 (Cluster)</t><t color='%5' size='0.8' align='right'>%6</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Stroke 3 (JDAM)</t><t color='%7' size='0.8' align='right'>%8</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Reaper 1 (SAD Plane)</t><t color='%11' size='0.8' align='right'>%12</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Black Jack 4 (SAD HELO)</t><t color='%13' size='0.8' align='right'>%14</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Sentry 3 (UAV Recon)</t><t color='%15' size='0.8' align='right'>%16</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Angel 6 (MEDEVAC)</t><t color='%17' size='0.8' align='right'>%18</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Harvester 2 (Supply)</t><t color='%17' size='0.8' align='right'>%18</t>
            <br /><br />
            <t color='#004c99' size='1.3' align='center' underline='1'>Artillery</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Available Rounds</t><t color='#ffffff' size='0.8' align='right'>%9x</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Available Rounds %19:</t><t color='#ffffff' size='0.8' align='right'></t>
            <t color='#ffffff' size='0.8' align='left'>%20</t><t color='#ffffff' size='0.8' align='right'></t>
        ", _gunColor, _gunCd, _gunRocketColor, _gunRocketCd, _clusterColor, _clusterCd, _jdamColor, _jdamCd,  pl_arty_ammo, pl_sorties, _sadPlaneColor, _sadPlaneCd, _sadHeloColor, _sadHeloCd, _sadUavColor, _sadUavCd, _sadMedevacColor, _sadMedevacCd, groupId (pl_arty_groups#pl_active_arty_group_idx), _batteryRoundsFinal];

        hintSilent parseText _message;
        sleep 1;
    };
    hintSilent "";
};

// _off = [(pl_arty_groups#pl_active_arty_group_idx) getVariable ["pl_active_arty_guns", []]] call pl_get_arty_ammo;
// _off2 = _off apply {[[_x#0] call pl_get_arty_type_to_name, _x#1]};
// player sideChat (str _off2);


v1 addEventHandler ["HandleDamage", {
    params ["_unit", "_selection", "_damage", "_source", "_projectile", "_hitIndex", "_instigator", "_hitPoint"];

    if (["mine", _projectile] call BIS_fnc_inString) then {

        if !(_unit getVariable ["pl_mine_called_out", false]) then {
            if (pl_enable_beep_sound) then {playSound "radioina"};
            if (pl_enable_chat_radio) then {(leader (group (driver _unit))) sideChat format ["...We Just Hit a Mine", (groupId (group (driver _unit)))]};
            if (pl_enable_map_radio) then {[(group (driver _unit)), "...We Just Hit a Mine", 20] call pl_map_radio_callout};

            _mineArea = createMarker [str (random 3), getPos _unit];
            _mineArea setMarkerShape "RECTANGLE";
            _mineArea setMarkerBrush "Cross";
            _mineArea setMarkerColor "colorORANGE";
            _mineArea setMarkerAlpha 0.5;
            _mineArea setMarkerSize [25, 25];
            _mineArea setMarkerDir (getDir _unit);
            pl_engineering_markers pushBack _mineArea;

            _mines = allMines select {(_x distance2D _unit) < 20};

            {
                _m = createMarker [str (random 3), getPos _x];
                _m setMarkerType "mil_triangle";
                _m setMarkerSize [0.4, 0.4];
                _m setMarkerColor "ColorRed";
                _m setMarkerShadow false;
                pl_engineering_markers pushBack _m;
                playerSide revealMine _x;
            } forEach _mines;

            _unit setVariable ["pl_mine_called_out", true];

            [_unit] spawn {
                params ["_unit"];

                sleep 5;

                _unit setVariable ["pl_mine_called_out", nil];
            }
        };

    };
    _damage
}];


{
    _x setVariable ["pl_assigned_group", group (driver _x)];  
} forEach vehicles;

if (count (((getPos (leader _grp)) nearEntities [["Man"], 500]) select {side _x == playerSide and ((leader _grp) knowsAbout _x) > 0}) > 0) then {
    if ((random 1) > 0.4) then {
        [_grp] spawn pl_opfor_attack_closest_enemy;
        _time = time + 10 + (random 1);
    } else {
        [_grp] spawn pl_opfor_flanking_move;
        _time = time + 25 + (random 1);
    };
};
