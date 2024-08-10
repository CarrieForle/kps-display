#SingleInstance Force
#Requires AutoHotkey v2.0
#Include "gui/gui.ahk"
#Include "gui/main.ahk"
#Include "config.ahk"

FileEncoding "UTF-8"

onKeyDown(inputHook, vk, sc)
{
    for char in hold_char_creation_ticks
    {
        if char == vk
        {
            return
        }
    }
    
    char_creation_ticks.Push(A_TickCount)
    hold_char_creation_ticks.Push(vk)
}
        
onKeyUp(input_hook, vk, sc)
{
    for i, char in hold_char_creation_ticks
    {
        if char == vk
        {
            hold_char_creation_ticks.RemoveAt(i)
            return
        }
    }
}

prev_char_counts := 0
char_creation_ticks := []
hold_char_creation_ticks := []
PER_SECOND := 1000
CHECK_INTERVAL := 77 ; ms

try
{
    progress := false
    config_name := IniRead("profile.ini", "general", "current_profile")
    progress := true
    config := Configuration.read(IniRead("profile.ini", "general", "current_profile"))
}
catch Error as e
{
    if !progress {
        MsgBox "Failed to read profile.ini: " e.Message "`nThe program will terminate.", "Error", 16
        ExitApp
    }
    else
    {
        MsgBox "Failed to read " config_name ": " e.Message "`nThe program will terminate.", "Error", 16
        ExitApp
    }
}

input_hook := InputHook("B V N L0")
input_hook.OnKeyUp := onKeyUp
input_hook.OnKeyDown := onKeyDown
input_hook.NotifyNonText := true
input_hook.KeyOpt("{All}", "N")
input_hook.Start()

guis := init_guis(config)
guis["main"].Show("H300 W300")

SetTimer kps_update, CHECK_INTERVAL
    
kps_update()
{
    global prev_char_counts

    while char_creation_ticks.Length > 0 && A_TickCount - char_creation_ticks[1] > PER_SECOND
    {
        char_creation_ticks.RemoveAt(1)
        ; ToolTip "POP", 1920 // 2 - 300, 1080 // 2, 2
    }
    
    if prev_char_counts != char_creation_ticks.Length
    {
        prev_char_counts := char_creation_ticks.Length
        update_kps_text(guis["main"]["kps_text"], char_creation_ticks.Length)
    }
}