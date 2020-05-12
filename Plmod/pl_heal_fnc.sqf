pl_medic_heal = {
    params ["_medic", "_target", "_time"];
    _healPos = (getPos leader (group _medic)) findEmptyPosition [0, 40];
    _moveToPos = {
        params ["_unit", "_pos"];
        _unit disableAI "AUTOCOMBAT";
        _unit doMove _pos;
        waitUntil {(_unit distance2D _pos < 2) or (unitReady _unit) or (!alive _unit) or !((group _unit) getVariable "onTask")};
        doStop _unit;
        _unit disableAI "PATH";
        _unit setUnitPos "MIDDLE";
    };
    if (_target == player) then {
        _h1 =[_medic, (getPos player)] spawn _moveToPos;
        _medic sideChat "Hold Position, Help is on the Way!";
        waitUntil {(scriptDone _h1) or !((group _medic) getVariable "onTask")};
    }
    else
    {
        _h1 = [_medic, _healPos] spawn _moveToPos;
        _h2 = [_target, _healPos] spawn _moveToPos;
        waitUntil {((scriptDone _h1) and (scriptDone _h2)) or !((group _medic) getVariable "onTask")};
    };
    if !(alive _target) exitWith {
        _medic enableAI "PATH";
        _medic enableAI "AUTOCOMBAT";
        _medic setUnitPos "AUTO";
        _medic doFollow leader (group _medic);
    };
    if !(alive _medic) exitWith {(group _medic) setVariable ["onTask", false]};
    _medic action["HealSoldier", _target];
    _time = time + 6;
    waitUntil {(time >= _time) or !((group _medic) getVariable "onTask")};
    _target setDamage 0;
    _medic enableAI "PATH";
    _medic enableAI "AUTOCOMBAT";
    _target enableAI "PATH";
    _target enableAI "AUTOCOMBAT";
    _medic setUnitPos "AUTO";
    _target setUnitPos "AUTO";
    _medic doFollow leader (group _medic);
    _target doFollow leader (group _target);
};



pl_ccp = {
    params ["_group"];
    private ["_ccpUp", "_medic", "_healTarget"];

    _group setVariable ["onTask", false];
    sleep 0.25;

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"];
    {
        doStop _x;
    } forEach (units _group);
    _medicClsName = ["B_medic_F", "O_medic_F", "I_medic_F", "I_E_medic_F"];
    _medic = ((units _group) select {(typeOf _x) in _medicClsName}) select 0;
    if !(isNil "_medic") then {
        while {(_group getVariable "onTask")} do {
            if (_group isEqualTo grpNull) exitWith {};
            _targets = (getPos leader _group) nearObjects ["Man", 30];
            {
                if (side _x == side _medic) then {
                    if ((damage _x > 0) and (alive _x)) then {
                        _healTarget = _x;
                        _h1 = [_medic, _healTarget] spawn pl_medic_heal;
                        waitUntil {scriptDone _h1 or !(_group getVariable "onTask")}
                    };
                };
            } forEach _targets;
            sleep 1;
        };
    }
    else
    {
        leader _group sideChat "Negativ, Our Medic is Dead";
    };
};

// [hcSelected player select 0] spawn pl_ccp;
