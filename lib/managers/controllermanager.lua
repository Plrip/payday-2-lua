core:module("ControllerManager")
core:import("CoreControllerManager")
core:import("CoreClass")
ControllerManager = ControllerManager or class(CoreControllerManager.ControllerManager)
function ControllerManager:init(path, default_settings_path)
	default_settings_path = "settings/controller_settings"
	path = default_settings_path
	ControllerManager.super.init(self, path, default_settings_path)
end
function ControllerManager:controller_mod_changed()
	if not Global.controller_manager.user_mod then
		Global.controller_manager.user_mod = managers.user:get_setting("controller_mod")
		self:load_user_mod()
	end
end
function ControllerManager:set_user_mod(connection_name, params)
	Global.controller_manager.user_mod = Global.controller_manager.user_mod or {}
	if params.axis then
		Global.controller_manager.user_mod[connection_name] = Global.controller_manager.user_mod[connection_name] or {
			axis = params.axis
		}
		Global.controller_manager.user_mod[connection_name][params.button] = params
	else
		Global.controller_manager.user_mod[connection_name] = params
	end
	managers.user:set_setting("controller_mod_type", managers.controller:get_default_wrapper_type())
	managers.user:set_setting("controller_mod", Global.controller_manager.user_mod, true)
end
function ControllerManager:clear_user_mod(category, CONTROLS_INFO)
	Global.controller_manager.user_mod = Global.controller_manager.user_mod or {}
	local names = table.map_keys(Global.controller_manager.user_mod)
	for _, name in ipairs(names) do
		if CONTROLS_INFO[name].category == category then
			Global.controller_manager.user_mod[name] = nil
		end
	end
	managers.user:set_setting("controller_mod_type", managers.controller:get_default_wrapper_type())
	managers.user:set_setting("controller_mod", Global.controller_manager.user_mod, true)
	self:load_user_mod()
end
function ControllerManager:load_user_mod()
	if Global.controller_manager.user_mod then
		local connections = managers.controller:get_settings(managers.user:get_setting("controller_mod_type")):get_connection_map()
		for connection_name, params in pairs(Global.controller_manager.user_mod) do
			if params.axis then
				for button, button_params in pairs(params) do
					if type(button_params) == "table" then
						connections[params.axis]._btn_connections[button_params.button].name = button_params.connection
					end
				end
			elseif connections[params.button] then
				connections[params.button]:set_controller_id(params.controller_id)
				connections[params.button]:set_input_name_list({
					params.connection
				})
			end
		end
		self:rebind_connections()
	end
end
function ControllerManager:init_finalize()
	managers.user:add_setting_changed_callback("controller_mod", callback(self, self, "controller_mod_changed"), true)
	if Global.controller_manager.user_mod then
		self:load_user_mod()
	end
	self:_check_dialog()
end
function ControllerManager:default_controller_connect_change(connected)
	ControllerManager.super.default_controller_connect_change(self, connected)
	if Global.controller_manager.default_wrapper_index and not connected and not self:_controller_changed_dialog_active() then
		self:_show_controller_changed_dialog()
	end
end
function ControllerManager:_check_dialog()
	if Global.controller_manager.connect_controller_dialog_visible and not self:_controller_changed_dialog_active() then
		self:_show_controller_changed_dialog()
	end
end
function ControllerManager:_controller_changed_dialog_active()
	return managers.system_menu:is_active_by_id("connect_controller_dialog") and true or false
end
function ControllerManager:_show_controller_changed_dialog()
	if self:_controller_changed_dialog_active() then
		return
	end
	Global.controller_manager.connect_controller_dialog_visible = true
	local data = {}
	data.callback_func = callback(self, self, "connect_controller_dialog_callback")
	data.title = managers.localization:text("dialog_connect_controller_title")
	data.text = managers.localization:text("dialog_connect_controller_text", {
		NR = Global.controller_manager.default_wrapper_index or 1
	})
	data.button_list = {
		{
			text = managers.localization:text("dialog_ok")
		}
	}
	data.id = "connect_controller_dialog"
	data.force = true
	managers.system_menu:show(data)
end
function ControllerManager:_close_controller_changed_dialog()
	if Global.controller_manager.connect_controller_dialog_visible or self:_controller_changed_dialog_active() then
		managers.system_menu:close("connect_controller_dialog")
		self:connect_controller_dialog_callback()
	end
end
function ControllerManager:connect_controller_dialog_callback()
	Global.controller_manager.connect_controller_dialog_visible = nil
end
CoreClass.override_class(CoreControllerManager.ControllerManager, ControllerManager)
