#SingleInstance Force
#Requires AutoHotkey v2.0
#Include "gui/gui.ahk"
#Include "message.ahk"
#Include "main.ahk"
#Include "message.ahk"
#Include "resread.ahk"
#Include "config.ahk"

;@Ahk2Exe-AddResource res/format_help.txt*6

FileEncoding "UTF-8"

char_count := 0
char_creation_ticks := []
hold_char_creation_ticks := []
PER_SECOND := 1000
CHECK_INTERVAL := 77 ; ms

onKeyDown(inputHook, vk, sc)
{
    global char_count

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

input_hook := InputHook("B V N L0")
input_hook.OnKeyUp := onKeyUp
input_hook.OnKeyDown := onKeyDown
input_hook.NotifyNonText := true
input_hook.KeyOpt("{All}", "N")
input_hook.Start()
init_guis()
get_guis("main").Show()
SetTimer kps_update, CHECK_INTERVAL

kps_update()
{
    while char_creation_ticks.Length > 0 and A_TickCount - char_creation_ticks[1] > PER_SECOND
    {
        char_creation_ticks.RemoveAt(1)
        ; ToolTip "POP", 1920 // 2 - 300, 1080 // 2, 2
    }
    
    update_kps_text(char_creation_ticks.Length)
}