// dyn_standart_squad = configFile >> "CfgGroups" >> "East" >> "CWR3_RUS" >> "Infantry" >> "cwr3_o_rifle_squad";
dyn_standart_squad_1 = configfile >> "CfgGroups" >> "East" >> "VN_VC" >> "vn_o_group_men_vc" >> "vn_o_group_men_vc_01";
dyn_standart_squad_2 = configFile >> "CfgGroups" >> "East" >> "VN_VC" >> "vn_o_group_men_vc" >> "vn_o_group_men_vc_02";
dyn_standart_squad_3 = configFile >> "CfgGroups" >> "East" >> "VN_VC" >> "vn_o_group_men_vc_local" >> "vn_o_group_men_vc_local_01";
dyn_standart_squad_4 = configFile >> "CfgGroups" >> "East" >> "VN_VC" >> "vn_o_group_men_vc_local" >> "vn_o_group_men_vc_local_02";
dyn_small_squad = configfile >> "CfgGroups" >> "East" >> "VN_VC" >> "vn_o_group_men_vc" >> "vn_o_group_men_vc_04";
dyn_standart_squads = [dyn_standart_squad_1, dyn_standart_squad_2, dyn_standart_squad_3, dyn_standart_squad_4];
dyn_standart_soldier = "vn_o_men_vc_06";
dyn_standart_trasnport_vehicles = ["vn_o_wheeled_z157_02_vcmf", "vn_o_wheeled_z157_01_vcmf"];
dyn_standart_combat_vehicles = ["vn_o_wheeled_btr40_mg_01_vcmf", "vn_o_wheeled_btr40_mg_02_vcmf"];

dyn_map_center = [worldSize / 2, worldsize / 2, 0];

dyn_debug = false;

execVM "dyn_viet_ai_functions.sqf";
execVM "dyn_viet_spawn_functions.sqf";
execVM "dyn_viet_obj_functions.sqf";
execVM "dyn_viet_setup_functions.sqf";

dyn_static_grps = [art_0, art_1, art_2, inf_0, inf_1, inf_2, inf_3];
{
	_grp = _x;
	{
		_x disableAI "Path";
	} forEach (units _grp);
} forEach dyn_static_grps;

sleep 5;

{
	[_x] call pl_hide_group_icon;
	sleep 0.2;
} forEach dyn_static_grps;

// "CUP_B_A10_DYN_USA"
pl_cas_Heli_1 = "cwr3_b_ah64";
pl_medevac_Heli_1 = "cwr3_b_uh1_mev";
pl_cas_plane_1 = "RHS_A10";
pl_cas_plane_2 = "RHS_A10";
pl_cas_plane_3 = "RHS_A10";
