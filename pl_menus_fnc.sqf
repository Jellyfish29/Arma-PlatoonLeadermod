sleep 1;
// pl_support_enabled_setting = true;
if (pl_cas_enabled) then {pl_cas_enabled = 1;} else {pl_cas_enabled = 0;};
if (pl_arty_enabled) then {pl_arty_enabled = 1;} else {pl_arty_enabled = 0;};

if (pl_enabled_medical) then {pl_show_medical = 1} else {pl_show_medical = 0};
if (pl_enable_vehicle_recovery) then {pl_show_vehicle_recovery = 1} else {pl_show_vehicle_recovery = 0};
if (pl_virtual_mines_enabled) then {pl_show_virtual_mines = 1} else {pl_show_virtual_mines = 0};

// if (pl_support_enabled_setting) then {pl_cas_enabled = 1; pl_arty_enabled = 1; pl_satus_enabled = 1;}
// else{pl_cas_enabled = 0; pl_arty_enabled = 0; pl_satus_enabled = 0;};

pl_mortar_names = ["B_Mortar_01_F", "B_T_Mortar_01_F", "O_Mortar_01_F", "O_T_Mortar_01_F", "I_Mortar_01_F"];
pl_mortars = [];

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

pl_str_cas = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Air Support</t>';
pl_str_arty = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Off Map Artillery</t>';
pl_str_mortar = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> On Map Artillery</t>';
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

pl_str_heal = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"/><t> Enable/Disable autonomous Medic</t>';
pl_str_ccp = '<img color="#e5e500" image="\Plmod\gfx\pl_ccp_marker.paa"/><t> Set Up Casualty Collection Point</t>';
pl_str_aidStation = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"/><t> Set Up Aid Station</t>';
pl_str_transfer = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\exit_ca.paa"/><t> Transfer Medic</t>';
pl_str_resupply = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"/><t> Resupply at</t>';
pl_str_supply_point = '<img color="#e5e500" image="\Plmod\gfx\pl_r3p_marker.paa"/><t> Set Up Rearm, Refuel, Resupply Point</t>';
pl_str_repair = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"/><t> Recover/Repair Vehicle</t>';
pl_str_maintenance = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"/><t> Set up Maintenance Point</t>';
pl_str_recon = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa"/><t> Designate as Recon</t>';
pl_str_ce_menu = '<img color="#e5e500" image="\Plmod\gfx\b_engineer.paa"/><t> Combat Engineering Tasks</t>';
pl_rearm_point_str = '<img color="#e5e500" image="\Plmod\gfx\pl_asp_marker.paa"/><t> Set up Ammo Supply Point</t>';

//        [parseText '%13', [4], '', -5, [['expression', '[] spawn pl_vehicle_ccp_aid_station']], '%1', 'HCNotEmpty'],

pl_show_css_menu = {
    call compile format ["
    HC_Missions_0 = [
        ['Combat Support',true],
        [parseText '%3', [2], '', -5, [['expression', '[] spawn pl_spawn_heal_group']], '%1', 'HCNotEmpty'],
        [parseText '%4', [3], '', -5, [['expression', '[] spawn pl_ccp']], '%1', 'HCNotEmpty'],
        [parseText '%5', [4], '', -5, [['expression', '[] spawn pl_transfer_medic']], '%1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%1', '1'],
        [parseText '%6', [5], '', -5, [['expression', '[] spawn pl_rearm']], '1', 'HCNotEmpty'],
        [parseText '%12', [6], '', -5, [['expression', '[] spawn pl_rearm_point']], '1', 'HCNotEmpty'],
        [parseText '%10', [7], '', -5, [['expression', '[] spawn pl_supply_point']], '1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        [parseText '%7', [8], '', -5, [['expression', '[] spawn pl_repair']], '%2', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        [parseText '%11', [9], '#USER:pl_combat_engineer', -5, [['expression', '']], '%2', '1'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        [parseText '%9', [10], '', -5, [['expression', '[] spawn pl_recon']], '1', 'HCNotEmpty']
    ];", pl_show_medical, pl_show_vehicle_recovery, pl_str_heal, pl_str_ccp, pl_str_transfer, pl_str_resupply, pl_str_repair, pl_str_maintenance, pl_str_recon, pl_str_supply_point, pl_str_ce_menu, pl_rearm_point_str];
    // showCommandingMenu "#USER:pl_mortar_menu";
};

[] call pl_show_css_menu;

pl_mine_spacing_menu = [
    ['Mine Field Spacing',true],
    ['2m', [2], '', -5, [['expression', 'pl_mine_spacing = 2']], '1', '1'],
    ['4m', [3], '', -5, [['expression', 'pl_mine_spacing = 4']], '1', '1'],
    ['6m', [4], '', -5, [['expression', 'pl_mine_spacing = 6']], '1', '1'],
    ['8m', [5], '', -5, [['expression', 'pl_mine_spacing = 8']], '1', '1'],
    ['12m', [6], '', -5, [['expression', 'pl_mine_spacing = 12']], '1', '1'],
    ['16m', [7], '', -5, [['expression', 'pl_mine_spacing = 16']], '1', '1']
];

pl_str_charge = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>';
pl_str_detonate = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Detonate Charges</t>';
pl_str_lay_mine_field = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Lay Mine Field</t>';
pl_str_mine_field_spacing = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\map_ca.paa"/><t> Set Mine Field Spacing</t>';
pl_str_clear_mine = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\search_ca.paa"/><t> Clear Mines</t>';
pl_str_des_bridge = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Demolish Bridge</t>';
pl_str_rpr_bridge = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa"/><t> Repair Bridge</t>';

pl_show_egineer_menu = {
    call compile format ["
    pl_combat_engineer = [
        ['Combat Engineer Tasking',true],
        [parseText '%2', [2], '', -5, [['expression', '[] spawn pl_place_charge']], '%1', 'HCNotEmpty'],
        [parseText '%3', [3], '', -5, [['expression', '{[_x] spawn pl_detonate_charges} forEach (hcSelected player)']], '%1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        [parseText '%4', [4], '', -5, [['expression', '[] spawn pl_lay_mine_field']], '%1', 'HCNotEmpty'],
        [parseText '%5', [5], '#USER:pl_mine_spacing_menu', -5, [['expression', '']], '%1', '1'],
        [parseText '%6', [6], '', -5, [['expression', '[] spawn pl_mine_clearing']], '1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        [parseText '%7', [7], '', -5, [['expression', '[] spawn pl_destroy_bridge']], '%1', 'HCNotEmpty'],
        [parseText '%8', [8], '', -5, [['expression', '[] spawn pl_repair_bridge']], '%1', 'HCNotEmpty']
    ];", pl_virtual_mines_enabled, pl_str_charge, pl_str_detonate, pl_str_lay_mine_field, pl_str_mine_field_spacing, pl_str_clear_mine, pl_str_des_bridge, pl_str_rpr_bridge];
};

[] call pl_show_egineer_menu;


pl_str_gun = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Gun Run (1)</t>';
pl_str_attack_run = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Attack Run (2)</t>';
pl_str_cluster = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Cluster Bomb Strike (4)</t>';
pl_str_jdam = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> JDAM Strike (5)</t>';
pl_str_plane_sad = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\plane_ca.paa"/><t> Attack Plane SAD (3)</t>';
pl_str_helo_sad = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\heli_ca.paa"/><t> Attack Helo SAD (7)</t>';
pl_str_uav = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\intel_ca.paa"/><t> UAV Recon (4)</t>';
pl_str_medevac = '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"/><t> MEDEVAC (4)</t>';


pl_show_cas_menu = {
    call compile format ["
    pl_cas_menu = [
        ['CAS',true],
        [parseText '%8', [2], '', -5, [['expression', '[1] spawn pl_cas']], '1', '%1'],
        [parseText '%9', [3], '', -5, [['expression', '[2] spawn pl_cas']], '1', '%2'],
        [parseText '%10', [4], '', -5, [['expression', '[3] spawn pl_cas']], '1', '%3'],
        [parseText '%11', [5], '', -5, [['expression', '[4] spawn pl_cas']], '1', '%4'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        [parseText '%12', [6], '', -5, [['expression', '[1] spawn pl_interdiction_cas']], '1', '%5'],
        [parseText '%13', [7], '', -5, [['expression', '[2] spawn pl_interdiction_cas']], '1', '%6'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        [parseText '%14', [8], '', -5, [['expression', '[3] spawn pl_interdiction_cas']], '1', '%7'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        [parseText '%15', [9], '', -5, [['expression', '[4] spawn pl_interdiction_cas']], '1', '%16']

    ];", pl_gun_enabled, pl_gun_rocket_enabled, pl_cluster_enabled, pl_jdam_enabled, pl_plane_sad_enabled, pl_helo_sad_enabled, pl_uav_sad_enabled, pl_str_gun, pl_str_attack_run, pl_str_cluster, pl_str_jdam, pl_str_plane_sad, pl_str_helo_sad, pl_str_uav, pl_str_medevac, pl_medevac_sad_enabled];
    showCommandingMenu "#USER:pl_cas_menu";
};

pl_show_arty_menu = {
call compile format ["
pl_arty_menu = [
    ['Artillery',true],
    ['Call 155m Artillery Strike (%1)', [2], '', -5, [['expression', '[] spawn pl_arty']], '1', '%5'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Rounds:           %2', [3], '#USER:pl_arty_round_menu', -5, [['expression', '']], '1', '%5'],
    ['Dispersion:      %3 m', [4], '#USER:pl_arty_dispersion_menu', -5, [['expression', '']], '1', '%5'],
    ['Delay:               %4 s', [5], '#USER:pl_arty_delay_menu', -5, [['expression', '']], '1', '%5'],
    ['', [], '', -5, [['expression', '']], '1', '0']
];",pl_arty_ammo, pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, pl_arty_enabled];
showCommandingMenu "#USER:pl_arty_menu";
};

pl_arty_round_menu = 
[
    ['Rounds',true],
    ['1', [2], '', -5, [['expression', 'pl_arty_rounds = 1; [] spawn pl_show_arty_menu']], '1', '1'],
    ['3', [3], '', -5, [['expression', 'pl_arty_rounds = 3; [] spawn pl_show_arty_menu']], '1', '1'],
    ['6', [4], '', -5, [['expression', 'pl_arty_rounds = 6; [] spawn pl_show_arty_menu']], '1', '1'],
    ['9', [5], '', -5, [['expression', 'pl_arty_rounds = 9; [] spawn pl_show_arty_menu']], '1', '1'],
    ['12', [6], '', -5, [['expression', 'pl_arty_rounds = 12; [] spawn pl_show_arty_menu']], '1', '1'],
    ['15', [7], '', -5, [['expression', 'pl_arty_rounds = 15; [] spawn pl_show_arty_menu']], '1', '1'],
    ['18', [8], '', -5, [['expression', 'pl_arty_rounds = 18; [] spawn pl_show_arty_menu']], '1', '1'],
    ['21', [9], '', -5, [['expression', 'pl_arty_rounds = 21; [] spawn pl_show_arty_menu']], '1', '1'],
    ['24', [10], '', -5, [['expression', 'pl_arty_rounds = 24; [] spawn pl_show_arty_menu']], '1', '1']
];

pl_arty_dispersion_menu = 
[
    ['Dispersion',true],
    ['50 m', [2], '', -5, [['expression', 'pl_arty_dispersion = 50; [] spawn pl_show_arty_menu']], '1', '1'],
    ['75 m', [3], '', -5, [['expression', 'pl_arty_dispersion = 75; [] spawn pl_show_arty_menu']], '1', '1'],
    ['100 m', [4], '', -5, [['expression', 'pl_arty_dispersion = 100; [] spawn pl_show_arty_menu']], '1', '1'],
    ['125 m', [5], '', -5, [['expression', 'pl_arty_dispersion = 125; [] spawn pl_show_arty_menu']], '1', '1'],
    ['150 m', [6], '', -5, [['expression', 'pl_arty_dispersion = 150; [] spawn pl_show_arty_menu']], '1', '1'],
    ['200 m', [7], '', -5, [['expression', 'pl_arty_dispersion = 200; [] spawn pl_show_arty_menu']], '1', '1'],
    ['250 m', [8], '', -5, [['expression', 'pl_arty_dispersion = 250; [] spawn pl_show_arty_menu']], '1', '1'],
    ['300 m', [9], '', -5, [['expression', 'pl_arty_dispersion = 300; [] spawn pl_show_arty_menu']], '1', '1'],
    ['400 m', [10], '', -5, [['expression', 'pl_arty_dispersion = 400; [] spawn pl_show_arty_menu']], '1', '1'],
    ['600 m', [11], '', -5, [['expression', 'pl_arty_dispersion = 600; [] spawn pl_show_arty_menu']], '1', '1']
];

pl_arty_delay_menu = [
    ['Delay',true],
    ['1 s', [2], '', -5, [['expression', 'pl_arty_delay = 1; [] spawn pl_show_arty_menu']], '1', '1'],
    ['5 s', [3], '', -5, [['expression', 'pl_arty_delay = 5; [] spawn pl_show_arty_menu']], '1', '1'],
    ['10 s', [4], '', -5, [['expression', 'pl_arty_delay = 10; [] spawn pl_show_arty_menu']], '1', '1'],
    ['15 s', [5], '', -5, [['expression', 'pl_arty_delay = 15; [] spawn pl_show_arty_menu']], '1', '1'],
    ['20 s', [6], '', -5, [['expression', 'pl_arty_delay = 20; [] spawn pl_show_arty_menu']], '1', '1'],
    ['30 s', [7], '', -5, [['expression', 'pl_arty_delay = 30; [] spawn pl_show_arty_menu']], '1', '1']
];

pl_arty_round_menu_on_map = 
[
    ['Rounds',true],
    ['1', [2], '', -5, [['expression', 'pl_arty_rounds = 1; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['3', [3], '', -5, [['expression', 'pl_arty_rounds = 3; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['6', [4], '', -5, [['expression', 'pl_arty_rounds = 6; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['9', [5], '', -5, [['expression', 'pl_arty_rounds = 9; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['12', [6], '', -5, [['expression', 'pl_arty_rounds = 12; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['15', [7], '', -5, [['expression', 'pl_arty_rounds = 15; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['18', [8], '', -5, [['expression', 'pl_arty_rounds = 18; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['21', [9], '', -5, [['expression', 'pl_arty_rounds = 21; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['24', [10], '', -5, [['expression', 'pl_arty_rounds = 24; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

pl_arty_dispersion_menu_on_map = 
[
    ['Dispersion',true],
    ['50 m', [2], '', -5, [['expression', 'pl_arty_dispersion = 50; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['75 m', [3], '', -5, [['expression', 'pl_arty_dispersion = 75; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['100 m', [4], '', -5, [['expression', 'pl_arty_dispersion = 100; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['125 m', [5], '', -5, [['expression', 'pl_arty_dispersion = 125; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['150 m', [6], '', -5, [['expression', 'pl_arty_dispersion = 150; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['200 m', [7], '', -5, [['expression', 'pl_arty_dispersion = 200; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['250 m', [8], '', -5, [['expression', 'pl_arty_dispersion = 250; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['300 m', [9], '', -5, [['expression', 'pl_arty_dispersion = 300; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['400 m', [10], '', -5, [['expression', 'pl_arty_dispersion = 400; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['600 m', [11], '', -5, [['expression', 'pl_arty_dispersion = 600; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

pl_arty_delay_menu_on_map = [
    ['Delay',true],
    ['1 s', [2], '', -5, [['expression', 'pl_arty_delay = 1; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['5 s', [3], '', -5, [['expression', 'pl_arty_delay = 5; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['10 s', [4], '', -5, [['expression', 'pl_arty_delay = 10; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['15 s', [5], '', -5, [['expression', 'pl_arty_delay = 15; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['20 s', [6], '', -5, [['expression', 'pl_arty_delay = 20; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['30 s', [7], '', -5, [['expression', 'pl_arty_delay = 30; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

pl_arty_round_type = 1;
pl_arty_round_type_menu_on_map = 
[
    ['Type',true],
    ['HE', [2], '', -5, [['expression', 'pl_arty_round_type = 1; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['SMOKE', [3], '', -5, [['expression', 'pl_arty_round_type = 2; [] spawn pl_show_on_map_arty_menu']], '1', '1'],
    ['ILLUM', [4], '', -5, [['expression', 'pl_arty_round_type = 3; [] spawn pl_show_on_map_arty_menu']], '1', '1']
];

pl_get_type_str = {
    params ["_type"];

    private _return = "";
    switch (_type) do { 
          case 1 : {_return = "HE"}; 
          case 2 : {_return = "SMOKE"}; 
          case 3 : {_return = "ILLUM"};
          default {};
      };
    _return
};

pl_show_on_map_arty_menu = {
call compile format ["
pl_on_map_arty_menu = [
    ['Artillery',true],
    ['Call Artillery Strike', [2], '', -5, [['expression', '[] spawn pl_fire_on_map_arty']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Choose Battery:   %5', [3], '', -5, [['expression', '[] spawn pl_show_battery_menu']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['Type:          %6', [4], '#USER:pl_arty_round_type_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Rounds:        %1', [4], '#USER:pl_arty_round_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Dispersion:    %2 m', [5], '#USER:pl_arty_dispersion_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['Min Delay:     %3 s', [6], '#USER:pl_arty_delay_menu_on_map', -5, [['expression', '']], '1', '1'],
    ['', [], '', -5, [['expression', '']], '1', '0']
];", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, pl_arty_enabled, groupId (pl_arty_groups#pl_active_arty_group_idx), [pl_arty_round_type] call pl_get_type_str];
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


//    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\heal_ca.paa"/><t> Set Up Aid Station</t>', [5], '', -5, [['expression', '["aid"] call pl_task_planer']], '1', '1'],
pl_task_plan_menu = [
    ['Task Plan', true],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\pl_std_atk.paa'/><t> Assault Position</t>", [2], '', -5, [['expression', '["assault"] call pl_task_planer']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\pl_position.paa'/><t> Take Position</t>", [3], '', -5, [['expression', '["defPos"] call pl_task_planer']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"/><t> Set Up SP/MCP</t>', [4], '', -5, [['expression', '["resupply"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"/><t> Recover/Repair Vehicle</t>', [5], '', -5, [['expression', '["recover"] call pl_task_planer']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Lay Mine Field</t>', [6], '', -5, [['expression', '["mine"] call pl_task_planer']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>', [7], '', -5, [['expression', '["charge"] call pl_task_planer']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa"/><t> Unload Cargo</t>', [8], '', -5, [['expression', '["unload"] call pl_task_planer']], '1', '1']

];

pl_task_plan_menu_unloaded_inf = [
    ['Task Plan', true],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\attack_ca.paa'/><t> Assault Position</t>", [2], '', -5, [['expression', '["assault"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\AFP.paa'/><t> Defend Position</t>", [3], '', -5, [['expression', '["defend"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText "<img color='#e5e500' image='\Plmod\gfx\SFP.paa'/><t> Take Position</t>", [4], '', -5, [['expression', '["defPos"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\mine_ca.paa"/><t> Lay Mine Field</t>', [5], '', -5, [['expression', '["mine"] spawn pl_task_planer_unload_inf']], '1', '1'],
    [parseText '<img color="#e5e500" image="\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"/><t> Place Charge</t>', [6], '', -5, [['expression', '["charge"] spawn pl_task_planer_unload_inf']], '1', '1'],
    ['', [], '', -1, [['expression', '']], '1', '1']
];



pl_change_icon_menu = 
[
    ['Nato Markers',true],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_inf.paa'/><t> Infantry</t>", [2], '', -5, [['expression', '{[_x, "inf"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_armor.paa'/><t> Armor</t>", [3], '', -5, [['expression', '{[_x, "armor"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_mech_inf.paa'/><t> Mech Inf</t>", [4], '', -5, [['expression', '{[_x, "mech_inf"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_motor_inf.paa'/><t> Mot Inf</t>", [5], '', -5, [['expression', '{[_x, "motor_inf"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_recon.paa'/><t> Recon</t>", [6], '', -5, [['expression', '{[_x, "recon"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_maint.paa'/><t> Maintenance</t>", [7], '', -5, [['expression', '{[_x, "maint"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_support.paa'/><t> Support</t>", [8], '', -5, [['expression', '{[_x, "support"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_antiair.paa'/><t> Anti Air</t>", [9], '', -5, [['expression', '{[_x, "antiair"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_art.paa'/><t> Artillery</t>", [10], '', -5, [['expression', '{[_x, "art"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1'],
    [parseText "<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\b_unknown.paa'/><t> Unknown</t>", [11], '', -5, [['expression', '{[_x, "unknown"] call pl_change_group_icon} forEach (hcSelected player);']], '1', '1']
];

pl_group_management = [
    ['Group Management',true],
    ['Add', [2], '', -5, [['expression', '[] spawn pl_add_to_hc']], '1', '1'],
    ['Add All', [3], '', -5, [['expression', '[] call pl_add_all_groups']], '1', '1'],
    ['Remove', [4], '', -5, [['expression', '{[_x] call pl_remove_from_hc} forEach (hcSelected player)']], '1', 'HCNotEmpty'],
    ['Split', [5], '', -5, [['expression', '{[_x] call pl_split_hc_group} forEach (hcSelected player)']], '1', 'HCNotEmpty'],
    ['Merge', [6], '', -5, [['expression', '[] spawn pl_merge_hc_groups']], '1', 'HCNotEmpty'],
    ['Reset', [7], '', -5, [['expression', '[(hcSelected player) select 0] spawn pl_reset_group']], '1', 'HCNotEmpty'],
    ['Hard Unstuck', [8], '', -5, [['expression', '[(hcSelected player) select 0] call pl_hard_unstuck']], '1', 'HCNotEmpty'],
    ['Change Icon', [9], '#USER:pl_change_icon_menu', -5, [['expression', '']], '1', 'HCNotEmpty'],
    ['Delete', [7], '#USER:pl_confirm_delete', -5, [['expression', '']], '1', 'HCNotEmpty']
];

pl_confirm_delete = [
    ['Confirm Deletion',true],
    ['Confirm', [2], '', -5, [['expression', '{[_x] call pl_delete_group} forEach (hcSelected player)']], '1', 'HCNotEmpty']
];