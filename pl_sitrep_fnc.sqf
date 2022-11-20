pl_get_group_health_hex = {
    params ["_group"];
    private ["_healthState"];
    _healthState = ["Green", "#66ff33"];
    {
        if ((damage _x) > 0.1) then {
            _healthState = ["Yellow", "#e5e500"];
        };
        if (_x getVariable "pl_wia" and (alive _x)) then {
            _healthState = ["Red", "#b20000"];
        };
    } forEach (units _group);
    _healthState;
};

pl_get_ammo_group_state = {
    params ["_group"];
    private ["_ammoState", "_magsDefault", "_magsDefaultSolo"];
    _ammoState = ["Green", "#66ff33", [0.4,1,0.2,1]];
    _magsDefault = 0;
    _magsDefaultSolo = _group getVariable ["magCountSoloDefault", 100];
    _magCountAll = 0;


    {
        _primary = primaryWeapon _x;
        _standartMagAmount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> _primary >> "magazines") apply {toUpper _x})} count magazines _x) + 1;
        _magCountAll = _magCountAll + _standartMagAmount;
        _magsDefault = _magsDefault + _magsDefaultSolo;
    } forEach (units _group);

    if (_magCountAll < (_magsDefault * 0.6)) then {
        _ammoState = ["Yellow", "#e5e500", [0.9,0.9,0,1]];
    };
    if (_magCountAll < (_magsDefault * 0.25)) then {
        _ammoState = ["Red", "#b20000", [0.7,0,0,1]];
    };
    _ammoState
};

pl_get_mg_ammo_status_need = {
    params ["_group", ["_amount", 2], ["_liveCheck", false]];

    private _c = 0;
    _mgAmmoStatus = {
        _unit = _x;
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun") then {_c = _c + 1};
        if ((primaryweapon _unit call BIS_fnc_itemtype) select 1 == "MachineGun" and ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> primaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit) <= _amount) exitWith {true}; 
        false
    } forEach (units _group);
    if (_liveCheck and _c == 0) exitWith {true};
    _mgAmmoStatus  
};

pl_get_at_ammo_status_need = {
    params ["_group", ["_amount", 0], ["_liveCheck", false]];

    private _missileCount = 0;
    private _c = 0;
    {
        if (secondaryWeapon _x != "") then {
            _c = _c + 1;
            _secondary = secondaryWeapon _x;
            if (toUpper ((secondaryWeaponMagazine _x)#0) in (getArray (configFile >> "CfgWeapons" >> _secondary >> "magazines") apply {toUpper _x})) then {_missileCount = _missileCount + 1};
        };
    } forEach (units _group);
    if (_liveCheck and _c == 0) exitWith {true};
    if (_c == 0) exitWith {false};
    if (_missileCount <= _amount) exitWith {true};
    false 
};

pl_sitrep_solo = {

    params ["_group"];

    _clockTime = [daytime, "HH:MM"] call BIS_fnc_timeToString;
    _gridPos = mapGridPosition (leader _group);
    _ammoState = [_group] call pl_get_ammo_group_state;
    _healthState = [_group] call pl_get_group_health_hex;
    _taskIcon = "";
    _onTask = _group getVariable "onTask";
    if (_onTask) then {
        _taskIcon = _group getVariable 'specialIcon';
    };

    _message = format ["
        <t color='#004c99' size='1.3' align='center' underline='1'>SITREP</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Callsign:</t><t color='#ffffff' size='0.9' align='right'>%1</t>
        <br /><br />
        <t color='#ffffff' size='1' align='left'>Status:</t><t color='#ffffff' size='0.9' align='right'>%2</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Formation:</t><t color='#ffffff' size='0.9' align='right'>%3</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Time:</t><t color='#ffffff' size='0.9' align='right'>%4</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Grid:</t><t color='#ffffff' size='0.9' align='right'>%5</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Strength:</t><t color='#ffffff' size='0.9' align='right'>%6x</t>
        <br />
        <t color='#ffffff' size='1' align='left'>Task:</t><img color='#e5e500' align='right' image='%7'/>
        <br /><br />
        <t color='#ffffff' size='0.9' align='left'>Health/MOS:</t><t color='#ffffff' size='0.9' align='right'>Ammo:</t>
        <br />
        <t color='%8' size='0.8' align='left'>%9</t><t color='%10' size='0.8' align='right'>%11</t>
        <br />
    ", (groupId _group), (behaviour (leader _group)), (formation _group), _clockTime, _gridPos, (count (units _group)), _taskIcon,
     _healthState select 1, _healthState select 0, _ammoState select 1, _ammoState select 0];

    {
        _mags = magazines _x;
        _mag = " ";
        _missile = " ";
        _magCount = 0;
        _missileCount = 0;


        _primary = primaryWeapon _x;
        _magCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> _primary >> "magazines") apply {toUpper _x})} count magazines _x);

        _secondary = secondaryWeapon _x;
        if !(_secondary isEqualTo "") then {
            _missileCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> _secondary >> "magazines") apply {toUpper _x})} count magazines _x);
        };


        if (toUpper ((primaryWeaponMagazine _x)#0) in (getArray (configFile >> "CfgWeapons" >> _primary >> "magazines") apply {toUpper _x})) then {_magCount = _magCount + 1};
        if (toUpper ((secondaryWeaponMagazine _x)#0) in (getArray (configFile >> "CfgWeapons" >> _secondary >> "magazines") apply {toUpper _x})) then {_missileCount = _missileCount + 1};

        _unitMos = getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName");
        _unitDamage = getDammage _x;
        _unitDamage = 100 - (round (_unitDamage * 100));
        _unitDamageStr = format ["%1%2", _unitDamage, "%"];
        if (_x getVariable "pl_wia") then {
            _unitDamageStr = "W.I.A";
        };
        if (_unitDamage <= 0) then {
            _unitDamageStr = "M.I.A";
        };
        _message = _message + format ["<br /><t color='#cccccc' size='0.8' align='left'>- %1 / %2</t><t color='#cccccc' size='0.8' align='right'> x%3</t>",_unitDamageStr, _unitMos, _magCount];
        if (_missileCount > 0) then{
            _message = _message + format ["<t color='#cccccc' size='0.8' align='right'>/x%1 AT</t>", _missileCount];
        };

    } forEach (units _group);

    private _availableMines = 0;
    {
        _mines = _x getVariable ["pl_virtual_mines", 0];
        _availableMines = _availableMines + _mines;
    } forEach (units _group);

    if (_availableMines > 0) then {
        _message = _message + format ["<br /><br /><t color='#ffffff' size='0.9' align='left'>Available Mines/Charges: </t><t color='#cccccc' size='0.9' align='right'>x%1</t>", _availableMines];
    };

    if (vehicle (leader _group) != (leader _group)) then {
        _vic = vehicle (leader _group);
        _vicName = getText (configFile >> "CfgVehicles" >> typeOf _vic >> "displayName");
        _unitDamage = getDammage _vic;
        _unitDamage = 100 - (round (_unitDamage * 100));
        _message = _message + format ["
            <br /><br /><t color='#cccccc' size='1' align='left'>Vehicle: %1</t>
            <br /><t color='#cccccc' size='0.8' align='left'>Status</t><t color='#cccccc' size='1' align='right'>%2%3</t>", _vicName, _unitDamage, "%"];
        if (_vic getVariable ["pl_is_supply_vehicle", false] or _vic getVariable ["pl_is_repair_vehicle", false] or getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular") isEqualTo "APC" or _vic isKindOf "Car") then {
            _ammoCargo = _vic getVariable ["pl_supplies", 0];
            _repairCargo = _vic getVariable ["pl_repair_supplies", 0];
            _reinforcements = _vic getVariable ["pl_avaible_reinforcements", 0];

            _message = _message + format ["
            <br /><t color='#cccccc' size='0.8' align='left'>Ammo/Medical Supplies: </t><t color='#cccccc' size='1' align='right'>%1</t>
            <br /><t color='#cccccc' size='0.8' align='left'>Repair Supplies: </t><t color='#cccccc' size='1' align='right'>%4</t>
            <br /><t color='#cccccc' size='0.8' align='left'>Avaible Reinforcements: </t><t color='#cccccc' size='1' align='right'>%3</t>", _ammoCargo, "%", _reinforcements, _repairCargo];

        };
    };

    _targets = [];
    _targets = [(leader _group)] call pl_get_targets;

    if ((count _targets) > 0) then {
        
        if ((_group getVariable "sitrepCd") < time) then {
            // [_targets] spawn pl_mark_targets_on_map;
            [_targets, (leader _group)] call pl_reveal_targets;
            _group setVariable ["sitrepCd", time + 30];
        };

        _manSpotted = "Man" countType _targets;
        _tankSpotted = "Tank" countType _targets;
        _carSpotted = "Car" countType _targets;
        _airSpotted = "Air" countType _targets;

        _message = _message + format ["
        <br /><br />
        <t color='#7f0000' size='1.3' align='center' underline='1'>CONTACTS</t>
        <br /><br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_inf.paa'/><t size='0.9' align='center'>INF</t><t size='0.8' align='right'>%1x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_armor.paa'/><t size='0.9' align='center'>ARM</t><t color='#ffffff' size='0.9' align='right'>%2x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_motor_inf.paa'/><t size='0.9' align='center'>MOT</t><t color='#ffffff' size='0.9' align='right'>%3x</t>
        <br />
        <img align='left' image='\A3\ui_f\data\map\markers\nato\o_air.paa'/><t size='0.9' align='center'>AIR</t><t color='#ffffff' size='0.9' align='right'>%4x</t>
        ",_manSpotted, _tankSpotted, _carSpotted, _airSpotted];

    }
    else
    {
        _message = _message + "
        <br /><br />
        <t color='#7f0000' size='1.3' align='center' underline='1'>CONTACTS</t>
        <br /><br />
        <t color='#7f0000' size='1' align='center'>Unknown Enemy Contacts</t>
        ";
    };
    hint parseText _message;
};

pl_sitrep_multi_cd = 0;

pl_sitrep_multi = {
    params ["_groups"];
    private ["_strengthAll", "_groupInfo", "_targetsAll", "_message"];

    _strengthAll = 0;
    _targetsAll = [];
    _targets =  [];
    _groupInfo = [];
    _message = "<t color='#004c99' size='1.5' align='center' underline='1'>SITREP</t>";
    {
        _group = _x;
        _callsign = groupId _group;
        _strength = count (units _group);
        _strengthAll = _strengthAll + _strength;
        _healthState = ([_group] call pl_get_group_health_hex) select 1;
        _ammoState = [_group] call pl_get_ammo_group_state;

        _taskIcon = "";
        _onTask = _group getVariable ["onTask", false];
        if (_onTask) then {
            _taskIcon = _group getVariable 'specialIcon';
        };

        _contactIconColor = "#66ff33";
        _inContact = _group getVariable 'inContact';
        if (_inContact) then {
            _contactIconColor = "#b20000";
        };

        _statusColor = "#66ff33";
        _statusIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa';
        _behaviour = behaviour (leader _group);
        if (_behaviour isEqualTo 'COMBAT') then {
            _statusColor = "#b20000";
            _statusIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa';
        };
        if (_behaviour isEqualTo 'STEALTH') then {
            _statusColor = '#004c99';
            _statusIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa';
        };
        if (_behaviour isEqualTo 'SAFE') then {
            _statusColor = "#cccccc";
            _statusIcon = '\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa';
        };

        _groupStatus = [_statusColor, _statusIcon];

        _groupInfo pushBack [_callsign, _strength, _healthState, _ammoState, _taskIcon, _contactIconColor, _groupStatus];

        _targets = [(leader _group)] call pl_get_targets;
        _targetsAll append _targets;
    } forEach _groups;

    _targetsAll = _targetsAll arrayIntersect _targetsAll;

    if (pl_sitrep_multi_cd < time) then {
        // [_targetsAll] spawn pl_mark_targets_on_map;
        [_targetsAll, player] call pl_reveal_targets;
        pl_sitrep_multi_cd = time + 30;
    };
    _targetsAmount = count _targetsAll;

    _message = _message + format ["
    <br /><br />
    <t color='#ffffff' size='1' align='left'>Strength:</t><t color='#ffffff' size='1' align='right'>%1x</t>
    <br /><br />
    <t color='#ffffff' size='1' align='left'>Contacts:</t><t color='#ffffff' size='1' align='right'>%2x</t>
    <br /><br />
    <t color='#ffffff' size='1.1' align='center' underline='1'>Units:</t>", _strengthAll, _targetsAmount];
    {
        _callsign = _x select 0;
        _strength = _x select 1;
        _healthState = _x select 2;
        _ammoState = _x select 3;
        _taskIcon = _x select 4;
        _contactColor = _x select 5;
        _groupStatus = _x select 6;

        _message = _message + format ["
        <br />
        <t color='#004c99' size='1' align='left'>%1</t>
        <img color='#e5e500' align='right' image='%2'/>
        <img color='%3' align='right' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/>
        <img color='%4' align='right' image='%5'/>
        <br />
        <t color='#cccccc' size='0.9' align='left'>Strength: </t><t color='%6' size='0.9' align='left'>%7</t>
        <t color='#cccccc' size='0.9' align='right'>Ammo: </t><t color='%8' size='0.9' align='right'>%9</t>",
         _callsign, _taskIcon, _contactColor, _groupStatus select 0, _groupStatus select 1, _healthState,
        _strength, _ammoState select 1, _ammoState select 0];
    } forEach _groupInfo;

    hint parseText _message;
};


pl_spawn_sitrep = {
    if (count (hcSelected player) == 1) then {
        [(hcSelected player select 0)] spawn pl_sitrep_solo;
    };
    if (count (hcSelected player) > 1) then {
        [hcSelected player] spawn pl_sitrep_multi;
    };
};

// [] call pl_spawn_sitrep;
