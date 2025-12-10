using System;
using System.Diagnostics;

class KeyboardBridge
{
    static void Main()
    {
        // Start InputHandler subprocess
        ProcessStartInfo psi = new ProcessStartInfo
        {
            FileName = "InputHandler.exe",
            RedirectStandardOutput = true,
            RedirectStandardInput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        
        Process proc = Process.Start(psi);
        
        // Read keyboard and send to InputHandler
        while (true)
        {
            try
            {
                ConsoleKeyInfo key = Console.ReadKey(true);
                string keyName = GetKeyName(key);
                if (!string.IsNullOrEmpty(keyName))
                {
                    proc.StandardInput.WriteLine(keyName);
                    proc.StandardInput.Flush();
                }
            }
            catch
            {
                break;
            }
        }
        
        proc.WaitForExit();
    }
    
    static string GetKeyName(ConsoleKeyInfo key)
    {
        return key.Key switch
        {
            ConsoleKey.UpArrow => "Up",
            ConsoleKey.DownArrow => "Down",
            ConsoleKey.LeftArrow => "Left",
            ConsoleKey.RightArrow => "Right",
            ConsoleKey.Enter => "Enter",
            ConsoleKey.Escape => "Escape",
            ConsoleKey.Tab => "Tab",
            _ => GetCharName(key.KeyChar)
        };
    }
    
    static string GetCharName(char ch)
    {
        if (ch == 'q' || ch == 'Q') return "Q";
        if (char.IsLetterOrDigit(ch) || char.IsPunctuation(ch))
            return "CHAR:" + ch;
        return "";
    }
}
