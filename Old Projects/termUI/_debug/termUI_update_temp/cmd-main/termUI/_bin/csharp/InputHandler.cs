using System;
using System.IO;
using System.Text;

class InputHandler
{
    static void Main(string[] args)
    {
        bool useStdin = false;
        string replayFile = GetArgValue(args, "--replay");
        if (!string.IsNullOrEmpty(replayFile))
        {
            useStdin = true;
        }

        if (useStdin)
        {
            TextReader reader = !string.IsNullOrEmpty(replayFile) ? (TextReader)new StreamReader(replayFile) : Console.In;
            string line;
            while ((line = reader.ReadLine()) != null)
            {
                line = line.Trim();
                if (line.Length == 0) continue;
                EmitParsed(line);
            }
            return;
        }

        // Interactive mode: read real keys
        // First, enable raw input
        Console.TreatControlCAsInput = false;
        
        while (true)
        {
            try
            {
                // Poll for key availability instead of blocking
                if (Console.KeyAvailable)
                {
                    ConsoleKeyInfo keyInfo = Console.ReadKey(true);
                    MapKeyAndEmit(keyInfo);
                }
                else
                {
                    // Small sleep to prevent busy-waiting
                    System.Threading.Thread.Sleep(10);
                }
            }
            catch (IOException)
            {
                // Input stream closed
                break;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Error: " + ex.Message);
                break;
            }
        }
    }

    static void MapKeyAndEmit(ConsoleKeyInfo info)
    {
        string key;
        string ch;
        switch (info.Key)
        {
            case ConsoleKey.UpArrow: 
                key = "Up"; ch = ""; 
                break;
            case ConsoleKey.DownArrow: 
                key = "Down"; ch = ""; 
                break;
            case ConsoleKey.LeftArrow: 
                key = "Left"; ch = ""; 
                break;
            case ConsoleKey.RightArrow: 
                key = "Right"; ch = ""; 
                break;
            case ConsoleKey.Enter: 
                key = "Enter"; ch = ""; 
                break;
            case ConsoleKey.Escape: 
                key = "Escape"; ch = ""; 
                break;
            case ConsoleKey.Tab:
                key = "Tab"; ch = "";
                break;
            default:
                char charVal = info.KeyChar;
                if (charVal == '\0') charVal = ' ';
                // Treat q/Q as quit key for fast exit
                if (charVal == 'q' || charVal == 'Q')
                {
                    key = "Q";
                    ch = charVal.ToString();
                }
                else
                {
                    key = "Char"; 
                    ch = charVal.ToString();
                }
                break;
        }
        EmitEvent(key, ch);
    }

    static void EmitParsed(string line)
    {
        // Simple formats: "Up" or "CHAR:a" or JSON with key/char
        if (line.StartsWith("CHAR:", StringComparison.OrdinalIgnoreCase) && line.Length > 5)
        {
            EmitEvent("Char", line.Substring(5, 1));
            return;
        }
        if (line.StartsWith("{"))
        {
            // naive parse for key/char
            string key = Extract(line, "\"key\"");
            string ch = Extract(line, "\"char\"");
            EmitEvent(string.IsNullOrEmpty(key) ? "Unknown" : key, ch);
            return;
        }
        EmitEvent(line, "");
    }

    static string Extract(string json, string field)
    {
        int idx = json.IndexOf(field, StringComparison.OrdinalIgnoreCase);
        if (idx < 0) return string.Empty;
        idx = json.IndexOf(':', idx);
        if (idx < 0) return string.Empty;
        idx++;
        while (idx < json.Length && (json[idx] == ' ' || json[idx] == '"')) idx++;
        StringBuilder sb = new StringBuilder();
        while (idx < json.Length)
        {
            char c = json[idx];
            if (c == '"' || c == ',' || c == '}') break;
            sb.Append(c);
            idx++;
        }
        return sb.ToString();
    }

    static void EmitEvent(string key, string ch)
    {
        string id = Guid.NewGuid().ToString("N");
        string timestamp = DateTime.UtcNow.ToString("o");
        ch = ch ?? string.Empty;
        key = key ?? "Unknown";
        string payload = string.Format("{{\"id\":\"{0}\",\"key\":\"{1}\",\"char\":\"{2}\",\"timestamp\":\"{3}\",\"source\":\"handler\"}}",
            id, Escape(key), Escape(ch), timestamp);
        Console.Out.WriteLine(payload);
        Console.Out.Flush();
    }

    static string Escape(string s) 
    { 
        return s.Replace("\\", "\\\\").Replace("\"", "\\\""); 
    }

    static string GetArgValue(string[] args, string name)
    {
        for (int i = 0; i < args.Length; i++)
        {
            if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                return args[i + 1];
            }
        }
        return string.Empty;
    }
}
