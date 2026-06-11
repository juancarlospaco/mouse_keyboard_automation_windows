Add-Type -AssemblyName System.Windows.Forms, System.Drawing
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Keyboard+mouse automation OFF; Must be run as Admin!" -ForegroundColor Yellow
    exit
}
function Test-TypeExists {
  param($n) [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { try { if ($_.GetType($n, $false)) { return $true } } catch {} }; $false
}

function Add-X {
    if (Test-TypeExists -typeName "X") { return }
    Add-Type -ReferencedAssemblies "System.Windows.Forms", "System.Drawing" @"
using System;
using System.Runtime.InteropServices;

public class X {
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, int dwFlags, int dwExtraInfo);
    [DllImport("user32.dll")]
    public static extern IntPtr WindowFromPoint(System.Drawing.Point p);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    private static Action[] _ascii = new Action[128];
    private static System.Collections.Generic.Dictionary<int,Action> _special =
        new System.Collections.Generic.Dictionary<int,Action>();
    private const uint WM_CLOSE = 0x0010;

    static X() {
        for (int i = 0; i < 26; i++) {
            int idx = i;
            _ascii['a' + i] = () => _k((byte)(0x41 + idx));
        }
        for (int i = 0; i < 10; i++) {
            int idx = i;
            _ascii['0' + i] = () => _k((byte)(0x30 + idx));
        }
        _ascii[' '] = () => _k(0x20);

        // F1-F12  →  😀 U+1F600  …  😋 U+1F60B
        for (int i = 0; i < 12; i++) { int idx = i; _special[0x1F600 + idx] = () => _k((byte)(0x70 + idx)); }

        // pad0-pad9  →  😌 U+1F60C  …  😕 U+1F615
        for (int i = 0; i < 10; i++) { int idx = i; _special[0x1F60C + idx] = () => _k((byte)(0x60 + idx)); }

        // Navigation / system keys  →  😖 U+1F616  …  😦 U+1F626
        byte[] navVk = { 0x5B, 0x1B, 0x0D, 0x09, 0x08, 0x20, 0x2C, 0x21, 0x22, 0x24, 0x23, 0x2D, 0x2E, 0x25, 0x26, 0x27, 0x28 };
        //                win  esc  enter tab  bksp space prsc pgUp pgDn home end  ins  del  left up   rght down
        for (int i = 0; i < navVk.Length; i++) { int idx = i; byte vk = navVk[idx]; _special[0x1F616 + idx] = () => _k(vk); }

        // capslock  →  😧 U+1F627
        _special[0x1F627] = () => _k(0x14);

        // Ctrl combos  →  😨😩😪😫😬  U+1F628-U+1F62C
        //              copy  cut   paste selAll undo
        _special[0x1F628] = () => _ctrl(0x43); // Ctrl+C
        _special[0x1F629] = () => _ctrl(0x58); // Ctrl+X
        _special[0x1F62A] = () => _ctrl(0x56); // Ctrl+V
        _special[0x1F62B] = () => _ctrl(0x41); // Ctrl+A
        _special[0x1F62C] = () => _ctrl(0x5A); // Ctrl+Z

        // Modifier down/up  →  😭😮😯😰😱😲  U+1F62D-U+1F632
        //                       shDn  shUp  ctDn  ctUp  alDn  alUp
        _special[0x1F62D] = () => _kDown(0x10); // Shift ↓
        _special[0x1F62E] = () => _kUp(0x10);   // Shift ↑
        _special[0x1F62F] = () => _kDown(0x11); // Ctrl ↓
        _special[0x1F630] = () => _kUp(0x11);   // Ctrl ↑
        _special[0x1F631] = () => _kDown(0x12); // Alt ↓
        _special[0x1F632] = () => _kUp(0x12);   // Alt ↑
    }

    public static void _scroll(int lines) { mouse_event(0x0800, 0, 0, lines * 120, 0); }
    private static void _k(byte key)     { keybd_event(key, 0, 0, 0); keybd_event(key, 0, 0x0002, 0); }
    private static void _kDown(byte key) { keybd_event(key, 0, 0, 0); }
    private static void _kUp(byte key)   { keybd_event(key, 0, 0x0002, 0); }
    private static void _ctrl(byte key)  { keybd_event(0x11, 0, 0, 0); keybd_event(key, 0, 0, 0); keybd_event(key, 0, 0x0002, 0); keybd_event(0x11, 0, 0x0002, 0); }
    private static void _shifted(byte key) {
        keybd_event(0x10, 0, 0, 0);
        keybd_event(key, 0, 0, 0);
        keybd_event(key, 0, 0x0002, 0);
        keybd_event(0x10, 0, 0x0002, 0);
    }

    public static void xkill() {
        while (true) {
            if ((GetAsyncKeyState(0x01) & 0x8000) != 0) {
                var pos = System.Windows.Forms.Cursor.Position;
                IntPtr hWnd = WindowFromPoint(System.Windows.Forms.Cursor.Position);
                if (hWnd != IntPtr.Zero) {
                    uint pid;
                    GetWindowThreadProcessId(hWnd, out pid);
                    if (!PostMessage(hWnd, WM_CLOSE, IntPtr.Zero, IntPtr.Zero)) {
                        Console.WriteLine("SOFT CLOSE FAILED, FORCING...");
                        try { System.Diagnostics.Process.GetProcessById((int)pid).Kill(); }
                        catch { Console.WriteLine("FORCE CLOSE FAILED."); }
                    }
                }
                break;
            }
            System.Threading.Thread.Sleep(99);
        }
    }

    public static void keyboard(string text) {
        int i = 0;
        while (i < text.Length) {
            int cp = char.ConvertToUtf32(text, i);
            int charLen = char.IsSurrogatePair(text, i) ? 2 : 1;
            Action act;
            if (_special.TryGetValue(cp, out act)) {
                act();
            }
            else {
                switch (cp) {
                    case '?': _shifted(0xBF); break;
                    case '!': _shifted(0x31); break;
                    case '@': _shifted(0x32); break;
                    case '#': _shifted(0x33); break;
                    case '$': _shifted(0x34); break;
                    case '%': _shifted(0x35); break;
                    case '^': _shifted(0x36); break;
                    case '&': _shifted(0x37); break;
                    case '*': _shifted(0x38); break;
                    case '(': _shifted(0x39); break;
                    case ')': _shifted(0x30); break;
                    case '_': _shifted(0xBD); break;
                    case '+': _shifted(0xBB); break;
                    case '{': _shifted(0xDB); break;
                    case '}': _shifted(0xDD); break;
                    case '|': _shifted(0xDC); break;
                    case ':': _shifted(0xBA); break;
                    case '"': _shifted(0xDE); break;
                    case '<': _shifted(0xBC); break;
                    case '>': _shifted(0xBE); break;
                    case '~': _shifted(0xC0); break;
                    case '\n': _k(0x0D); break;  // Enter
                    case '\r': _k(0x0D); break;  // Enter
                    case '\t': _k(0x09); break;  // Tab
                    case 0x1F480: xkill(); break; // ☠️ xkill linux-like
                    case 0x1F4C5:  // 📅 date
                        DateTime now = DateTime.Now;
                        keyboard(now.ToString("yyyy-MM-dd"));
                        break;
                    case 0x1F552:  // 🕒 time
                        DateTime now2 = DateTime.Now;
                        keyboard(now2.ToString("HH:mm:ss"));
                        break;
                    default:  // Minúsculas, números, espacio y resto de ASCII
                        if (cp >= 'A' && cp <= 'Z') {
                            _shifted((byte)(0x41 + (cp - 'A')));
                        } else if (cp < 128 && _ascii[cp] != null) {
                            _ascii[cp]();
                        }
                        break;
                }
            }
            i += charLen;
        }
    }

    static void MoveCursor(int dx, int dy) {
        var p = System.Windows.Forms.Cursor.Position;
        SetCursorPos(p.X + dx, p.Y + dy);
    }

    public static void grid(char c) {
        int idx = c - '0', cols = 5, rows = 2;
        var b = System.Windows.Forms.Screen.PrimaryScreen.Bounds;
        SetCursorPos(b.Left + (idx % cols) * b.Width / cols + b.Width / cols / 2,
                     b.Top + (idx / cols) * b.Height / rows + b.Height / rows / 2);
    }

    public static void mouse(string movement) {
        int step = 10;
        int bigStep = 100;
        foreach (char cmd in movement.ToCharArray()) {
            switch (cmd) {
                case 'a': MoveCursor(-step, 0); break;
                case 'A': MoveCursor(-bigStep, 0); break;
                case 'd': MoveCursor(step, 0); break;
                case 'D': MoveCursor(bigStep, 0); break;
                case 'w': MoveCursor(0, -step); break;
                case 'W': MoveCursor(0, -bigStep); break;
                case 's': MoveCursor(0, step); break;
                case 'S': MoveCursor(0, bigStep); break;
                case 'q': MoveCursor(-step, -step); break;
                case 'Q': MoveCursor(-bigStep, -bigStep); break;
                case 'e': MoveCursor(step, -step); break;
                case 'E': MoveCursor(bigStep, -bigStep); break;
                case 'z': MoveCursor(-step, step); break;
                case 'Z': MoveCursor(-bigStep, bigStep); break;
                case 'x': MoveCursor(step, step); break;
                case 'X': MoveCursor(bigStep, bigStep); break;
                case 'l': mouse_event(0x0002, 0, 0, 0, 0); mouse_event(0x0004, 0, 0, 0, 0); break;
                case 'm': mouse_event(0x0020, 0, 0, 0, 0); mouse_event(0x0040, 0, 0, 0, 0); break;
                case 'r': mouse_event(0x0008, 0, 0, 0, 0); mouse_event(0x0010, 0, 0, 0, 0); break;
                case 'L': mouse_event(0x0002, 0, 0, 0, 0); mouse_event(0x0004, 0, 0, 0, 0); mouse_event(0x0002, 0, 0, 0, 0); mouse_event(0x0004, 0, 0, 0, 0); break;
                case 'p': System.Threading.Thread.Sleep(step * 10); break;
                case 'P': System.Threading.Thread.Sleep(bigStep * 10); break;
                case ']': _scroll(step / 2); break;
                case '}': _scroll(bigStep / 2); break;
                case '[': _scroll(-step / 2); break;
                case '{': _scroll(-bigStep / 2); break;
                case '<': step = System.Math.Max(1, step / 2); bigStep = System.Math.Max(1, bigStep / 2); break;
                case '>': step = System.Math.Min(999, step * 2); bigStep = System.Math.Min(9999, bigStep * 2); break;
                case '0': grid('0'); break;
                case '1': grid('1'); break;
                case '2': grid('2'); break;
                case '3': grid('3'); break;
                case '4': grid('4'); break;
                case '5': grid('5'); break;
                case '6': grid('6'); break;
                case '7': grid('7'); break;
                case '8': grid('8'); break;
                case '9': grid('9'); break;
            }

        }
    }
}
"@
    Write-Host "Keyboard+mouse automation; Run 'mouse ""wasd""' or 'keyboard ""Abc123""' as Admin." -ForegroundColor Green
}
if (-not (Test-TypeExists -typeName "X")) {
    Add-X
}
# WRAPPER FUNCTIONS
function _mouse { param([string]$Command) [X]::mouse($Command) }
function _keyboard { param([string]$Text) [X]::keyboard($Text) }
function _xkill { [X]::xkill() }
