class cfgFunctions
{
    class PlModFnc
    {
        class AddonPlMod
        {
            class init
            {
                postInit=1;
                file="\Plmod\init.sqf";
            };
        };
    };
};

class CfgPatches
{
    class Pl_Mod
    {
        projectName="Platoon Leader: High Command Mod";
        version="A3.1.5.4.3";
        author="Jellyfish";
        requiredVersion=0.1;
        units[]={};
        requiredAddons[]=
        {
            "A3_UI_F",
            "A3_Dubbing_Radio_F"
        };
    };
};

class CfgSurfaces {
    class Default {
        AIAvoidStance = 1;
    };
};

// class Extended_PreInit_EventHandlers {
//     class pl_settings {
//         init = "call compile preprocessFileLineNumbers '\Plmod\XEH_preInit.sqf'";
//     };
// };

class RscHCGroupRootMenu
{
    access=0;
    contexsensitive=1;
    title="";
    atomic=0;
    vocabulary="";
    class Items
    {
        class Empty1
        {
            title="";
            shortcuts[]={0};
            command="";
            show="HCIsLeader * (1 - HCCursorOnIconEnemy)";
            enable="0";
            speechId=0;
        };
        class EmptyBlank1: Empty1
        {
            title="";
            show="(1 - HCIsLeader)";
            enable="0";
        };
        // class Attack
        // {
        //     title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Suppress</t>";
        //     shortcuts[]={0};
        //     command=-5;
        //     class Params
        //     {
        //         expression="[] call pl_spawn_suppression";
        //     };
        //     show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
        //     enable="HCNotEmpty";
        //     speechId=0;
        //     cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
        //     priority=2;
        // };
        class EmptyBlank2: Empty1
        {
            title="command 3";
            show="0" //"(1 - HCIsLeader) + (HCIsLeader * (1 - CursorOnGround)) + (HCCursorOnIconSelectable)";
            enable="0";
        };
        class Move
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Set Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x, false] call pl_reset;} forEach (hcSelected player); playSound 'beep'; ['MOVE',_pos,_is3D,hcselected player,false] call BIS_HC_path_menu";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=1;
        };
        class MoveAdd
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Add Waypoint</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression=
                    "{if ((count (waypoints _x)) == 0) then {[_x, false] spawn pl_reset}} forEach (hcSelected player); playSound 'beep'; if (count (hcSelected player) > 1 and (!pl_draw_formation_mouse)) then {[hcSelected player, true] spawn pl_move_as_formation}; if (count (hcSelected player) <= 1) then {['MOVE',_pos,_is3D,hcselected player,true] call BIS_HC_path_menu}";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=2;
        };
        class Watch
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa'/><t> Watch Direction</t>";
            shortcuts[]={0};
            command=-5;
            class params
            {
                expression="[] call pl_spawn_watch_dir";
            };
            show="HCIsLeader * CursorOnGround * IsWatchCommanded * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\watch_ca.paa";
            priority=2;
        };
        class Empty3
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\run_ca.paa'/><t> Rusch/Fallback</t>";
            shortcuts[]={};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_rush} forEach hcSelected player";
            };
            show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=1;
        };
        class Empty4
        {
            title="<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\normal_ca.paa'/><t> Advance</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_advance} forEach (hcSelected player)";
            };
            show="HCIsLeader * CursorOnGround * (1 - IsWatchCommanded) * (1 - HCCursorOnIconSelectable) * (1 - IsSelectedToAdd)";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=2;
        };
        // class Separator
        // {
        //     title="";
        //     shortcuts[]={0};
        //     command=-1;
        // };
        class Empty5
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa'/><t> March</t>";
            shortcuts[]={0};
            command=-5;
            class Params
            {
                expression="{[_x] spawn pl_march}forEach (hcSelected player)";
            };
            show="HCIsLeader * CursorOnGround * (1 - HCCursorOnIconSelectable) * IsSelectedToAdd * IsWatchCommanded";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=4;
        };
        class Empty6
        {
            title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa'/><t> Bounding Overwatch</t>";
            shortcuts[]={};
            command=-5;
            class Params
            {
                expression="[] spawn pl_bounding_squad";
            };
            // show="HCIsLeader * IsWatchCommanded * (1 - IsSelectedToAdd)";
            show = "0";
            enable="HCNotEmpty";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            priority=3;
        };
        class Empty7: Empty1
        {
            title="";
            show="0";
        };
        class EmptyBlank7: Empty1
        {
            title="";
            show="0";
        };
        class Select
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Selectset0";
            shortcuts[]={0};
            command="CMD_HC_SELECT_AUTO";
            show="HCIsLeader * HCCursorOnIconSelectable * (1 - IsSelectedToAdd)";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class SelectAdd
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Select0";
            shortcuts[]={0};
            command="CMD_HC_SELECT_AUTO_ADD";
            show="HCIsLeader * HCCursorOnIconSelectable * (1 - HCCursorOnIconSelectableSelected) * IsSelectedToAdd";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class Deselect
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Deselect0";
            shortcuts[]={0};
            command="CMD_HC_DESELECT_AUTO";
            show="HCIsLeader * HCCursorOnIconSelectable * (HCCursorOnIconSelectableSelected) * IsSelectedToAdd";
            enable="1";
            speechId=0;
            cursorTexture="\A3\ui_f\data\igui\cfg\cursors\selectOver_ca.paa";
            priority=2;
        };
        class Empty8: Empty1
        {
            title="";
            command=-1;
            show="0";
        };
        class SelectUnitFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_SelectUnitFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_SELECT_UNIT_FROM_BAR";
            show="IsXbox * HCCanSelectUnitFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class DeselectUnitFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_DeselectUnitFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_DESELECT_UNIT_FROM_BAR";
            show="IsXbox * HCCanDeselectUnitFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class SelectTeamFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_SelectTeamFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_SELECT_TEAM_FROM_BAR";
            show="IsXbox * HCCanSelectTeamFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class DeselectTeamFromBar
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_DeselectTeamFromBar0";
            shortcuts[]=
            {
                0,
                "0x00050000 + 3"
            };
            command="CMD_DESELECT_TEAM_FROM_BAR";
            show="IsXbox * HCCanDeselectTeamFromBar";
            enable="HCNotEmpty";
            speechId=0;
            priority=3;
        };
        class Empty9: Empty1
        {
            title="";
            show="0";
        };
        class Empty10: Empty1
        {
            title="";
            show="0";
        };
        class Reply
        {
            title="$STR_rscMenu.hppRscGroupRootMenu_Items_Communication0";
            shortcuts[]={0};
            menu="#User:BIS_fnc_addCommMenuItem_menu";
            show="1";
            enable="1";
            speechId=0;
        };
    };
};
    class RscHCMainMenu
    {
        class Items
        {
            class Move
            {
                shortcuts[] = {2};
                title = "Move";
                shortcutsAction = "CommandingMenu1";
                menu = "RscHCMoveHigh";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Target
            {
                shortcuts[] = {3};
                title = "Target";
                shortcutsAction = "CommandingMenu2";
                menu = "#USER:HC_Targets_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Engage
            {
                shortcuts[] = {4};
                title = "Engage";
                shortcutsAction = "CommandingMenu3";
                menu = "RscHCWatchDir";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Speed
            {
                shortcuts[] = {5};
                title = "Speed";
                shortcutsAction = "CommandingMenu4";
                menu = "RscHCSpeedMode";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Mission
            {
                shortcuts[] = {6};
                title = "Mission";
                shortcutsAction = "CommandingMenu5";
                menu = "#USER:HC_Missions_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Action
            {
                shortcuts[] = {7};
                title = "Action";
                shortcutsAction = "CommandingMenu6";
                menu = "#USER:HC_Custom_0";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CombatMode
            {
                shortcuts[] = {8};
                title = "Combat Mode";
                shortcutsAction = "CommandingMenu7";
                menu = "RscHCCombatMode";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Formations
            {
                shortcuts[] = {9};
                title = "Formation";
                shortcutsAction = "CommandingMenu8";
                menu = "RscHCFormations";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Team
            {
                shortcuts[] = {10};
                title = "Team";
                shortcutsAction = "CommandingMenu9";
                menu = "RscHCTeam";
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class Reply
            {
                shortcuts[] = {11};
                title = "Reply";
                shortcutsAction = "CommandingMenu0";
                menu = "RscHCReply";
                speechId = 0;
            };
            // class Back
            // {
            //     shortcuts[] = {"BACK"};
            //     title = "";
            //     command = -4;
            //     speechId = 0;
            // };
        };
        access = 0;
        title = "High Command - Commander";
        atomic = 0;
        vocabulary = "";
    };
    class RscHCMoveHigh
    {
        class Items
        {
            class NextWP
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'NEXTWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Next Waypoint</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CancelWP
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "'CANCELWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Last Waypoint</t>";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class CancelAllWPs
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'CANCELALLWP' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel All Waypoint</t>";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
                speechId = 0;
            };
            class PlSeperator1
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlStop
            {
                title="<img color='#b20000' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Task / Stop</t>";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="playSound 'beep'; [] call pl_spawn_reset";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator15
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlHold
            {
                title="<img color='#EC3E14' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Hold</t>";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_hold";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlExecute
            {
                title="<img color='#EC3E14' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Execute</t>";
                shortcuts[]={7};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_execute";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator10
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlFollow
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa'/><t> Form on Commander</t>";
                shortcuts[]={8};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_follow ";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };

            // class PlFormationMove
            // {
            //     title="<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\line_ca.paa'/><t> Formation Move</t";
            //     shortcuts[]={9};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_move_as_formation";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            
        };
        title = "Move";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCWatchDir
    {
        class items
        {
            class OpenFire
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\map\markers\military\arrow_CA.paa'/><t> Assault Position</t>";
                shortcuts[]={2};
                submenu="";
                command=-5;
                class params
                {
                    expression="[(hcSelected player) select 0] spawn pl_assault_position";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            };
            class HoldFire
            {
                title="<img color='#e5e500' image='\Plmod\gfx\AFP.paa'/><t> Defend Position</t>";
                shortcuts[]={3};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_defend_position} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\tactical_ca.paa";
            };
            class PlTakePosition
            {
                title="<img color='#e5e500' image='\Plmod\gfx\SFP.paa'/><t> Take Position</t>";
                shortcuts[]={4};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_take_position;";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator11
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlSuppressArea
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Suppress Position</t>";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_suppressive_fire_position";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
                cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            };
            // class PlFieldOfFire
            // {
            //     title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\rifle_ca.paa'/><t> Set Field of Fire</t>";
            //     shortcuts[]={6};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_field_of_fire";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            //     cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            // };
            class PlSeperator21
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlTakeCover
            {
                title="<img color='#e5e500' image='\A3\3den\data\Attributes\Stance\down_ca.paa'/><t> Take Cover/Button Up</t>";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_full_cover} forEach (hcSelected player)";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlTankHunt
            // {
            //     title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa'/><t> Destroy Vehicles</t>";
            //     shortcuts[]={6};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_tank_hunt";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            //     cursorTexture="\A3\ui_f\data\igui\cfg\cursors\attack_ca.paa";
            // };
            class PlSeperator5
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlBoundingSquad
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\help_ca.paa'/><t> Bounding Overwatch</t>";
                shortcuts[]={7};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_bounding_squad";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            
            class PlSeperator301
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlAttachInf
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\map\markers\nato\n_mech_inf.paa'/><t> Follow Vehicle</t";
                shortcuts[]={8};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_attach_inf";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlGarBuilding
            // {
            //     title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getin_ca.paa'/><t> Garrison Building</t>";
            //     shortcuts[]={7};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_garrison_building";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            
            // class PlCancelTask2
            // {
            //     title="<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Cancel Task</t>";
            //     shortcuts[]={10};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="playSound 'beep'; [] call pl_spawn_reset";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Combat Tasking";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCCombatMode
    {
        class items
        {
            class Stealth
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_STEALTH' call BIS_HC_path_menu";
                };
                title = "<img color='#191999' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\scout_ca.paa'/><t> Stealth</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Combat
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_DANGER' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\danger_ca.paa'/><t> Combat</t";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Aware
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_AWARE' call BIS_HC_path_menu";
                };
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\listen_ca.paa'/><t> Aware</t";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Safe
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "{{_x disableAI 'AUTOCOMBAT';}forEach (units _x);}forEach (hcSelected player); 'COMBAT_SAFE' call BIS_HC_path_menu";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\wait_ca.paa'/><t> Safe</t";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlSeperator8
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class OpenFire
            {
                shortcuts[] = {6};
                class Params
                {
                    expression = "{[_x] call pl_open_fire} forEach (hcSelected player)";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Open Fire</t";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class HoldFire
            {
                shortcuts[] = {7};
                class Params
                {
                    expression = "{[_x] call pl_hold_fire} forEach (hcSelected player)";
                };
                title = "<img color='#191999' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\target_ca.paa'/><t> Hold Fire</t";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
        };
        title = "Combat Mode";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCSpeedMode
    {
        class items
        {
            class Limited
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'SPEED_LIMITED' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\limited_ca.paa'/><t> Limited</t";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Normal
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'SPEED_NORMAL' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\normal_ca.paa'/><t> Normal</t";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Full
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "'SPEED_FULL' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\SpeedMode\full_ca.paa'/><t> Full</t";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlSeperator7
            {
                title="Vehicle Speed:";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlVic15
            {
                shortcuts[]={6};
                class Params
                {
                    expression = "[15] call pl_spawn_vic_speed";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 15 km/h</t";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVic30
            {
                shortcuts[]={7};
                class Params
                {
                    expression = "[30] call pl_spawn_vic_speed";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 30 km/h</t";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVic50
            {
                shortcuts[]={8};
                class Params
                {
                    expression = "[50] call pl_spawn_vic_speed";
                };
                title = "<img color='#66ff33' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> 50 km/h</t";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class PlVicMax
            {
                shortcuts[]={9};
                class Params
                {
                    expression = "[5000] call pl_spawn_vic_speed";
                };
                title = "<img color='#ffffff' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> Max</t";
                shortcutsAction = "CommandingMenu7";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
        };
        title = "Speed";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCFormations
    {
        class items
        {
            class Column
            {
                shortcuts[] = {2};
                class Params
                {
                    expression = "'COLUMN' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\column_ca.paa'/><t> Column</t>";
                shortcutsAction = "CommandingMenu1";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class ColumnStag
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "'STAG COLUMN' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\stag_column_ca.paa'/><t> Stag Column</t>";
                shortcutsAction = "CommandingMenu2";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Wedge
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "'WEDGE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\wedge_ca.paa'/><t> Wedge</t>";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class EchelonL
            {
                shortcuts[] = {5};
                class Params
                {
                    expression = "'ECH LEFT' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\ech_left_ca.paa'/><t> Echelon L.</t>";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class EchelonR
            {
                shortcuts[] = {6};
                class Params
                {
                    expression = "'ECH RIGHT' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\ech_right_ca.paa'/><t> Echelon R.</t>";
                shortcutsAction = "CommandingMenu5";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Vee
            {
                shortcuts[] = {7};
                class Params
                {
                    expression = "'VEE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\vee_ca.paa'/><t> Vee</t>";
                shortcutsAction = "CommandingMenu6";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Line
            {
                shortcuts[] = {8};
                class Params
                {
                    expression = "'LINE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\line_ca.paa'/><t> Line</t>";
                shortcutsAction = "CommandingMenu7";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class ColumnCompact
            {
                shortcuts[] = {9};
                class Params
                {
                    expression = "'FILE' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\file_ca.paa'/><t> File</t>";
                shortcutsAction = "CommandingMenu8";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
            class Delta
            {
                shortcuts[] = {10};
                class Params
                {
                    expression = "'DIAMOND' call BIS_HC_path_menu";
                };
                title = "<img color='#e5e500' image='\A3\3den\data\Attributes\Formation\diamond_ca.paa'/><t> Diamond</t>";
                shortcutsAction = "CommandingMenu9";
                command = -5;
                show = "";
                enable = "HCNotEmpty";
            };
        };
        title = "Formation";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };
    class RscHCTeam
    {
        class items
        {
            class AssignRed
            {
                title="Get in Vehicle as Cargo";
                shortcuts[]={2};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_getIn_vehicle";
                };
                show="0";
                enable="HCNotEmpty";
                speechId=0;
            };
            class AssignGreen
            {
                title="Get Out Vehicle";
                shortcuts[]={3};
                submenu="";
                command=-5;
                class params
                {
                    expression="[hcSelected player select 0] spawn pl_getOut_vehicle";
                };
                show="0";
                enable="HCNotEmpty";
                speechId=0;
            };
            class AssignBlue
            {
                title="Clear Area/Buildings";
                shortcuts[]={4};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_sweep_area} forEach (hcSelected player)";
                };
                show="0";
                enable="0";
                speechId=0;
            };
            class AssignYellow
            {
                title="Garrison Building";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_building_garrison";
                };
                show="0";
                enable="0";
                speechId=0;
            };
            class AssignMain
            {
                shortcuts[] = {6};
                title = "Assign White";
                shortcutsAction = "CommandingMenu5";
                command = "CMD_ASSIGN_MAIN";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class SelectTeam
            {
                shortcuts[] = {10};
                title = "Team";
                shortcutsAction = "CommandingMenu9";
                menu = "0";
                show = "0";
            };
            class PlGetInVic
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\truck_ca.paa'/><t> Load / Extraction</t";
                shortcuts[]={2};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_getIn_vehicle";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlGetOutVic
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\land_ca.paa'/><t> Unload / Insertion</t";
                shortcuts[]={3};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_spawn_getOut_vehicle";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlGetOutVicAtPos
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Unload at current Pos</t";
                shortcuts[]={4};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] spawn pl_unload_at_position_planed} forEach (hcSelected player);";
                };
                show="1";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator15
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlCrewVehicle
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\car_ca.paa'/><t> Crew Vehicle</t";
                shortcuts[]={5};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] spawn pl_crew_vehicle";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlLeaveVehicle
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\getout_ca.paa'/><t> Leave Vehicle</t";
                shortcuts[]={6};
                submenu="";
                command=-5;
                class params
                {
                    expression="[] call pl_spawn_leave_vehicle";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator46
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlmoveInConvoy
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\navigate_ca.paa'/><t> Move as Convoy</t";
                shortcuts[]={7};
                submenu="";
                command=-5;
                class params
                {
                    expression="[true] call pl_spawn_getOut_vehicle";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlSeperator47
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };

            class PlSeperator201
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };

            class PlReverseVic
            {
                title="Reverse Vehicle Direction";
                shortcuts[]={10};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] call pl_ch_vehicle_dir} forEach (hcSelected player)";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            class PlUnstuckVic
            {
                title="Unstuck Vehicle/Group";
                shortcuts[]={11};
                submenu="";
                command=-5;
                class params
                {
                    expression="{[_x] call pl_vehicle_unstuck;} forEach (hcSelected player);";
                };
                show="HCIsLeader";
                enable="HCNotEmpty";
                speechId=0;
            };
            // class PlResetVic
            // {
            //     title="Reset Vehicle";
            //     shortcuts[]={11};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="{[_x] call pl_vehicle_reset} forEach (hcSelected player)";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Transport";
        vocabulary = "";
    };
    class RscHCSelectTeam
    {
        class items
        {
            class TeamRed
            {
                shortcuts[] = {2};
                title = "Red";
                shortcutsAction = "CommandingMenu1";
                command = "CMD_TEAM_RED";
                show = "IsLeader";
                enable = "NotEmptyRedTeam";
            };
            class TeamGreen
            {
                shortcuts[] = {3};
                title = "Green";
                shortcutsAction = "CommandingMenu2";
                command = "CMD_TEAM_GREEN";
                show = "IsLeader";
                enable = "NotEmptyGreenTeam";
            };
            class TeamBlue
            {
                shortcuts[] = {4};
                title = "Blue";
                shortcutsAction = "CommandingMenu3";
                command = "CMD_TEAM_BLUE";
                show = "IsLeader";
                enable = "NotEmptyBlueTeam";
            };
            class TeamYellow
            {
                shortcuts[] = {5};
                title = "Yellow";
                shortcutsAction = "CommandingMenu4";
                command = "CMD_TEAM_YELLOW";
                show = "IsLeader";
                enable = "NotEmptyYellowTeam";
            };
            class TeamMain
            {
                shortcuts[] = {6};
                title = "White";
                shortcutsAction = "CommandingMenu5";
                command = "CMD_TEAM_MAIN";
                show = "IsLeader";
                enable = "NotEmptyMainTeam";
            };
        };
        title = "Team";
        vocabulary = "";
    };
    class RscHCReply
    {
        class items
        {
            class SITREP
            {
                shortcuts[]={2};
                class Params
                {
                    expression = "[] call pl_spawn_sitrep";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa'/><t> SITREP</t";
                shortcutsAction = "CommandingMenu1";
                show = "HCIsLeader";
                enable = "HCNotEmpty";
                speechId = 0;
                command = -5;
            };
            class Communication
            {
                shortcuts[]={3};
                title = "Supports";
                shortcutsAction = "CommandingMenu2";
                menu = "#User:BIS_MENU_GroupCommunication";
            };
            // PL Support
            class UserRadio
            {
                shortcuts[]={4};
                title = "Custom";
                shortcutsAction = "CommandingMenu3";
                menu = "#CUSTOM_RADIO";
                show = "0"
            };
            class Radio
            {
                shortcuts[]={4};
                title = "Radio";
                shortcutsAction = "CommandingMenu3";
                menu = "RscRadio";
                enable = "HasRadio";
            };
            class PlSeperator8
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            class PlContacts
            {
                shortcuts[]={5};
                class Params
                {
                    expression = "[] call pl_player_report";
                };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\radio_ca.paa'/><t> Report own Contacts</t";
                shortcutsAction = "CommandingMenu4";
                show = "HCIsLeader";
                enable = "1";
                speechId = 0;
                command = -5;
            };
            class PlSeperator12
            {
                title="";
                shortcuts[]={};
                submenu="";
                command=-1;
                class params
                {
                    expression="";
                };
                show="1";
                enable="1";
                speechId=0;
            };
            // class PlJoinGroup
            // {
            //     title="Join Group";
            //     shortcuts[]={6};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[hcSelected player select 0] spawn pl_join_hc_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            class PlGroupManagement
            {
                title="<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\meet_ca.paa'/><t> Group Management</t";
                shortcuts[]={6};
                menu="#USER:pl_group_management";
                command=-5;
                class params
                {
                    expression="";
                };
                show="HCIsLeader";
                enable="1";
                speechId=0;
            };
            // class PlSplitGroups
            // {
            //     title="Split Group";
            //     shortcuts[]={7};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[hcSelected player select 0] spawn pl_split_hc_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator13
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlAddGroup
            // {
            //     title="Add Group";
            //     shortcuts[]={8};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_add_to_hc";
            //     };
            //     show="HCIsLeader";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlRemoveGroup
            // {
            //     title="Remove Group";
            //     shortcuts[]={9};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[] spawn pl_spawn_remove_hc";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator18
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlChangeIconGroup
            // {
            //     title="Change Group Marker";
            //     shortcuts[]={10};
            //     menu="#USER:pl_change_icon_menu";
            //     command=-5;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
            // class PlSeperator303
            // {
            //     title="";
            //     shortcuts[]={};
            //     submenu="";
            //     command=-1;
            //     class params
            //     {
            //         expression="";
            //     };
            //     show="1";
            //     enable="1";
            //     speechId=0;
            // };
            // class PlResetGroup
            // {
            //     title="Reset Group";
            //     shortcuts[]={11};
            //     submenu="";
            //     command=-5;
            //     class params
            //     {
            //         expression="[(hcSelected player) select 0] spawn pl_reset_group";
            //     };
            //     show="HCIsLeader";
            //     enable="HCNotEmpty";
            //     speechId=0;
            // };
        };
        title = "Reply";
        access = 0;
        atomic = 0;
        vocabulary = "";
    };

class RscHCWPRootMenu
    {
        class Items
        {
            class Type
            {
                shortcuts[] = {1};
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\move_ca.paa'/><t> Type</t>";
                shortcutsAction = "CommandingMenu1";
                menu = "RscHCWPType";
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class CombatMode
            {
                shortcuts[] = {3};
                title = "Combat Mode";
                shortcutsAction = "CommandingMenu2";
                menu = "RscHCWPCombatMode";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Formations
            {
                shortcuts[] = {4};
                title = "Formation";
                shortcutsAction = "CommandingMenu3";
                menu = "RscHCWPFormations";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Speed
            {
                shortcuts[] = {5};
                title = "Speed";
                shortcutsAction = "CommandingMenu4";
                menu = "RscHCWPSpeedMode";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Wait
            {
                shortcuts[] = {6};
                title = "Timeout";
                shortcutsAction = "CommandingMenu5";
                menu = "RscHCWPWait";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class WaitUntil
            {
                shortcuts[] = {7};
                title = "Wait until";
                shortcutsAction = "CommandingMenu6";
                menu = "#USER:HCWPWaitUntil";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class WaitRadio
            {
                shortcuts[] = {8};
                title = "Radio";
                shortcutsAction = "CommandingMenu7";
                menu = "#USER:HCWPWaitRadio";
                show = "0";
                enable = "0";
                speechId = 0;
            };
            class Separator1
            {
                shortcuts[] = {0};
                title = "";
                command = -1;
            };
            class CreateTask
            {
                shortcuts[] = {2};
                // class Params
                // {
                //     expression = "[] call pl_get_task_plan_wp";
                // };
                title = "<img color='#e5e500' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Plan Task</t>";
                shortcutsAction = "CommandingMenu2";
                menu = "#USER:pl_task_plan_menu"
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class CancleTask
            {
                shortcuts[] = {4};
                class Params
                {
                    expression = "[] call pl_cancel_planed_task";
                };
                title = "<img color='#b20000' image='\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa'/><t> Cancel Planed Task</t>";
                shortcutsAction = "CommandingMenu4";
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            class Separator200
            {
                shortcuts[] = {0};
                title = "";
                command = -1;
            };
            class CancelWP
            {
                shortcuts[] = {3};
                class Params
                {
                    expression = "[] call pl_cancel_planed_task; 'WP_CANCELWP' call BIS_HC_path_menu";
                };
                title = "<img color='#b20000' image='\A3\3den\data\Attributes\default_ca.paa'/><t> Cancel Waypoint</t>";
                shortcutsAction = "CommandingMenu3";
                command = -5;
                show = "1";
                enable = "1";
                speechId = 0;
            };
            // class Back
            // {
            //     shortcuts[] = {14};
            //     shortcutsAction = "NavigateMenu";
            //     title = "";
            //     command = -4;
            //     speechId = 0;
            // };
        };
        access = 0;
        title = "";
        atomic = 0;
        vocabulary = "";
    };

class CfgMarkerClasses
{
    class Check_point_1
    {
        displayName="PL Markers";
    };
};
class CfgMarkers
{
    class pl_marker
    {
        name="Check Point";
        icon="\Plmod\gfx\CP.paa";
        color[]={0,0,0,1};
        size=48;
        scope=2;
        scopeCurator=2;
        shadow=0;
        markerClass="Check_point_1";
    };
    class marker_CCP: pl_marker
    {
        name="CCP";
        icon="\Plmod\gfx\CCP.paa";
        texture="\Plmod\gfx\CCP.paa";
    };
    class marker_afp: pl_marker
    {
        name="Attack by Fire Position";
        icon="\Plmod\gfx\AFP.paa";
        texture="\Plmod\gfx\AFP.paa";
    };
    class marker_sfp: pl_marker
    {
        name="Support by Fire Position";
        icon="\Plmod\gfx\SFP.paa";
        texture="\Plmod\gfx\SFP.paa";
    };
    class marker_eng: pl_marker
    {
        name="NATO Engineer";
        icon="\Plmod\gfx\b_engineer.paa";
        texture="\Plmod\gfx\b_engineer.paa";
    };
    class marker_at: pl_marker
    {
        name="NATO AT";
        icon="\Plmod\gfx\b_antiarmor.paa";
        texture="\Plmod\gfx\b_antiarmor.paa";
    };
};
class RscSubmenu;
class RscMenuStatus: RscSubmenu
{
    class Items
    {
        class Pl_Status_Separator1
        {
            title="";
            shortcuts[]={};
            submenu="";
            command=-1;
            class params
            {
                expression="";
            };
            show="1";
            enable="1";
            speechId=0;
        };
        class Pl_Status_CreateHCGroup
        {
            title="Create HC Group";
            shortcuts[]={10};
            submenu="";
            command=-5;
            class params
            {
                expression="[] call pl_create_hc_group";
            };
            show="1";
            enable="NotEmpty";
            speechId=0;
        };
    };
};


class RscMapControl {
    access = 1;
    alphaFadeEndScale = 0.4;
    alphaFadeStartScale = 0.35;
    colorBackground[] = {0.969,0.957,0.949,1};
    colorCountlines[] = {0.572,0.354,0.188,0.25};
    colorCountlinesWater[] = {0.491,0.577,0.702,0.3};
    colorForest[] = {0.624,0.78,0.388,0.5};
    colorForestBorder[] = {0,0,0,0};
    colorGrid[] = {0.1,0.1,0.1,0.6};
    colorGridMap[] = {0.1,0.1,0.1,0.6};
    colorInactive[] = {1,1,1,0.5};
    colorLevels[] = {0.286,0.177,0.094,0.5};
    colorMainCountlines[] = {0.572,0.354,0.188,0.5};
    colorMainCountlinesWater[] = {0.491,0.577,0.702,0.6};
    colorMainRoads[] = {0.9,0.5,0.3,1};
    colorMainRoadsFill[] = {1,0.6,0.4,1};
    colorNames[] = {0.1,0.1,0.1,0.9};
    colorOutside[] = {0,0,0,1};
    colorPowerLines[] = {0.1,0.1,0.1,1};
    colorRailWay[] = {0.8,0.2,0,1};
    colorRoads[] = {0.7,0.7,0.7,1};
    colorRoadsFill[] = {1,1,1,1};
    colorRocks[] = {0,0,0,0.3};
    colorRocksBorder[] = {0,0,0,0};
    colorSea[] = {0.467,0.631,0.851,0.5};
    colorText[] = {0,0,0,1};
    colorTracks[] = {0.84,0.76,0.65,0.15};
    colorTracksFill[] = {0.84,0.76,0.65,1};
    font = "TahomaB";
    fontGrid = "TahomaB";
    fontInfo = "PuristaMedium";
    fontLabel = "PuristaMedium";
    fontLevel = "TahomaB";
    fontNames = "PuristaMedium";
    fontUnits = "TahomaB";
    h = "SafeZoneH - 1.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
    maxSatelliteAlpha = 0.45;
    moveOnEdges = 0;
    ptsPerSquareCLn = 10;
    ptsPerSquareCost = 10;
    ptsPerSquareExp = 10;
    ptsPerSquareFor = 9;
    ptsPerSquareForEdge = 9;
    ptsPerSquareObj = 9;
    ptsPerSquareRoad = 6;
    ptsPerSquareSea = 5;
    ptsPerSquareTxt = 3;
    scaleDefault = 0.16;
    scaleMax = 1;
    scaleMin = 0.001;
    shadow = 0;
    showCountourInterval = 0;
    sizeEx = "(         (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
    sizeExGrid = 0.02;
    sizeExInfo = "(         (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    sizeExLabel = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    sizeExLevel = 0.02;
    sizeExNames = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8) * 2";
    sizeExUnits = "(            (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
    stickX[] = {0.2,["Gamma",1,1.5]};
    stickY[] = {0.2,["Gamma",1,1.5]};
    style = 48;
    text = "#(argb,8,8,3)color(1,1,1,1)";
    type = 101;
    w = "SafeZoneWAbs";
    x = "SafeZoneXAbs";
    y = "SafeZoneY + 1.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
    class ActiveMarker
        {
        color[] = {0.3,0.1,0.9,1};
        size = 50;
        };
    class Bunker
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        importance = "1.5 * 14 * 0.05";
        size = 14;
        };
    class Bush
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0.45,0.64,0.33,0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        importance = "0.2 * 14 * 0.05 * 0.05";
        size = "14/2";
        };
    class BusStop
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\busstop_CA.paa";
        importance = 1;
        size = 24;
        };
    class Chapel
        {
        coefMax = 4;
        coefMin = 0.85;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\Chapel_CA.paa";
        importance = 1;
        size = 24;
        };
    class Church
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\church_CA.paa";
        importance = 1;
        size = 24;
        };
    class Command
        {
        coefMax = 1;
        coefMin = 1;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
        importance =1;
        size = 18;
        };
    class Cross
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\Cross_CA.paa";
        importance = 1;
        size = 24;
        };
    class CustomMark
        {
        coefMax = 1;
        coefMin = 1;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\custommark_ca.paa";
        importance = 1;
        size = 24;
        };
    class Fortress
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\bunker_ca.paa";
        importance = "2 * 16 * 0.05";
        size = 16;
        };
    class Fountain
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\fountain_ca.paa";
        importance = "1 * 12 * 0.05";
        size = 11;
        };
    class Fuelstation
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\fuelstation_CA.paa";
        importance = 1;
        size = 24;
        };
    class Hospital
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\hospital_CA.paa";
        importance = 1;
        size = 24;
        };
    class Legend
        {
        color[] = {0,0,0,1};
        colorBackground[] = {1,1,1,0.5};
        font = "PuristaMedium";
        h = "3.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
        sizeEx = "(         (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 0.8)";
        w = "10 *                   (           ((safezoneW / safezoneH) min 1.2) / 40)";
        x = "SafeZoneX +                    (           ((safezoneW / safezoneH) min 1.2) / 40)";
        y = "SafeZoneY + safezoneH - 4.5 *                  (           (           ((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
        };
    class Lighthouse
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\lighthouse_CA.paa";
        importance = 1;
        size = 24;
        };
    class power
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\power_CA.paa";
        importance = 1;
        size = 24;
        };
    class powersolar
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\powersolar_CA.paa";
        importance = 1;
        size = 24;
        };
    class powerwind
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\powerwind_CA.paa";
        importance = 1;
        size = 24;
        };
    class powerwave
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\powerwave_CA.paa";
        importance = 1;
        size = 24;
        };
    class Quay
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\quay_CA.paa";
        importance = 1;
        size = 24;
        };
    class Rock
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0.1,0.1,0.1,0.8};
        icon = "\A3\ui_f\data\map\mapcontrol\rock_ca.paa";
        importance = "0.5 * 12 * 0.05";
        size = 12;
        };
    class Ruin
        {
        coefMax = 4;
        coefMin = 1;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\ruin_ca.paa";
        importance = "1.2 * 16 * 0.05";
        size = 16;
        };
    class shipwreck
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\shipwreck_CA.paa";
        importance = 1;
        size = 24;
        };
    class SmallTree
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0.45,0.64,0.33,0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        importance = "0.6 * 12 * 0.05";
        size = 12;
        };
    class Stack
        {
        coefMax = 4;
        coefMin = 0.9;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\stack_ca.paa";
        importance = "2 * 16 * 0.05";
        size = 20;
        };
    class LineMarker
        {
            lineWidthThin = 0.008;
            lineWidthThick = 0.014;
            lineDistanceMin = 3e-005;
            lineLengthMin = 5;
        };
    class Task
        {
        coefMax = 1;
        coefMin = 1;
        color[] = {"(profilenamespace getvariable ['IGUI_TEXT_RGB_R',0])","(profilenamespace getvariable ['IGUI_TEXT_RGB_G',1])","(profilenamespace getvariable ['IGUI_TEXT_RGB_B',1])","(profilenamespace getvariable ['IGUI_TEXT_RGB_A',0.8])"};
        colorCanceled[] = {0.7,0.7,0.7,1};
        colorCreated[] = {1,1,1,1};
        colorDone[] = {0.7,1,0.3,1};
        colorFailed[] = {1,0.3,0.2,1};
        icon = "\A3\ui_f\data\map\mapcontrol\taskIcon_CA.paa";
        iconCanceled = "\A3\ui_f\data\map\mapcontrol\taskIconCanceled_CA.paa";
        iconCreated = "\A3\ui_f\data\map\mapcontrol\taskIconCreated_CA.paa";
        iconDone = "\A3\ui_f\data\map\mapcontrol\taskIconDone_CA.paa";
        iconFailed = "\A3\ui_f\data\map\mapcontrol\taskIconFailed_CA.paa";
        importance = 1;
        size = 27;
        };
    class Tourism
        {
        coefMax = 4;
        coefMin = 0.7;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\tourism_ca.paa";
        importance = "1 * 16 * 0.05";
        size = 16;
        };
    class Transmitter
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\transmitter_CA.paa";
        importance = 1;
        size = 24;
        };
    class Tree
        {
        coefMax = 4;
        coefMin = 0.25;
        color[] = {0.45,0.64,0.33,0.4};
        icon = "\A3\ui_f\data\map\mapcontrol\bush_ca.paa";
        importance = "0.9 * 16 * 0.05";
        size = 12;
        };
    class ViewTower
        {
        coefMax = 4;
        coefMin = 0.5;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\viewtower_ca.paa";
        importance = "2.5 * 16 * 0.05";
        size = 16;
        };
    class Watertower
        {
        coefMax = 1;
        coefMin = 0.85;
        color[] = {1,1,1,1};
        icon = "\A3\ui_f\data\map\mapcontrol\watertower_CA.paa";
        importance = 1;
        size = 24;
        };
    class Waypoint
        {
        coefMax = 1;
        coefMin = 1;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\waypoint_ca.paa";
        importance = 1;
        size = 24;
        };
    class WaypointCompleted
        {
        coefMax = 1;
        coefMin = 1;
        color[] = {0,0,0,1};
        icon = "\A3\ui_f\data\map\mapcontrol\waypointCompleted_ca.paa";
        importance = 1;
        size = 24;
        };

};


// class CfgGroups
// {
//     class Empty
//     {
//         class Plmod
//         {
//             name = "Platoon Leader";
//             class fortifications // Catégorie de classement (possible d'en ajouter d'autres)
//             {
//                 name = "Dortifications"; // Nom de la catégorie  
//                 class Raodblock
//                 {
//                     name = "Raodblock";
//                     side = 8;
//                     icon = "\a3\Ui_f\data\Map\VehicleIcons\iconVehicle_ca.paa";
//                     class Object0  {side = 8; vehicle = ""Land_Razorwire_F""; rank = """"; position[] = {-1.69824,0.341309,0.00115967}; dir = 9.0426;};
//                     class Object1  {side = 8; vehicle = ""Land_BagFence_Long_F""; rank = """"; position[] = {-1.69727,-1.35352,6.10352e-005}; dir = 6.1329;};
//                     class Object2  {side = 8; vehicle = ""Land_BagFence_Long_F""; rank = """"; position[] = {1.25488,-1.63037,7.62939e-005}; dir = 6.1329;};
                    
//                 };
//             };
//         };
//     };
// };





