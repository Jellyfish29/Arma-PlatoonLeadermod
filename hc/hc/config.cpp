class CfgPatches
{
	class A3_Modules_F_Hc
	{
		addonRootClass="A3_Modules_F";
		requiredAddons[]=
		{
			"A3_Modules_F"
		};
		requiredVersion=0.1;
		units[]=
		{
			"HighCommand",
			"HighCommandSubordinate"
		};
		weapons[]={};
	};
};
class CfgVehicles
{
	class Logic;
	class Module_F: Logic
	{
		class ArgumentsBaseUnits
		{
			class Units;
		};
		class ModuleDescription
		{
			class AnyBrain;
		};
	};
	class Pl_HighCommand: Module_F
	{
		author="$STR_A3_Bohemia_Interactive";
		_generalMacro="PlHighCommand";
		scope=2;
		displayName="Pl HC Commander";
		icon="\A3\modules_f\data\icon_HC_ca.paa";
		class EventHandlers
		{
			init="if (isServer) then {if (isnil 'BIS_HC_mainscope') then {BIS_HC_mainscope = _this select 0; publicvariable 'bis_hc_mainscope'}; _ok = _this execVM 'hc\HC\data\scripts\hc.sqf'};";
		};
		class ModuleDescription: ModuleDescription
		{
			description="$STR_A3_CfgVehicles_HighCommand_ModuleDescription_0";
			sync[]=
			{
				"HighCommandSubordinate",
				"AnyBrain"
			};
			class AnyBrain: AnyBrain
			{
				description="$STR_A3_CfgVehicles_HighCommand_ModuleDescription_AnyBrain_0";
			};
			class HighCommandSubordinate
			{
				duplicate=1;
			};
		};
	};
	class Pl_HighCommandSubordinate: Pl_HighCommand
	{
		author="$STR_A3_Bohemia_Interactive";
		_generalMacro="PlHighCommandSubordinate";
		displayName="Pl HC Subordinate";
		icon="\A3\modules_f\data\icon_HC_sub_ca.paa";
		class EventHandlers
		{
			init="";
		};
		class ModuleDescription: ModuleDescription
		{
			description="$STR_A3_CfgVehicles_HighCommandSubordinate_ModuleDescription_0";
			duplicate=1;
			sync[]=
			{
				"HighCommand",
				"AnyBrain"
			};
			class AnyBrain: AnyBrain
			{
				description="$STR_A3_CfgVehicles_HighCommandSubordinate_ModuleDescription_AnyBrain_0";
				duplicate=1;
			};
			class HighCommand
			{
			};
		};
	};
};
