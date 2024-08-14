/*
 * Copyright (c) 2024 CarrieForle
 * This file is part of KPS Display.
 *
 * KPS Display is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * KPS Display is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * adng with KPS Display. If not, see <https://www.gnu.org/licenses/>.
 */

#Requires AutoHotkey v2.0
#Include "gui/gui.ahk"
#Include "gui/main.ahk"

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

try
{
    filepath := better_ini_read("setup.ini", "general", "current_profile")
    dimension := StrSplit(better_ini_read("setup.ini", "general", "dimension"), A_Space)

    if dimension.Length != 2
    {
        throw ValueError("Expected 2 integers for dimension. Found " dimension.Length)
    }

    for i in dimension
    {
        if !IsInteger(i) || Integer(i) < 1
        {
            throw ValueError("Expected positive integer for dimension. Found " i)
        }
    }
    filename := 0

    config := Configuration.read(filepath)
}
catch ConfigParseError as e
{
    loop
    {
        try
        {
            SplitPath filepath, &filename

        if "Yes" = MsgBox("Failed to read " filename "`nError: " e.Message "`nChoose a profile (pick yes) or the default profile (pick no)?", "Error", 0x14) && filepath := FileSelect(1, , "Open config", "Config (*.ini)")
            {
                config := Configuration.read(filepath)
                break
            }
            else
            {
                try
                {
                    config := Configuration.read("default.ini")
                    break
                }
                catch Error as e
                {
                    MsgBox("Failed to read default.ini`nError: " e.Message "`nThe program will terminate.", "Error", 16)
                    ExitApp
                }
            }
        }
        catch ConfigParseError as e
        {

        }
        catch Error as e
        {
            unrecoverable_error(e)
        }
    }
}
catch Error as e
{
    MsgBox "Failed to read setup.ini`nError: " e.Message "`nThe program will terminate.", "Fatal Error", 16
    ExitApp
}

input_hook := InputHook("B V L0")
input_hook.OnKeyUp := onKeyUp
input_hook.OnKeyDown := onKeyDown
config.general.monitored_keys.transform(input_hook)
input_hook.Start()

transmit_config_to_event_loop(new_config)
{
    global config
    config := new_config
    config.general.monitored_keys.transform(input_hook)
    SetTimer kps_update, config.general.update_interval
}

guis := init_guis(config, dimension)

guis["main"].OnEvent("Size", _real_resize.Bind(&config))
guis["main"].Show("w" dimension[1] "h" dimension[2])

SetTimer kps_update, config.general.update_interval
    
kps_update()
{
    global prev_char_counts

    while char_creation_ticks.Length > 0 && A_TickCount - char_creation_ticks[1] > PER_SECOND
    {
        char_creation_ticks.RemoveAt(1)
    }

    kps := char_creation_ticks.Length
    
    if prev_char_counts != kps
    {
        prev_char_counts := kps
        update_kps_text(guis["main"]["kps_text"], config.KPS.format.to_string(kps, config.custom_kps, config.KPS.padding))
    }
}