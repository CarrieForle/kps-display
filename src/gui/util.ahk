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
 * along with KPS Display. If not, see <https://www.gnu.org/licenses/>.
 */

default_font()
{
    return "Segoe UI"
}

try_do(f, &output?)
{
    try
    {
        output := f()
    }
    catch Error as e
    {
        output := e

        return false
    }

    return true
}

; Not used, but I hope one day it's useful
show_tooltip(wParam, lParam, msg, hwnd)
{
    static prev_hwnd := 0

    if (hwnd != prev_hwnd)
    {
        ToolTip()
        ctrl := GuiCtrlFromHwnd(hwnd)

        if ctrl && ctrl.HasProp("tooltip")
        {
            SetTimer () => ToolTip(ctrl.tooltip), -500
            SetTimer () => ToolTip(), -3000

            prev_hwnd := hwnd
        }

    }
}