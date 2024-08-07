#Include "main.ahk"
#Include "config.ahk"
#Include "about.ahk"

__guis := Map()

get_guis(key)
{
    return __guis[key]
}
;
init_guis()
{
    global __guis
    static called := false

    if !called {
        main_gui := init_main_gui()
        __guis["main"] := main_gui

        config_gui := init_config_gui(main_gui)
        __guis["config"] := config_gui

        about_gui := init_about_gui(main_gui)
        __guis["about"] := about_gui

        option_menu := Menu()
        show_option := _real_show_option.bind(option_menu)
        option_menu.Add("Configure", _real_show_config.Bind(main_gui, config_gui))
        option_menu.Add("About", _real_show_about.Bind(main_gui, about_gui))
        main_gui.OnEvent("ContextMenu", show_option)

        __guis["option_menu"] := option_menu

        called := true
    }

    return (main_gui, config_gui, about_gui)
}