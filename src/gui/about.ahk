#Include "main.ahk"

_real_show_about(main_gui, about_gui, itemName, itemPos, myMenu)
{
    main_gui.Opt("+Disabled")
    about_gui.Show("AutoSize")
}

init_about_gui(main_gui)
{
    about_gui := Gui("+Owner" main_gui.Hwnd " +ToolWindow")
    about_gui.Title := "About"
    about_gui.SetFont("S9", default_font())
    about_gui.OnEvent("Close", _real_enable_main.Bind(main_gui))
    about_link := about_gui.AddLink("Center vabout_link", "KPS (Key per second) display`nis made by CarrieForle © 2024")
    show_about := _real_show_about.bind(main_gui)
    
    return about_gui
}