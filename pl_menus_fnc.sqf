// pl_support_enabled_setting = true;
if (pl_cas_enabled) then {pl_cas_enabled = 1;} else {pl_cas_enabled = 0;};
if (pl_arty_enabled) then {pl_arty_enabled = 1;} else {pl_arty_enabled = 0;};

// if (pl_support_enabled_setting) then {pl_cas_enabled = 1; pl_arty_enabled = 1; pl_satus_enabled = 1;}
// else{pl_cas_enabled = 0; pl_arty_enabled = 0; pl_satus_enabled = 0;};



call compile format ["
 HC_Custom_0 = [
    ['Fire Support',true],
    ['Close Air Support', [2], '', -5, [['expression', '[] spawn pl_show_cas_menu']], '1', '%1'],
    ['Artillery Strike', [3], '', -5, [['expression', '[] spawn pl_show_arty_menu']], '1', '%2'],
    ['', [], '', -5, [['expression', '']], '1', '0'],
    ['STATUS', [4], '', -5, [['expression', '[] spawn pl_support_status']], '1', '1']
];", pl_cas_enabled, pl_arty_enabled];

HC_Missions_0 = [
    ['Logistics',true],
    ['Recover Vehicle', [2], '', -5, [['expression', '[] spawn pl_repair']], '1', 'HCNotEmpty']
];

pl_show_cas_menu = {
    call compile format ["
    pl_cas_menu = [
        ['CAS',true],
        ['Attack Run', [2], '', -5, [['expression', '[1] spawn pl_cas']], '1', '%1'],
        ['Cluster Bomb Strike', [3], '', -5, [['expression', '[2] spawn pl_cas']], '1', '%2'],
        ['JDAM Strike', [4], '', -5, [['expression', '[3] spawn pl_cas']], '1', '%3']
    ];", pl_gun_enabled, pl_cluster_enabled, pl_jdam_enabled];
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
    ['2', [2], '', -5, [['expression', 'pl_arty_rounds = 2; [] spawn pl_show_arty_menu']], '1', '1'],
    ['4', [3], '', -5, [['expression', 'pl_arty_rounds = 4; [] spawn pl_show_arty_menu']], '1', '1'],
    ['6', [4], '', -5, [['expression', 'pl_arty_rounds = 6; [] spawn pl_show_arty_menu']], '1', '1'],
    ['8', [5], '', -5, [['expression', 'pl_arty_rounds = 8; [] spawn pl_show_arty_menu']], '1', '1'],
    ['10', [6], '', -5, [['expression', 'pl_arty_rounds = 10; [] spawn pl_show_arty_menu']], '1', '1'],
    ['12', [7], '', -5, [['expression', 'pl_arty_rounds = 12; [] spawn pl_show_arty_menu']], '1', '1']
];

pl_arty_dispersion_menu = 
[
    ['Dispersion',false],
    ['50 m', [2], '', -5, [['expression', 'pl_arty_dispersion = 50; [] spawn pl_show_arty_menu']], '1', '1'],
    ['75 m', [3], '', -5, [['expression', 'pl_arty_dispersion = 75; [] spawn pl_show_arty_menu']], '1', '1'],
    ['100 m', [4], '', -5, [['expression', 'pl_arty_dispersion = 100; [] spawn pl_show_arty_menu']], '1', '1'],
    ['125 m', [5], '', -5, [['expression', 'pl_arty_dispersion = 125; [] spawn pl_show_arty_menu']], '1', '1'],
    ['150 m', [6], '', -5, [['expression', 'pl_arty_dispersion = 150; [] spawn pl_show_arty_menu']], '1', '1'],
    ['200 m', [7], '', -5, [['expression', 'pl_arty_dispersion = 200; [] spawn pl_show_arty_menu']], '1', '1']
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