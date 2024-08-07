#Include "../../resread.ahk"
#Include "../util.ahk"

_real_show_format_help(format_help_gui, config_gui, GuiCtrlObj, *)
{
    format_help_gui.show()
    config_gui.opt("+Disabled")
}

init_config_format_help_gui(config_gui, help_ico_handle)
{
    format_help_picture := config_gui.AddPicture("vformat_help_picture X+ w16 h-1", "HICON:*" help_ico_handle)
    format_help_gui := Gui("+Owner" config_gui.Hwnd " -MinimizeBox -MaximizeBox")
    format_help_gui.Title := "Format Help"

    ; Use `help` icon
    SendMessage 0x0080, 0, help_ico_handle, format_help_gui

    format_help_gui.SetFont("S10", "Consolas")
    format_help_edit := format_help_gui.AddEdit("vformat_help_edit ReadOnly w450 h450", StrGet(res_read("res/format_help.txt", 6), "UTF-8"))
    show_format_help := _real_show_format_help.bind(format_help_gui, config_gui)
    enable_config_gui := enable_gui.bind(config_gui)
    format_help_picture.OnEvent("Click", show_format_help)
    format_help_gui.OnEvent("Close", enable_config_gui)

    return format_help_gui
}