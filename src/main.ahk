#SingleInstance Force
#Requires AutoHotkey v2.0
#Include "key.ahk"
#Include "gui.ahk"

FileEncoding "UTF-8"

charCount := 0
chars := []
holdChars := []
CHECK_INTERVAL := 50 ; ms

onKeyDown(inputHook, vk, sc)
{
    global charCount

    for char in holdChars
    {
        if char == vk
        {
            return
        }
    }

    chars.Push(Key(1, A_TickCount))
    holdChars.Push(vk)
}

onKeyUp(inputHook, vk, sc)
{
    for i, char in holdChars
    {
        if char == vk
        {
            holdChars.RemoveAt(i)
            return
        }
    }
}

write(filename, text)
{
    try
    {
        FileDelete filename
    } catch
    {

    }

    FileAppend text, filename
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
    while chars.Length > 0 and A_TickCount - chars[1].creationTick > 1000
    {
        chars.RemoveAt(1)
        ; ToolTip "POP", 1920 // 2 - 300, 1080 // 2, 2
    }

    totalChars := 0
    evaluation_string := ""

    for char in chars
    {
        totalChars += char.length
        evaluation_string .= "`n" char.creationTick
    }

    ; evaluation_string := totalChars " " CHECK_INTERVAL - (A_TickCount - start) "`n" A_TickCount "`n" (A_TickCount - start) . evaluation_string 

    write "text.txt", String(totalChars)

    Sleep CHECK_INTERVAL - (A_TickCount - start)
}