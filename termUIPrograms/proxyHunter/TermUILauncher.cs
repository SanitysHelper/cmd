using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;

class Program
{
    static int Main(string[] args)
    {
        var exeDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var psScript = Path.Combine(exeDir, "powershell", "termUI.ps1");
        var settings = Path.Combine(exeDir, "settings.ini");
        var versionJson = Path.Combine(exeDir, "VERSION.json");
        var modulesDir = Path.Combine(exeDir, "powershell", "modules");
        var required = new[] { psScript, settings, versionJson, modulesDir };

        bool needsRestore = required.Any(p => !File.Exists(p) && !Directory.Exists(p));

        if (needsRestore)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("[termUI] Core files missing. Attempting online repair from GitHub...");
            Console.ResetColor();
            if (!RestoreFromGitHub(exeDir))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("[termUI] Repair failed. Please download the full package from GitHub.");
                Console.ResetColor();
                return 1;
            }
        }

        if (!File.Exists(psScript))
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine("[termUI] termUI.ps1 still missing after repair. Exiting.");
            Console.ResetColor();
            return 1;
        }

        // Launch PowerShell with arguments
        var argList = string.Join(" ", args.Select(QuoteArg));
        var psi = new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = string.Format("-NoProfile -ExecutionPolicy Bypass -File \"{0}\" {1}", psScript, argList),
            UseShellExecute = false
        };

        try
        {
            using (var p = Process.Start(psi))
            {
                p.WaitForExit();
                return p.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine(string.Format("[termUI] Failed to start PowerShell: {0}", ex.Message));
            Console.ResetColor();
            return 1;
        }
    }

    static bool RestoreFromGitHub(string targetDir)
    {
        var repo = "SanitysHelper/cmd";
        var branch = "main";
        var downloadUrl = string.Format("https://github.com/{0}/archive/refs/heads/{1}.zip", repo, branch);
        var tempZip = Path.Combine(Path.GetTempPath(), "termui_bootstrap.zip");
        var extractDir = Path.Combine(Path.GetTempPath(), "termui_bootstrap_extract");

        try
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
            
            var version = GetRemoteVersion(repo, branch);
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine(string.Format("[termUI] Downloading termUI {0} from GitHub...", version));
            Console.ResetColor();

            if (File.Exists(tempZip)) File.Delete(tempZip);
            if (Directory.Exists(extractDir)) Directory.Delete(extractDir, true);

            var request = (HttpWebRequest)WebRequest.Create(downloadUrl);
            request.UserAgent = "termUI-Bootstrap";
            using (var response = (HttpWebResponse)request.GetResponse())
            using (var responseStream = response.GetResponseStream())
            using (var fileStream = new FileStream(tempZip, FileMode.Create, FileAccess.Write, FileShare.None, 65536))
            {
                var totalBytes = response.ContentLength > 0 ? response.ContentLength : 23000000;  // Default ~23MB if unknown
                var buffer = new byte[8192];
                long totalRead = 0;
                int bytesRead;
                var lastPercent = -1;
                var lastUpdate = DateTime.MinValue;
                var barWidth = 40;
                
                while ((bytesRead = responseStream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    fileStream.Write(buffer, 0, bytesRead);
                    totalRead += bytesRead;
                    
                    var now = DateTime.Now;
                    var percent = totalBytes > 0 ? (int)((double)totalRead / totalBytes * 100) : 0;
                    percent = Math.Min(percent, 100);  // Cap at 100%
                    
                    if (percent != lastPercent || (now - lastUpdate).TotalMilliseconds > 500)
                    {
                        lastPercent = percent;
                        lastUpdate = now;
                        var filled = Math.Max(0, Math.Min((int)((double)percent / 100 * barWidth), barWidth));
                        var empty = Math.Max(0, barWidth - filled);
                        var bar = new string('=', filled) + new string('-', empty);
                        var mbReceived = totalRead / 1024.0 / 1024.0;
                        var mbTotal = totalBytes / 1024.0 / 1024.0;
                        Console.Write(string.Format("\r[{0}] {1}% ({2:F2} MB / {3:F2} MB)", bar, percent, mbReceived, mbTotal));
                    }
                }
                Console.WriteLine();
            }

            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("[termUI] Extracting termUI folder only...");
            Console.ResetColor();

            ZipFile.ExtractToDirectory(tempZip, extractDir);
            var sourceRoot = Path.Combine(extractDir, string.Format("cmd-{0}", branch), "termUI");
            
            if (!Directory.Exists(sourceRoot))
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("[termUI] termUI folder not found in archive");
                Console.ResetColor();
                return false;
            }

            var currentExe = GetCurrentExePath();
            CopyDirectoryContents(sourceRoot, targetDir, currentExe);
            
            File.Delete(tempZip);
            Directory.Delete(extractDir, true);
            
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("[termUI] Bootstrap completed successfully");
            Console.ResetColor();
            return true;
        }
        catch (Exception ex)
        {
            Console.ForegroundColor = ConsoleColor.Red;
            Console.WriteLine(string.Format("\n[termUI] Bootstrap error: {0}", ex.Message));
            Console.ResetColor();
            return false;
        }
    }

    static string GetRemoteVersion(string repo, string branch)
    {
        try
        {
            var versionUrl = string.Format("https://raw.githubusercontent.com/{0}/{1}/termUI/VERSION.json", repo, branch);
            using (var client = new WebClient())
            {
                client.Headers.Add("Cache-Control", "no-cache");
                var json = client.DownloadString(versionUrl);
                
                var versionPattern = "\"version\"";
                var versionStart = json.IndexOf(versionPattern);
                if (versionStart >= 0)
                {
                    var colonPos = json.IndexOf(":", versionStart);
                    if (colonPos >= 0)
                    {
                        var valueStart = colonPos + 1;
                        while (valueStart < json.Length && (json[valueStart] == ' ' || json[valueStart] == '\t' || json[valueStart] == '\r' || json[valueStart] == '\n'))
                            valueStart++;
                        
                        if (valueStart < json.Length && json[valueStart] == '"')
                        {
                            var quoteStart = valueStart + 1;
                            var quoteEnd = json.IndexOf('"', quoteStart);
                            if (quoteEnd > quoteStart)
                            {
                                return "v" + json.Substring(quoteStart, quoteEnd - quoteStart);
                            }
                        }
                    }
                }
            }
        }
        catch { }
        return "latest";
    }

    static void CopyDirectoryContents(string sourceDir, string targetDir, string skipPath)
    {
        var normalizedSkip = NormalizePath(skipPath);
        
        foreach (var dir in Directory.GetDirectories(sourceDir, "*", SearchOption.AllDirectories))
        {
            var rel = dir.Substring(sourceDir.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            var dest = Path.Combine(targetDir, rel);
            Directory.CreateDirectory(dest);
        }
        
        foreach (var file in Directory.GetFiles(sourceDir, "*", SearchOption.AllDirectories))
        {
            var rel = file.Substring(sourceDir.Length).TrimStart(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            var dest = Path.Combine(targetDir, rel);
            var normalizedDest = NormalizePath(dest);
            
            if (!string.IsNullOrEmpty(normalizedSkip) && string.Equals(normalizedDest, normalizedSkip, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }
            
            var destDir = Path.GetDirectoryName(dest);
            if (!string.IsNullOrEmpty(destDir))
                Directory.CreateDirectory(destDir);
            File.Copy(file, dest, true);
        }
    }

    static string NormalizePath(string path)
    {
        if (string.IsNullOrEmpty(path)) return string.Empty;
        try { return Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar); }
        catch { return path; }
    }

    static string GetCurrentExePath()
    {
        try { return Process.GetCurrentProcess().MainModule.FileName; }
        catch { return string.Empty; }
    }

    static string QuoteArg(string arg)
    {
        if (string.IsNullOrEmpty(arg)) return "\"\"";
        if (arg.Contains(" ")) return string.Format("\"{0}\"", arg);
        return arg;
    }
}
