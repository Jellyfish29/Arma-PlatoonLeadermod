sleep 1;
// pl_support_enabled_setting = true;
if (pl_cas_enabled) then {pl_cas_enabled = 1;} else {pl_cas_enabled = 0;};
if (pl_arty_enabled) then {pl_arty_enabled = 1;} else {pl_arty_enabled = 0;};

if (pl_enabled_medical) then {pl_show_medical = 1} else {pl_show_medical = 0};
if (pl_enable_vehicle_recovery) then {pl_show_vehicle_recovery = 1} else {pl_show_vehicle_recovery = 0};

// if (pl_support_enabled_setting) then {pl_cas_enabled = 1; pl_arty_enabled = 1; pl_satus_enabled = 1;}
// else{pl_cas_enabled = 0; pl_arty_enabled = 0; pl_satus_enabled = 0;};

pl_mortar_names = ["B_Mortar_01_F", "B_T_Mortar_01_F", "O_Mortar_01_F", "O_T_Mortar_01_F", "I_Mortar_01_F"];
pl_mortars = [];

pl_on_map_mortar = {
    private ["_mortars"];

    pl_mortars = [];
    _mortars = [];
    {
        if ((typeOf _x) in pl_mortar_names and (count (crew _x)) > 0) then {
            _mortars pushBack _x;
        };
    } forEach (vehicles select {side _x isEqualTo playerSide});

    if (count _mortars == 0) exitWith {0};
    pl_mortars append _mortars;
    1
};

pl_show_fire_support_menu = {
    call compile format ["
     HC_Custom_0 = [
        ['Fire Support',true],
        ['Close Air Support', [2], '', -5, [['expression', '[] spawn pl_show_cas_menu']], '1', '%1'],
        ['Artillery Strike', [3], '', -5, [['expression', '[] spawn pl_show_arty_menu']], '1', '%2'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        ['Platoon Mortar', [4], '', -5, [['expression', '[] spawn pl_show_mortar_menu']], '1', '%3'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        ['STATUS', [5], '', -5, [['expression', '[] spawn pl_support_status']], '1', '1']
    ];", pl_cas_enabled, pl_arty_enabled, [] call pl_on_map_mortar];
    // showCommandingMenu "#USER:pl_mortar_menu";
};

[] call pl_show_fire_support_menu;


pl_show_css_menu = {
    call compile format ["
    HC_Missions_0 = [
        ['CSS',true],
        ['Heal Squad', [2], '', -5, [['expression', '[] spawn pl_spawn_heal_group']], '%1', 'HCNotEmpty'],
        ['Set Up CCP', [3], '', -5, [['expression', '[] spawn pl_ccp']], '%1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%1', '1'],
        ['Resupply', [4], '', -5, [['expression', '[] spawn pl_spawn_rearm']], '1', 'HCNotEmpty'],
        ['', [], '', -1, [['expression', '']], '%2', '1'],
        ['Recover Vehicle', [5], '', -5, [['expression', '[] spawn pl_repair']], '%2', 'HCNotEmpty']
    ];", pl_show_medical, pl_show_vehicle_recovery];
    // showCommandingMenu "#USER:pl_mortar_menu";
};
[] call pl_show_css_menu;

pl_show_cas_menu = {
    call compile format ["
    pl_cas_menu = [
        ['CAS',true],
        ['Gun Run (1)', [2], '', -5, [['expression', '[1] spawn pl_cas']], '1', '%1'],
        ['Attack Run (2)', [3], '', -5, [['expression', '[2] spawn pl_cas']], '1', '%2'],
        ['Cluster Bomb Strike (4)', [4], '', -5, [['expression', '[3] spawn pl_cas']], '1', '%3'],
        ['JDAM Strike (5)', [5], '', -5, [['expression', '[4] spawn pl_cas']], '1', '%4'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        ['Attack Plane SAD (5)', [6], '', -5, [['expression', '[1] spawn pl_interdiction_cas']], '1', '%5'],
        ['Attack Helo SAD (4)', [7], '', -5, [['expression', '[2] spawn pl_interdiction_cas']], '1', '%6'],
        ['', [], '', -1, [['expression', '']], '1', '1'],
        ['UAV Recon (4)', [8], '', -5, [['expression', '[3] spawn pl_interdiction_cas']], '1', '%7']

    ];", pl_gun_enabled, pl_gun_rocket_enabled, pl_cluster_enabled, pl_jdam_enabled, pl_plane_sad_enabled, pl_helo_sad_enabled, pl_uav_sad_enabled];
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
    ['Dispersion',false],
    ['50 m', [2], '', -5, [['expression', 'pl_arty_dispersion = 50; [] spawn pl_show_arty_menu']], '1', '1'],
    ['75 m', [3], '', -5, [['expression', 'pl_arty_dispersion = 75; [] spawn pl_show_arty_menu']], '1', '1'],
    ['100 m', [4], '', -5, [['expression', 'pl_arty_dispersion = 100; [] spawn pl_show_arty_menu']], '1', '1'],
    ['125 m', [5], '', -5, [['expression', 'pl_arty_dispersion = 125; [] spawn pl_show_arty_menu']], '1', '1'],
    ['150 m', [6], '', -5, [['expression', 'pl_arty_dispersion = 150; [] spawn pl_show_arty_menu']], '1', '1'],
    ['200 m', [7], '', -5, [['expression', 'pl_arty_dispersion = 200; [] spawn pl_show_arty_menu']], '1', '1'],
    ['250 m', [8], '', -5, [['expression', 'pl_arty_dispersion = 250; [] spawn pl_show_arty_menu']], '1', '1'],
    ['300 m', [9], '', -5, [['expression', 'pl_arty_dispersion = 300; [] spawn pl_show_arty_menu']], '1', '1']
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



pl_show_mortar_menu = {
    call compile format ["
    pl_mortar_menu = [
        ['Platoon Mortar',true],
        ['Call Strike', [2], '', -5, [['expression', 'pl_arty_delay = 1; [] spawn pl_fire_mortar']], '1', '1'],
        ['', [], '', -5, [['expression', '']], '1', '0'],
        ['Rounds:           %1', [3], '#USER:pl_mortar_round_menu', -5, [['expression', '']], '1', '1']
    ];", pl_mortar_rounds];
    showCommandingMenu "#USER:pl_mortar_menu";
};

pl_mortar_round_menu = 
[
    ['Rounds',true],
    ['4', [2], '', -5, [['expression', 'pl_mortar_rounds = 4; [] spawn pl_show_mortar_menu']], '1', '1'],
    ['8', [3], '', -5, [['expression', 'pl_mortar_rounds = 8; [] spawn pl_show_mortar_menu']], '1', '1']

];