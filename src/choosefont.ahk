; code inspired by https://www.autohotkey.com/board/topic/94083-ahk-11-font-and-color-dialogs/
; https://learn.microsoft.com/en-us/windows/win32/api/commdlg/ns-commdlg-choosefontw

class Font
{
    typeface := ""
    weight := 400,
    italic := false
    underline := false
    strikethrough := false
    height := false

    __New(typeface, height, weight, italic, underline, strikethrough)
    {
        this.typeface := typeface
        this.height := height
        this.weight := 400
        this.italic := italic
        this.underline := underline
        this.strikethrough := strikethrough
    }
}
; https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-logfontw#members
_muldiv(a, b, c)
{
    return a * b // c
}

_rev_muldiv(muldiv, b, c)
{
    return muldiv * c // b
}

choose_font(owner_hwnd := 0, &output?, style?)
{
    ; 28 + 2 * 31 + 1 = 91
    static logfont := Buffer(91)

    LOGPIXELY := DllCall("GetDeviceCaps", "Ptr", DllCall("GetDC", "Ptr", 0), "Int", 90)

    font_height := -_muldiv(IsSet(style) ? style.height : 12, LOGPIXELY, 72)

    offset := NumPut(
        "Int", font_height,
        "Int", 0, ; width (idk)
        "Int", 0, ; escapement (idk)
        "Int", 0, ; orientation (idk)
        "Int", IsSet(style) ? style.weight : 0,
        "UChar", IsSet(style) ? style.italic : 0,
        "UChar", IsSet(style) ? style.underline : 0,
        "UChar", IsSet(style) ? style.strikethrough : 0,
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        "UChar", 0, ; not used
        logfont
    ) - logfont.Ptr

    if IsSet(style)
    {
        before_offset := offset
        written_bytes := StrPut(style.typeface, logfont.Ptr + offset, , "UTF-16")
        NumPut("Char", 0, logfont.ptr + offset + written_bytes)
        written_bytes++
    }

    if A_PtrSize = 8
    { 
        static tag_choose_font := Buffer(104)

        NumPut "UInt", tag_choose_font.Size,
            "Int", 0, ; padding
            "Ptr", owner_hwnd,
            "Ptr", 0, ; not used
            "Ptr", logfont.Ptr, 
            "Int", 0, ; return font size
            ; CF_INACTIVEFONTS, CF_FORCEFONTEXIST, CF_NOSCRIPTSEL, CF_NOVERTFONTS, CF_INITTOLOGFONTSTRUCT
            "UInt", 0x03810040, ; flags
            "UInt", 0, ; not used
            "Int", 0, ; padding
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "Ptr", 0, ; not used
            "UShort", 0, ; return font style (duplicate of logfont fields)
            "UShort", 0, ; __MISSING_ALIGNMENT__ (WTF does that mean?)
            "Int", 0, ; min font pt (not used)
            "Int", 0, ; max font pt (not used)
            "Int", 0, ; padding
            tag_choose_font
    }
    ; TODO: Test on 32-bit
    else
    {
        tag_choose_font := Buffer(92)

        NumPut "UInt", tag_choose_font.Size,
            "Ptr", owner_hwnd,
            "Ptr", 0,
            "Ptr", logfont.Ptr,
            "Int", 0,
            "UInt", 0x03810040,
            "UInt", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "Ptr", 0,
            "UShort", 0,
            "UShort", 0,
            "Int", 0,
            "Int", 0,
            tag_choose_font
    }

    result := DllCall("Comdlg32\ChooseFont", "Ptr", tag_choose_font, "Cdecl")

    if !result
    {
        if errno := DllCall("Comdlg32\CommDlgExtendedError")
        {
            MsgBox Format("Error: 0x{:x}`nFont is not chosen.", errno), "Error", 16
        }

        return
    }

    height := -_rev_muldiv(NumGet(logfont, "Int"), LOGPIXELY, 72)
    weight := NumGet(logfont, 16, "Int")
    italic := NumGet(logfont, 20, "UChar") ? true : false ; originally return 255 or 0
    underline := NumGet(logfont, 21, "UChar")
    strikethrough := NumGet(logfont, 22, "UChar")
    typeface := StrGet(logfont.ptr + 28, , "UTF-16")

    MsgBox "font height: " height "'`nWeight: " weight "'`nitalic: " italic "'`nunderline: " underline "'`nstrikethrough: " strikethrough "'`ntypeface: " typeface "'"

    return output := Font(typeface, height, weight, italic, underline, strikethrough)
}

; choose_font(,, Font("Consolas", 18, 700, 1, 1, 1))