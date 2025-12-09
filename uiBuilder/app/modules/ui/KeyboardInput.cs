using System;
using System.Runtime.InteropServices;
using System.Threading;

namespace UIBuilder.Input
{
    [StructLayout(LayoutKind.Sequential)]
    public struct KEY_EVENT_RECORD
    {
        public bool bKeyDown;
        public ushort wRepeatCount;
        public ushort wVirtualKeyCode;
        public ushort wVirtualScanCode;
        public char UnicodeChar;
        public uint dwControlKeyState;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT_RECORD
    {
        public ushort EventType;
        public KEY_EVENT_RECORD KeyEvent;
    }

    public class KeyboardHandler
    {
        private const int STD_INPUT_HANDLE = -11;
        private const int KEY_EVENT = 1;

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int nStdHandle);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool ReadConsoleInput(IntPtr hConsoleInput, out INPUT_RECORD lpBuffer, uint nLength, out uint lpNumberOfEventsRead);

        private IntPtr consoleHandle;

        public KeyboardHandler()
        {
            consoleHandle = GetStdHandle(STD_INPUT_HANDLE);
        }

        public KeyState WaitForKey()
        {
            while (true)
            {
                INPUT_RECORD record;
                uint numRead;
                
                if (ReadConsoleInput(consoleHandle, out record, 1, out numRead))
                {
                    if (numRead > 0 && record.EventType == KEY_EVENT)
                    {
                        KEY_EVENT_RECORD keyEvent = record.KeyEvent;
                        
                        return new KeyState
                        {
                            VirtualKeyCode = keyEvent.wVirtualKeyCode,
                            Character = keyEvent.UnicodeChar,
                            IsKeyDown = keyEvent.bKeyDown,
                            ControlKeyState = keyEvent.dwControlKeyState,
                            RepeatCount = keyEvent.wRepeatCount
                        };
                    }
                }
                Thread.Sleep(10);
            }
        }

        public bool IsShiftPressed(uint controlKeyState)
        {
            return (controlKeyState & 0x0012) != 0;
        }

        public bool IsCtrlPressed(uint controlKeyState)
        {
            return (controlKeyState & 0x000C) != 0;
        }

        public bool IsAltPressed(uint controlKeyState)
        {
            return (controlKeyState & 0x0021) != 0;
        }
    }

    public class KeyState
    {
        public ushort VirtualKeyCode;
        public char Character;
        public bool IsKeyDown;
        public uint ControlKeyState;
        public ushort RepeatCount;

        public override string ToString()
        {
            string keyName = GetKeyName(VirtualKeyCode);
            string modifiers = "";
            
            if ((ControlKeyState & 0x0012) != 0) modifiers += "Shift+";
            if ((ControlKeyState & 0x000C) != 0) modifiers += "Ctrl+";
            if ((ControlKeyState & 0x0021) != 0) modifiers += "Alt+";
            
            return modifiers + keyName;
        }

        private string GetKeyName(ushort code)
        {
            switch (code)
            {
                case 0x26: return "Up";
                case 0x28: return "Down";
                case 0x25: return "Left";
                case 0x27: return "Right";
                case 0x0D: return "Enter";
                case 0x08: return "Backspace";
                case 0x1B: return "Escape";
                case 0x10: return "Shift";
                case 0x11: return "Ctrl";
                case 0x12: return "Alt";
                default: return "Key(" + code.ToString() + ")";
            }
        }
    }

    class Program
    {
        private static KeyState TryGetInjectedKey()
        {
            string inj = Environment.GetEnvironmentVariable("UIB_INJECT_KEY");
            if (string.IsNullOrWhiteSpace(inj)) return null;

            // Format: vk=13;char=0;down=1;state=18;repeat=1
            ushort vk = 0;
            char ch = (char)0;
            bool down = true;
            uint state = 0;
            ushort repeat = 1;

            string[] parts = inj.Split(';');
            foreach (var part in parts)
            {
                var kv = part.Split('=');
                if (kv.Length != 2) continue;
                string key = kv[0].Trim().ToLower();
                string val = kv[1].Trim();
                switch (key)
                {
                    case "vk": ushort.TryParse(val, out vk); break;
                    case "char": ushort u; if (ushort.TryParse(val, out u)) ch = (char)u; break;
                    case "down": down = val == "1" || val.Equals("true", StringComparison.OrdinalIgnoreCase); break;
                    case "state": uint.TryParse(val, out state); break;
                    case "repeat": ushort.TryParse(val, out repeat); break;
                }
            }

            return new KeyState
            {
                VirtualKeyCode = vk,
                Character = ch,
                IsKeyDown = down,
                ControlKeyState = state,
                RepeatCount = repeat
            };
        }

        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                Console.WriteLine("Usage: KeyboardInput.exe <command>");
                Console.WriteLine("Commands:");
                Console.WriteLine("  wait - Wait for and return key press");
                Console.WriteLine("  test - Test keyboard detection");
                return;
            }

            string command = args[0].ToLower();

            if (command == "wait")
            {
                // Check for injected key first to allow automation
                KeyState injected = TryGetInjectedKey();
                if (injected != null)
                {
                    Console.WriteLine("VK:" + injected.VirtualKeyCode.ToString());
                    Console.WriteLine("Char:" + ((int)injected.Character).ToString());
                    Console.WriteLine("IsDown:" + injected.IsKeyDown.ToString());
                    Console.WriteLine("State:" + injected.ControlKeyState.ToString());
                    Console.WriteLine("Display:" + injected.ToString());
                    return;
                }

                var handler = new KeyboardHandler();
                KeyState key = handler.WaitForKey();
                
                Console.WriteLine("VK:" + key.VirtualKeyCode.ToString());
                Console.WriteLine("Char:" + ((int)key.Character).ToString());
                Console.WriteLine("IsDown:" + key.IsKeyDown.ToString());
                Console.WriteLine("State:" + key.ControlKeyState.ToString());
                Console.WriteLine("Display:" + key.ToString());
            }
            else if (command == "test")
            {
                Console.WriteLine("Testing keyboard input (press keys, Shift+Enter for desc, Q to quit):");
                Console.WriteLine();
                
                var handler = new KeyboardHandler();
                while (true)
                {
                    KeyState key = handler.WaitForKey();
                    
                    if (key.VirtualKeyCode == 0x51 || key.VirtualKeyCode == 0x71)
                    {
                        if (!key.IsKeyDown) break;
                    }
                    
                    string keyState = key.IsKeyDown ? "PRESSED" : "RELEASED";
                    Console.WriteLine("[" + keyState + "] " + key.ToString() + " (VK:" + key.VirtualKeyCode.ToString() + ", Repeat:" + key.RepeatCount.ToString() + ")");
                    
                    if (key.VirtualKeyCode == 0x0D && key.IsKeyDown)
                    {
                        bool isShift = handler.IsShiftPressed(key.ControlKeyState);
                        if (isShift)
                        {
                            Console.WriteLine(">>> SHIFT+ENTER DETECTED - SHOWING DESCRIPTION <<<");
                        }
                        else
                        {
                            Console.WriteLine(">>> ENTER DETECTED - SELECTING ITEM <<<");
                        }
                    }
                }
                Console.WriteLine("Goodbye!");
            }
        }
    }
}
