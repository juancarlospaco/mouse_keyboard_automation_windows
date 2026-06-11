# Mouse keyboard automation

Mouse and keyboard automation for Windows single-file standalone 250-line script.


# MOUSE

- "wasd" videogame-like movements, "qezx" videogame-like DIAGONAL movements.
- "l" for left click, "r" for right click, "m" for middle click, "L" for double click.
- ">" increase mouse speed, "<" decrease mouse speed.
- "p" for tiny pause sleep, "P" for big pause sleep.
- "]" Scroll wheel up, "[" Scroll wheel down.

Example:
```powershell
PS C:\> _mouse "wasd"
```

### Mouse Grid 5x2

The screen is imaginarily divided into a 5x2 grid, 2 rows horizontal, 5 columns vertical,
You can teleport the mouse to the center of each grid cell as a quick fast shortcut.

Imagine this is your screen:
```
┌─────┬─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  4  │  5  │
├─────┼─────┼─────┼─────┼─────┤
│  6  │  7  │  8  │  9  │  0  │
└─────┴─────┴─────┴─────┴─────┘
```

Example, teleport the mouse to the grid cell 3:
```powershell
PS C:\> _mouse "3"
```


# XKILL

- Linux-like XKill, closes/kills running apps visually with the mouse.
- It will try to close the app, if it is frozen, it will force kill it.

Example:
```powershell
PS C:\> _xkill
```


# KEYBOARD

- "a"-"z", "A"-"Z", "0"-"9" ASCII letters.
- Emoji is used for special keyboard keys.
- "☠️" executes a Linux-like xkill.
- "📅" types the current date in ISO format.
- "🕒" types the current time in ISO format.
- "😧" is Capslock.
- "😨" is copy Ctrl+C.
- "😩" is cut Ctrl+X.
- "😪" is paste Ctrl+V.
- "😫" is select all Ctrl+A.
- "😬" is undo Ctrl+Z.
- F1-F12 uses 😀 U+1F600 ~ 😋 U+1F60B
- pad0-pad9 uses 😌 U+1F60C ~ 😕 U+1F615

Example:
```powershell
PS C:\> _keyboard "Hello World 123"
```


# REQUISITES

- PowerShell.
- Must be run as Admin, because of Windows limitations.
- File must be "unlocked" to run, right click on file-->Properties--->Unlock checkbox (if any).


# INSTALL

- Can be installed anywhere, but in an easy-to-remember safe folder path, like the home folder `"C:\Users\USER\mouse_keyboard_automation_windows.ps1"`
- Open Powershell, execute `notepad $PROFILE` (if it warns about non-existent file ignore it, we'll create it).
- Add the line `. "C:\Users\USER\mouse_keyboard_automation_windows.ps1"` (leading dot is important), save and close Notepad, close PowerShell.
- Open PowerShell as Admin and you can use it.


# UNINSTALL

- Undo the steps from INSTALL section.


# DESING

I force a free LLM to do boring repetitive tasks on any arbitrary software,
it can not control the keyboard and mouse, but it understands PowerShell,
so using this file as a simplified "API", the LLM can control the keyboard and mouse.

I tried other solutions like AutoHotkey, TinyTask, Python, etc
but the generated code is too verbose and complex OOP, the LLM takes time to write it.

The main idea is to do more for less characters that need to be generated.

I tried an IDE with LLM like the paid Google Antigravity IDE,
but it can only work inside itself, can not work on any arbitrary software.

Free LLM worked on Blender and Unreal Engine with this simple tool.
