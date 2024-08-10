#Include "main.ahk"
#Include "config.ahk"
#Include "about.ahk"

off_and_on(my_gui)
{
    for gui_ctrl in my_gui
    {
        gui_ctrl.Enabled := false
        gui_ctrl.Enabled := true
    }
}

init_guis(config)
{
    static called := false
    static guis := Map()

    if !called {
        main_gui := init_main_gui(config)
        guis["main"] := main_gui

        config_gui := init_config_gui(main_gui, config)
        guis["config"] := config_gui

        about_gui := init_about_gui(main_gui)
        guis["about"] := about_gui

        option_menu := Menu()
        option_menu.Add("Configure", _real_show_config.Bind(main_gui, config_gui))
        option_menu.Add("About", _real_show_about.Bind(main_gui, about_gui))
        main_gui.OnEvent("ContextMenu", _real_show_option.bind(option_menu))
        _real_enable_main(main_gui)

        called := true
    }

    return guis
}