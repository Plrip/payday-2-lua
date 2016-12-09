if MenuNodeGui then
	MenuNodeWeaponCosmeticsGui = MenuNodeWeaponCosmeticsGui or class(MenuNodeGui)
	function MenuNodeWeaponCosmeticsGui:init(node, layer, parameters)
		parameters.font = tweak_data.menu.pd2_small_font
		parameters.font_size = tweak_data.menu.pd2_small_font_size
		parameters.row_item_blend_mode = "add"
		parameters.row_item_color = tweak_data.screen_colors.button_stage_3
		parameters.row_item_hightlight_color = tweak_data.screen_colors.button_stage_2
		parameters.marker_alpha = 1
		parameters.to_upper = true
		MenuNodeWeaponCosmeticsGui.super.init(self, node, layer, parameters)
	end
	function MenuNodeWeaponCosmeticsGui:mouse_pressed(button, x, y)
		if button == Idstring("1") then
			local row_item = self._highlighted_item and self:row_item(self._highlighted_item)
			if row_item and row_item.gui_panel and row_item.gui_panel:inside(x, y) then
				local key = self._highlighted_item:parameters().key or self._highlighted_item:name()
				local vector = self._highlighted_item:parameters().vector
				if key == "pattern_tweak" then
					self._highlighted_item:set_value(vector == 2 and 0 or 1)
				elseif key == "pattern_pos" then
					self._highlighted_item:set_value(0)
				elseif key == "wear_and_tear" then
					self._highlighted_item:set_value(1)
				elseif key == "uv_scale" then
					self._highlighted_item:set_value(1)
				elseif key == "uv_offset_rot" then
					self._highlighted_item:set_value(0)
				elseif key == "cubemap_pattern_control" then
					self._highlighted_item:set_value(0)
				else
					return
				end
				MenuCallbackHandler:update_weapon_skin(self._highlighted_item)
			end
		end
	end
end
if MenuManager then
	core:import("CoreMenuData")
	core:import("CoreMenuLogic")
	core:import("CoreMenuInput")
	core:import("CoreMenuRenderer")
	do
		local old_init = MenuManager.init
		function MenuManager:init(is_start_menu)
			old_init(self, is_start_menu)
			if self._registered_menus.menu_main then
				local c = ScriptSerializer:from_custom_xml([[
			
			<node name="debug_shiny" sync_state="blackmarket" scene_state="blackmarket_customize" gui_class="MenuNodeWeaponCosmeticsGui" menu_components="" topic_id="menu_crimenet" modifier="MenuCustomizeWeaponInitiator" align_line_proportions="0.65">
				<legend name="menu_legend_manual_switch_page"/>
				<legend name="menu_legend_select"/>
				<legend name="menu_legend_back"/>
				
				<default_item name="back"/>
			</node>
			]])
				local type = c._meta
				if type == "node" then
					local node_class = CoreMenuNode.MenuNode
					local type = c.type
					if type then
						node_class = CoreSerialize.string_to_classtable(type)
					end
					local name = c.name
					if name then
						local node = node_class:new(c)
						node:set_callback_handler(self._registered_menus.menu_main.callback_handler)
						self._registered_menus.menu_main.data._nodes[name] = node
					else
						Application:error("Menu node without name in '" .. menu_id .. "' in '" .. file_path .. "'")
					end
				elseif type == "default_node" then
					self._default_node_name = c.name
				end
			end
		end
		MenuCustomizeWeaponInitiator = MenuCustomizeWeaponInitiator or class(MenuInitiatorBase)
		function MenuCustomizeWeaponInitiator:modify_node(original_node, data)
			local node = deep_clone(original_node)
			node:clean_items()
			if not node:item("divider_end") then
				if not data.menu then
					if data.slot and data.category then
						local crafted = managers.blackmarket:get_crafted_category_slot(data.category, data.slot)
						local old_cosmetics_data = Global.shiny_debug and Global.shiny_debug.cosmetics_data
						Global.shiny_debug = {
							slot = data.slot,
							category = data.category,
							weapon_unit = managers.menu_scene._item_unit.unit,
							second_weapon_unit = managers.menu_scene._item_unit.second_unit
						}
						local new_cosmetics_data = old_cosmetics_data and old_cosmetics_data.weapon_id == crafted.weapon_id and old_cosmetics_data or {
							weapon_id = crafted.weapon_id,
							wear_and_tear = 1,
							parts = {}
						}
						Global.shiny_debug.weapon_unit:base()._cosmetics_data = new_cosmetics_data
						Global.shiny_debug.cosmetics_data = Global.shiny_debug.weapon_unit:base()._cosmetics_data
						Global.shiny_debug.weapon_unit:base():_apply_cosmetics(function()
						end)
						if Global.shiny_debug.second_weapon_unit then
							Global.shiny_debug.second_weapon_unit:base()._cosmetics_data = new_cosmetics_data
							Global.shiny_debug.second_weapon_unit:base():_apply_cosmetics(function()
							end)
						end
					end
					self:create_item(node, {
						enabled = true,
						name = "default_skin",
						text_id = "debug_wskn_base_skin",
						next_node = "debug_shiny",
						next_node_parameters = {
							{
								menu = "weapon_skin"
							}
						}
					})
					self:create_item(node, {
						enabled = true,
						name = "create_types_menu",
						text_id = "debug_wskn_types",
						next_node = "debug_shiny",
						next_node_parameters = {
							{menu = "types_menu"}
						}
					})
					self:create_item(node, {
						enabled = true,
						name = "create_parts_menu",
						text_id = "debug_wskn_parts",
						next_node = "debug_shiny",
						next_node_parameters = {
							{menu = "parts_menu"}
						}
					})
					self:create_divider(node, 1)
					self:create_item(node, {
						enabled = true,
						name = "edit_skin",
						text_id = "debug_wskn_edit_skin",
						next_node = "debug_shiny",
						next_node_parameters = {
							{
								menu = "edit_skin_menu"
							}
						}
					})
					self:create_item(node, {
						enabled = true,
						name = "clear_skin",
						text_id = "debug_wskn_clear_skin",
						callback = "clear_debug_weapon_skin"
					})
					self:create_divider(node, 1)
					do
						local name_input = self:create_input(node, {
							text_id = "debug_wskn_name_input",
							name = "name_input",
							enabled = true,
							crafted_data = Global.shiny_debug,
							part_id = data.part_id,
							material_name = data.material_name
						})
						local tbf_input = self:create_input(node, {
							text_id = "debug_wskn_tbf_input",
							name = "tbf_input",
							enabled = true,
							crafted_data = Global.shiny_debug,
							part_id = data.part_id,
							material_name = data.material_name
						})
						local rarities = tweak_data.economy.rarities
						local sort_list = {}
						for id in pairs(rarities) do
							table.insert(sort_list, id)
						end
						table.sort(sort_list, function(x, y)
							return rarities[x].index < rarities[y].index
						end)
						local multichoice_list = {}
						for _, id in ipairs(sort_list) do
							table.insert(multichoice_list, {
								_meta = "option",
								localize = false,
								text_id = id,
								value = id
							})
						end
						local rarity_input = self:create_multichoice(node, multichoice_list, {
							text_id = "debug_wskn_rarity",
							text_offset = 100,
							name = "rarity_input",
							enabled = true,
							crafted_data = Global.shiny_debug,
							part_id = data.part_id,
							material_name = data.material_name
						})
						local bonuses = tweak_data.economy.bonuses
						local sort_list = {}
						for id in pairs(bonuses) do
							table.insert(sort_list, id)
						end
						table.sort(sort_list)
						local multichoice_list = {}
						for _, id in ipairs(sort_list) do
							table.insert(multichoice_list, {
								_meta = "option",
								localize = false,
								text_id = id,
								value = id
							})
						end
						local bonus_input = self:create_multichoice(node, multichoice_list, {
							text_id = "debug_wskn_bonus",
							text_offset = 100,
							name = "bonus_input",
							enabled = true,
							crafted_data = Global.shiny_debug,
							part_id = data.part_id,
							material_name = data.material_name
						})
						local default_blueprint_toggle = self:create_toggle(node, {
							text_id = "debug_wskn_blueprint",
							name = "default_blueprint",
							enabled = true,
							crafted_data = Global.shiny_debug,
							part_id = data.part_id,
							material_name = data.material_name
						})
						name_input:set_input_text(Global.shiny_debug.cosmetics_data.id or "")
						tbf_input:set_input_text(Global.shiny_debug.cosmetics_data.tbf or "")
						bonus_input:set_value(Global.shiny_debug.cosmetics_data.bonus or bonuses[1])
						rarity_input:set_value(Global.shiny_debug.cosmetics_data.rarity or rarities[1])
						default_blueprint_toggle:set_value(Global.shiny_debug.cosmetics_data.default_blueprint and "on" or "off")
						self:create_divider(node, "copy")
						self:create_item(node, {
							enabled = true,
							name = "copy_skin",
							text_id = "debug_wskn_save_skin",
							callback = "copy_weapon_customize"
						})
					end
				elseif data.menu == "edit_skin_menu" then
					local cosmetics = managers.blackmarket:get_cosmetics_by_weapon_id(Global.shiny_debug.cosmetics_data.weapon_id) or {}
					local sort_data = {}
					for id, data in pairs(cosmetics) do
						table.insert(sort_data, id)
					end
					table.sort(sort_data)
					local default_item
					for _, id in ipairs(sort_data) do
						self:create_item(node, {
							enabled = true,
							name = id,
							text_id = tweak_data.blackmarket.weapon_skins[id].name_id,
							callback = "edit_weapon_customize"
						})
						default_item = default_item or id
					end
					node:set_default_item_name(default_item)
					node:select_item(default_item)
				elseif data.menu == "parts_menu" then
					local default_item
					for part_id, materials in pairs(Global.shiny_debug.weapon_unit:base()._materials or {}) do
						self:create_item(node, {
							enabled = true,
							name = part_id,
							localize = false,
							text_id = (tweak_data.weapon.factory.parts[part_id] and managers.localization:text("bm_menu_" .. tweak_data.weapon.factory.parts[part_id].type) .. " - ") .. part_id,
							next_node = "debug_shiny",
							next_node_parameters = {
								{
									menu = "materials_menu",
									part_id = part_id
								}
							}
						})
						default_item = default_item or part_id
					end
					node:set_default_item_name(default_item)
					node:select_item(default_item)
				elseif data.menu == "types_menu" then
					local types = managers.weapon_factory._parts_by_type or {}
					local default_item
					local sort_types = {}
					for type, parts in pairs(types) do
						table.insert(sort_types, type)
					end
					table.sort(sort_types)
					for _, mod_type in ipairs(sort_types) do
						self:create_item(node, {
							enabled = true,
							name = mod_type,
							localize = false,
							text_id = managers.localization:text("bm_menu_" .. mod_type),
							next_node = "debug_shiny",
							next_node_parameters = {
								{
									menu = "weapon_skin",
									mod_type = mod_type
								}
							}
						})
						default_item = default_item or mod_type
					end
					node:set_default_item_name(default_item)
					node:select_item(default_item)
				elseif data.menu == "materials_menu" then
					local default_item
					local items_map = {}
					for _, material in pairs(Global.shiny_debug.weapon_unit:base()._materials[data.part_id] or {}) do
						if not items_map[material:name():key()] then
							self:create_item(node, {
								enabled = true,
								name = material:name():key(),
								localize = false,
								text_id = utf8.to_upper(material:name():s()),
								next_node = "debug_shiny",
								next_node_parameters = {
									{
										menu = "weapon_skin",
										part_id = data.part_id,
										material_name = material:name()
									}
								}
							})
							default_item = default_item or material:name():key()
							items_map[material:name():key()] = true
						end
					end
					node:set_default_item_name(default_item)
					node:select_item(default_item)
				elseif data.menu == "weapon_skin" then
					local cdata = Global.shiny_debug.cosmetics_data
					if data.part_id then
						cdata.parts = cdata.parts or {}
						cdata.parts[data.part_id] = cdata.parts[data.part_id] or {}
						if data.material_name then
							cdata.parts[data.part_id][data.material_name:key()] = cdata.parts[data.part_id][data.material_name:key()] or {}
							cdata = cdata.parts[data.part_id][data.material_name:key()]
						else
							cdata = cdata.parts[data.part_id]
						end
					elseif data.mod_type then
						cdata.types = cdata.types or {}
						cdata.types[data.mod_type] = cdata.types[data.mod_type] or {}
						cdata = cdata.types[data.mod_type]
					end
					local base_gradients = tweak_data.blackmarket.shiny_debug_tool.weapon_skins.BASE_GRADIENT
					local sort_list = {}
					for id in pairs(base_gradients) do
						table.insert(sort_list, id)
					end
					table.sort(sort_list)
					local base_gradient
					local multichoice_list = {
						{
							_meta = "option",
							localize = false,
							text_id = "DEFAULT",
							value = -1
						}
					}
					for _, id in ipairs(sort_list) do
						base_gradient = base_gradients[id]
						table.insert(multichoice_list, {
							_meta = "option",
							localize = false,
							text_id = id,
							value = Idstring(base_gradient)
						})
					end
					local base_gradient_item = self:create_multichoice(node, multichoice_list, {
						text_offset = 50,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_base_gradient",
						name = "base_gradient",
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					base_gradient_item:set_value(cdata.base_gradient)
					local pattern_gradients = tweak_data.blackmarket.shiny_debug_tool.weapon_skins.PATTERN_GRADIENT
					sort_list = {}
					for id in pairs(pattern_gradients) do
						table.insert(sort_list, id)
					end
					table.sort(sort_list)
					local pattern_gradient
					local multichoice_list = {
						{
							_meta = "option",
							localize = false,
							text_id = "DEFAULT",
							value = -1
						}
					}
					for _, id in ipairs(sort_list) do
						pattern_gradient = pattern_gradients[id]
						table.insert(multichoice_list, {
							_meta = "option",
							localize = false,
							text_id = id,
							value = Idstring(pattern_gradient)
						})
					end
					local pattern_gradient_item = self:create_multichoice(node, multichoice_list, {
						text_offset = 50,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_gradient",
						name = "pattern_gradient",
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_gradient_item:set_value(cdata.pattern_gradient)
					local patterns = tweak_data.blackmarket.shiny_debug_tool.weapon_skins.PATTERN
					sort_list = {}
					for id in pairs(patterns) do
						table.insert(sort_list, id)
					end
					table.sort(sort_list)
					local pattern
					local multichoice_list = {
						{
							_meta = "option",
							localize = false,
							text_id = "DEFAULT",
							value = -1
						}
					}
					for _, id in ipairs(sort_list) do
						pattern = patterns[id]
						table.insert(multichoice_list, {
							_meta = "option",
							localize = false,
							text_id = id,
							value = Idstring(pattern)
						})
					end
					local pattern_item = self:create_multichoice(node, multichoice_list, {
						text_offset = 50,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern",
						name = "pattern",
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_item:set_value(cdata.pattern)
					self:create_divider(node, "sliders")
					local wear_and_tear_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 1,
						step = 0.2,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_wear_and_tear",
						name = "wear_and_tear",
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					wear_and_tear_item:set_value(cdata.wear_and_tear or 1)
					local pattern_pos_x_item = self:create_slider(node, {
						show_value = true,
						min = -2,
						max = 2,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_pos_x",
						name = "pattern_pos1",
						key = "pattern_pos",
						vector = 1,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_pos_x_item:set_value(cdata.pattern_pos and mvector3.x(cdata.pattern_pos) or 0)
					local pattern_pos_y_item = self:create_slider(node, {
						show_value = true,
						min = -2,
						max = 2,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_pos_y",
						name = "pattern_pos2",
						key = "pattern_pos",
						vector = 2,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_pos_y_item:set_value(cdata.pattern_pos and mvector3.y(cdata.pattern_pos) or 0)
					local pattern_tweak_x_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 20,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_tweak_x",
						name = "pattern_tweak1",
						key = "pattern_tweak",
						vector = 1,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_tweak_x_item:set_value(cdata.pattern_tweak and mvector3.x(cdata.pattern_tweak) or 1)
					self:create_divider(node, 1)
					local pattern_tweak_y_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 2 * math.pi,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_tweak_y",
						name = "pattern_tweak2",
						key = "pattern_tweak",
						vector = 2,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_tweak_y_item:set_value(cdata.pattern_tweak and mvector3.y(cdata.pattern_tweak) or 0)
					local pattern_tweak_z_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 1,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_pattern_tweak_z",
						name = "pattern_tweak3",
						key = "pattern_tweak",
						vector = 3,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					pattern_tweak_z_item:set_value(cdata.pattern_tweak and mvector3.z(cdata.pattern_tweak) or 1)
					self:create_divider(node, 2)
					local cubemap_pattern_control_x_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 1,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_cubemap_pattern_control_x",
						name = "cubemap_pattern_control1",
						key = "cubemap_pattern_control",
						vector = 1,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					cubemap_pattern_control_x_item:set_value(cdata.cubemap_pattern_control and mvector3.x(cdata.cubemap_pattern_control) or 0)
					local cubemap_pattern_control_y_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 1,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_cubemap_pattern_control_y",
						name = "cubemap_pattern_control2",
						key = "cubemap_pattern_control",
						vector = 2,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					cubemap_pattern_control_y_item:set_value(cdata.cubemap_pattern_control and mvector3.y(cdata.cubemap_pattern_control) or 0)
					self:create_divider(node, "sticker")
					self:create_divider(node, "sticker2")
					local stickers = tweak_data.blackmarket.shiny_debug_tool.weapon_skins.STICKER
					sort_list = {}
					for id in pairs(stickers) do
						table.insert(sort_list, id)
					end
					table.sort(sort_list)
					local sticker
					local multichoice_list = {
						{
							_meta = "option",
							localize = false,
							text_id = "DEFAULT",
							value = -1
						}
					}
					for _, id in ipairs(sort_list) do
						sticker = stickers[id]
						table.insert(multichoice_list, {
							_meta = "option",
							localize = false,
							text_id = id,
							value = Idstring(sticker)
						})
					end
					local sticker_item = self:create_multichoice(node, multichoice_list, {
						text_offset = 50,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_sticker",
						name = "sticker",
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					sticker_item:set_value(cdata.sticker)
					local uv_offset_rot_x_item = self:create_slider(node, {
						show_value = true,
						min = -2,
						max = 2,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_offset_rot_x",
						name = "uv_offset_rot1",
						key = "uv_offset_rot",
						vector = 1,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_offset_rot_x_item:set_value(cdata.uv_offset_rot and mvector3.x(cdata.uv_offset_rot) or 0)
					local uv_offset_rot_y_item = self:create_slider(node, {
						show_value = true,
						min = -2,
						max = 2,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_offset_rot_y",
						name = "uv_offset_rot2",
						key = "uv_offset_rot",
						vector = 2,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_offset_rot_y_item:set_value(cdata.uv_offset_rot and mvector3.y(cdata.uv_offset_rot) or 0)
					local uv_scale_x_item = self:create_slider(node, {
						show_value = true,
						min = 0.01,
						max = 20,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_scale_x",
						name = "uv_scale1",
						key = "uv_scale",
						vector = 1,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_scale_x_item:set_value(cdata.uv_scale and mvector3.x(cdata.uv_scale) or 1)
					local uv_scale_y_item = self:create_slider(node, {
						show_value = true,
						min = 0.01,
						max = 20,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_scale_y",
						name = "uv_scale2",
						key = "uv_scale",
						vector = 2,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_scale_y_item:set_value(cdata.uv_scale and mvector3.y(cdata.uv_scale) or 1)
					self:create_divider(node, 3)
					local uv_offset_rot_z_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 2 * math.pi,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_offset_rot_z",
						name = "uv_offset_rot3",
						key = "uv_offset_rot",
						vector = 3,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_offset_rot_z_item:set_value(cdata.uv_offset_rot and mvector3.z(cdata.uv_offset_rot) or 0)
					local uv_scale_z_item = self:create_slider(node, {
						show_value = true,
						min = 0,
						max = 1,
						step = 0.001,
						callback = "update_weapon_skin",
						text_id = "debug_wskn_uv_scale_z",
						name = "uv_scale3",
						key = "uv_scale",
						vector = 3,
						crafted_data = Global.shiny_debug,
						part_id = data.part_id,
						material_name = data.material_name,
						mod_type = data.mod_type
					})
					uv_scale_z_item:set_value(cdata.uv_scale and mvector3.z(cdata.uv_scale) or 1)
					Global.shiny_debug.weapon_unit:base():_apply_cosmetics(function()
					end)
					if Global.shiny_debug.second_weapon_unit then
						Global.shiny_debug.second_weapon_unit:base():_apply_cosmetics(function()
						end)
					end
					node:set_default_item_name("base_gradient")
					node:select_item("base_gradient")
				end
				self:create_divider(node, "end")
				self:add_back_button(node)
			end
			return node
		end
		function MenuCallbackHandler:clear_debug_weapon_skin()
			local new_cosmetics_data = {
				weapon_id = managers.blackmarket:get_crafted_category_slot(Global.shiny_debug.category, Global.shiny_debug.slot).weapon_id,
				wear_and_tear = 1,
				parts = {}
			}
			Global.shiny_debug.weapon_unit:base()._cosmetics_data = new_cosmetics_data
			Global.shiny_debug.cosmetics_data = Global.shiny_debug.weapon_unit:base()._cosmetics_data
			Global.shiny_debug.weapon_unit:base():_apply_cosmetics(function()
			end)
			if Global.shiny_debug.second_weapon_unit then
				Global.shiny_debug.second_weapon_unit:base()._cosmetics_data = new_cosmetics_data
				Global.shiny_debug.second_weapon_unit:base():_apply_cosmetics(function()
				end)
			end
		end
		function MenuCallbackHandler:edit_weapon_customize(item)
			local id = item:name()
			local new_cosmetics_data = deep_clone(tweak_data.blackmarket.weapon_skins[id])
			local crafted_item = managers.blackmarket:get_crafted_category_slot(Global.shiny_debug.category, Global.shiny_debug.slot)
			if new_cosmetics_data.default_blueprint then
				crafted_item.blueprint = deep_clone(new_cosmetics_data.default_blueprint)
			end
			local id = string.sub(id, string.len(new_cosmetics_data.weapon_id .. "_") + 1, -1)
			local tbf = string.sub(new_cosmetics_data.texture_bundle_folder, string.len("cash/safes/") + 1, -1)
			new_cosmetics_data.name_id = nil
			new_cosmetics_data.desc_id = nil
			new_cosmetics_data.texture_bundle_folder = nil
			new_cosmetics_data.wear_and_tear = nil
			new_cosmetics_data.reserve_quality = nil
			new_cosmetics_data.locked = nil
			new_cosmetics_data.unique_name_id = nil
			new_cosmetics_data.id = id
			new_cosmetics_data.tbf = tbf
			Global.shiny_debug.cosmetics_data = new_cosmetics_data
			managers.menu:back()
			managers.menu:back()
			managers.blackmarket:view_weapon(Global.shiny_debug.category, Global.shiny_debug.slot, function()
				managers.menu:open_node("debug_shiny", {
					{
						category = Global.shiny_debug.category,
						slot = Global.shiny_debug.slot
					}
				})
			end)
		end
		function MenuCallbackHandler:cleanup_weapon_customize_data(copy_data, skip_base)
			local remove_empty_func = function(data)
				local remove = {}
				for key, v in pairs(data) do
					if key == "pattern_tweak" and v == Vector3(1, 0, 1) then
						table.insert(remove, key)
					elseif key == "pattern_pos" and v == Vector3(0, 0, 0) then
						table.insert(remove, key)
					elseif key == "uv_scale" and v == Vector3(1, 1, 1) then
						table.insert(remove, key)
					elseif key == "uv_offset_rot" and v == Vector3(0, 0, 0) then
						table.insert(remove, key)
					elseif key == "cubemap_pattern_control" and v == Vector3(0, 0, 0) then
						table.insert(remove, key)
					elseif key == "wear_and_tear" and v == 1 then
						table.insert(remove, key)
					end
				end
				for _, key in ipairs(remove) do
					data[key] = nil
				end
			end
			if not skip_base then
				remove_empty_func(copy_data)
			end
			if copy_data.parts then
				local remove_parts = {}
				for part_id, materials in pairs(copy_data.parts) do
					local remove_materials = {}
					for k, data in pairs(materials) do
						data.wear_and_tear = nil
						remove_empty_func(data)
						if table.size(data) == 0 then
							table.insert(remove_materials, k)
						end
					end
					for _, key in ipairs(remove_materials) do
						materials[key] = nil
					end
					if table.size(materials) == 0 then
						table.insert(remove_parts, part_id)
					end
				end
				for _, part_id in ipairs(remove_parts) do
					copy_data.parts[part_id] = nil
				end
				if copy_data.parts and table.size(copy_data.parts) == 0 then
					copy_data.parts = nil
				end
			end
			if copy_data.types then
				local remove_types = {}
				for type_id, data in pairs(copy_data.types) do
					remove_empty_func(data)
					if table.size(data) == 0 then
						table.insert(remove_types, type_id)
					end
				end
				for _, type_id in ipairs(remove_types) do
					copy_data.types[type_id] = nil
				end
				if copy_data.types and table.size(copy_data.types) == 0 then
					copy_data.types = nil
				end
			end
		end
		function MenuCallbackHandler:copy_weapon_customize(item)
			local crafted_item = managers.blackmarket:get_crafted_category_slot(Global.shiny_debug.category, Global.shiny_debug.slot)
			local name = managers.menu:active_menu().logic:selected_node():item("name_input"):input_text()
			if not name or name == "" then
				name = "[REPLACE ME]"
			end
			local tbf = managers.menu:active_menu().logic:selected_node():item("tbf_input"):input_text()
			if not tbf or tbf == "" then
				tbf = "wip"
			end
			local bonus = managers.menu:active_menu().logic:selected_node():item("bonus_input"):value()
			if not bonus or bonus == "" then
				bonus = "[NEED BONUS]"
			end
			local rarity = managers.menu:active_menu().logic:selected_node():item("rarity_input"):value()
			if not rarity or rarity == "" then
				rarity = "[NEED RARITY]"
			end
			local item_id = crafted_item.weapon_id .. "_" .. name
			local copy_data = deep_clone(Global.shiny_debug.cosmetics_data)
			copy_data.bonus = bonus
			copy_data.rarity = rarity
			copy_data.name_id = "bm_wskn_" .. item_id
			copy_data.desc_id = "bm_wskn_" .. item_id .. "_desc"
			copy_data.texture_bundle_folder = "cash/safes/" .. tbf
			copy_data.wear_and_tear = nil
			copy_data.reserve_quality = true
			MenuCallbackHandler:cleanup_weapon_customize_data(copy_data)
			if copy_data.rarity == "legendary" then
				copy_data.locked = true
				copy_data.unique_name_id = copy_data.name_id
			end
			if managers.menu:active_menu().logic:selected_node():item("default_blueprint"):value() == "on" then
				copy_data.default_blueprint = deep_clone(crafted_item.blueprint)
			else
				copy_data.default_blueprint = nil
			end
			local text = "\tself.weapon_skins." .. item_id .. " = {}" .. serializeTable("self.weapon_skins." .. item_id, copy_data)
			Application:set_clipboard(text)
		end
		function MenuCallbackHandler:update_weapon_skin(item)
			local key = item:parameters().key or item:name()
			local part_id = item:parameters().part_id
			local material_name = item:parameters().material_name
			local mod_type = item:parameters().mod_type
			local value = item:value()
			local vector = item:parameters().vector
			if not Global.shiny_debug.weapon_unit or not alive(Global.shiny_debug.weapon_unit) or not Global.shiny_debug.cosmetics_data then
				return
			end
			local data = Global.shiny_debug.cosmetics_data
			if part_id then
				data.parts = data.parts or {}
				data.parts[part_id] = data.parts[part_id] or {}
				if material_name then
					data.parts[part_id][material_name:key()] = data.parts[part_id][material_name:key()] or {}
					data = data.parts[part_id][material_name:key()]
				else
					data = data.parts[part_id]
				end
			elseif mod_type then
				data.types = data.types or {}
				data.types[mod_type] = data.types[mod_type] or {}
				data = data.types[mod_type]
			end
			if value == -1 then
				value = nil
			elseif vector then
				local v = data[key]
				if not v then
					local i1 = managers.menu:active_menu().logic:selected_node():item(key .. "1")
					local i2 = managers.menu:active_menu().logic:selected_node():item(key .. "2")
					local i3 = managers.menu:active_menu().logic:selected_node():item(key .. "3")
					v = Vector3(i1 and i1:value() or 0, i2 and i2:value() or 0, i3 and i3:value() or 0)
				end
				if vector == 1 then
					mvector3.set_x(v, value)
				elseif vector == 2 then
					mvector3.set_y(v, value)
				elseif vector == 3 then
					mvector3.set_z(v, value)
				end
				value = v
			end
			data[key] = value
			MenuCallbackHandler:cleanup_weapon_customize_data(Global.shiny_debug.cosmetics_data, true)
			Global.shiny_debug.weapon_unit:base():_apply_cosmetics(function()
			end)
			if Global.shiny_debug.second_weapon_unit then
				Global.shiny_debug.second_weapon_unit:base():_apply_cosmetics(function()
				end)
			end
		end
		function serializeTable(table_prefix, val, name, skipnewlines, depth)
			skipnewlines = skipnewlines or false
			depth = depth or 0
			local tmp = string.rep("\t", depth)
			if depth == 1 then
				tmp = tmp .. table_prefix .. "."
			end
			local lines, sort_lines
			if depth == 0 then
				lines = {}
				sort_lines = {
					"name_id",
					"desc_id",
					"weapon_id",
					"rarity",
					"bonus",
					"reserve_quality",
					"texture_bundle_folder",
					"unique_name_id",
					"locked",
					"base_gradient",
					"pattern_gradient",
					"pattern",
					"sticker",
					"pattern_tweak",
					"pattern_pos",
					"uv_scale",
					"uv_offset_rot",
					"cubemap_pattern_control",
					"default_blueprint",
					"parts",
					"types"
				}
			end
			if name then
				tmp = tmp .. name .. " = "
			end
			if type(val) == "table" then
				tmp = tmp .. (name and "{" or "") .. "\n"
				if #val > 0 then
					for k, v in ipairs(val) do
						tmp = tmp .. serializeTable(table_prefix, v, nil, true, depth + 1) .. (name and "," or "") .. "\n"
					end
				else
					for k, v in pairs(val) do
						local kname = k
						if depth == 2 and type(v) == "table" then
							kname = string.format("[Idstring(%q):key()]", Idstring.lookup(k):s())
						end
						if depth == 0 then
							lines[k] = serializeTable(table_prefix, v, kname, skipnewlines, depth + 1) .. (name and "," or "") .. (not skipnewlines and "\n" or "")
						else
							tmp = tmp .. serializeTable(table_prefix, v, kname, skipnewlines, depth + 1) .. (name and "," or "") .. (not skipnewlines and "\n" or "")
						end
					end
				end
				tmp = tmp .. string.rep("\t", depth) .. (name and "}" or "")
			elseif type(val) == "number" then
				tmp = tmp .. tostring(val)
			elseif type(val) == "string" then
				tmp = tmp .. string.format("%q", val)
			elseif type(val) == "boolean" then
				tmp = tmp .. (val and "true" or "false")
			elseif type(val) == "userdata" and val.s then
				tmp = tmp .. "Idstring(\"" .. val:s() .. "\")"
			elseif type(val) == "userdata" and val.tostring then
				tmp = tmp .. val:tostring()
			else
				tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
			end
			if depth == 0 then
				for _, key in ipairs(sort_lines) do
					if lines[key] then
						tmp = tmp .. lines[key]
					end
				end
			end
			return tmp
		end
	end
end
