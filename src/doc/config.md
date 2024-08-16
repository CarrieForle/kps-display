# Configuration Overview

First and foremost, **profile file encoding must be UTF-16.** The encoding should be correct unless you create a profile from scratch. If the program is acting when loading your profile. This is the first thing to consider.

Another thing is it's strongly recommend to **NOT** directly edit `default.ini`. It serves as the default and fallback profile. The program would refuse to start if no profile is loaded so it's best to leave that. Saving `default.ini` in the program will overwrite all the comments so it's also best to save as a new file when you use the program.

This page is intended for people configuring in the program rather than with a text editor, as `default.ini` provides those explanation particularly.

## General

#### Padding

This is used in [KPS format](#format). See [this](format_help.md#Flag-and-Width) for details.

#### Monitored keys

The keys that will be accounted toward KPS. Typically you just type out the keys if it produces a character. Spaces are ignored. To monitor spacebar key, tab key and special keys like Shift and arrows, you wrap the key within curly brackets {}. [Here's the full list that applies](https://www.autohotkey.com/docs/v2/lib/Send.htm#keynames). Note mouse buttons couldn't be monitored.

If it's blank. All keys are monitored. If you supplied *any* key, only those keys are monitored. If you then checked **Invert**, all keys except the supplied keys are monitored. Note Invert option is ignored if you leave the field blank.

## Style

#### Background/Font color
The color of KPS in hex, optionally prefixed by `#`.

#### Alignment

The alignment of KPS

#### Format

See [Format Help](format_help.md)

#### Preview

Produce a window to preview the configuration without saving. You can leave preview window opened and continue to configure. Change some values and press **Restart** in the preview window or **Preview** in the configuration window will update the preview window.

## Custom KPS

Map KPS-es to certain texts. You can make it so the program display any text of your like when it reaches certain KPS. To enable custom KPS you must do so in **[Format](format_help.md#placeholder)**.

The left operand is the KPS value, the right operand is customized text for this KPS.

You may escape the following characters:
- `\n` = newline
- `\\` = `\`

Other characters are taken literally.

## Advanced

#### Update Interval

The interval for KPS to update in millisecond. The lower this value the more frequent it updates. This is best to set above 15 due to inprecision. If you see KPS occasionally disappearing for a frame or two, try to higher this value.

#### Offsets

The positional offset of KPS. Positive value moves the text right/down, negative moves left/up.