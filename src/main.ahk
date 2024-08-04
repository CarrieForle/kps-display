#SingleInstance Force
#Requires AutoHotkey v2.0
#Include "key.ahk"
#Include "gui.ahk"

FileEncoding "UTF-8"

charCount := 0
charCreationTicks := Keys()
holdcharCreationTicks := []
CHECK_INTERVAL := 50 ; ms

onKeyDown(inputHook, vk, sc)
{
    global charCount

    for char in holdcharCreationTicks
    {
        if char == vk
        {
            return
        }
    }

    charCreationTicks.Push(A_TickCount)
    holdcharCreationTicks.Push(vk)
}

onKeyUp(inputHook, vk, sc)
{
    for i, char in holdcharCreationTicks
    {
        if char == vk
        {
            holdcharCreationTicks.RemoveAt(i)
            return
        }
    }
}

inputHookObj := InputHook("B V N L0")
inputHookObj.OnKeyUp := onKeyUp
inputHookObj.OnKeyDown := onKeyDown
inputHookObj.NotifyNonText := true
inputHookObj.KeyOpt("{All}", "N")
inputHookObj.Start()

loop {
    start := A_TickCount
    ; arrays' first index is 1
    while charCreationTicks.Length > 0 and A_TickCount - charCreationTicks[1] > 1000
    {
        charCreationTicks.RemoveAt(1)
        ; ToolTip "POP", 1920 // 2 - 300, 1080 // 2, 2
    }

    evaluation_string := ""

    for creationTick in charCreationTicks
    {
        evaluation_string .= "`n" creationTick
    }

    ; evaluation_string := totalcharCreationTicks " " CHECK_INTERVAL - (A_TickCount - start) "`n" A_TickCount "`n" (A_TickCount - start) . evaluation_string 

    Sleep CHECK_INTERVAL - (A_TickCount - start)
}