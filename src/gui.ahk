#Include "message.ahk"

ShowOption(guiObj, guiCtrlObj, item, isRightClick, x, y)
{
    MsgBox "TODO You Right Clicked!"
}

mainGui := Gui("Resize")
mainGui.OnEvent("ContextMenu", ShowOption)
; KPS: key per second
kps := mainGui.AddText("W300 H300 Right", "##")
kps.SetFont("S72 Q5", "Segoe UI")
mainGui.Show("W300 H300")

get_kps()
{
    return kps
}

update_kps(wParam, lParam, msg, hwnd)
{
    kps_num := wParam - 0x10000
    kps := GuiCtrlFromHwnd(hwnd)
    kps.Text := String(kps_num)
}

OnMessage KPS_CHANGE, update_kps