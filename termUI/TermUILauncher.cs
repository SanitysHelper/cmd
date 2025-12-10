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

        bool needsRestore = required.Any(p => !PathExists(p));

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
        var tempZip = Path.Combine(Path.GetTempPath(), "termui_launcher_bootstrap.zip");
        var extractDir = Path.Combine(Path.GetTempPath(), "termui_launcher_extract");

        try
        {
            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
            if (File.Exists(tempZip)) File.Delete(tempZip);
            if (Directory.Exists(extractDir)) Directory.Delete(extractDir, true);

            using (var client = new WebClient())
            {
                client.DownloadFile(downloadUrl, tempZip);
            }

            ZipFile.ExtractToDirectory(tempZip, extractDir);
            var sourceRoot = Path.Combine(extractDir, string.Format("cmd-{0}", branch), "termUI");
            if (!Directory.Exists(sourceRoot))
            {
                Console.WriteLine(string.Format("[termUI] Bootstrap source not found in archive: {0}", sourceRoot));
                return false;
            }

            CopyDirectory(sourceRoot, targetDir);
            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine(string.Format("[termUI] Bootstrap error: {0}", ex.Message));
            return false;
        }
        finally
        {
            try { if (File.Exists(tempZip)) File.Delete(tempZip); } catch { }
            try { if (Directory.Exists(extractDir)) Directory.Delete(extractDir, true); } catch { }
        }
    }

    static void CopyDirectory(string sourceDir, string targetDir)
    {
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
            var destDir = Path.GetDirectoryName(dest);
            if (!string.IsNullOrEmpty(destDir)) { Directory.CreateDirectory(destDir); }
            File.Copy(file, dest, true);
        }
    }

    static bool PathExists(string path)
    {
        return File.Exists(path) || Directory.Exists(path);
    }

    static string QuoteArg(string arg)
    {
        if (string.IsNullOrEmpty(arg)) return "\"\"";
        if (arg.Contains(" ")) return string.Format("\"{0}\"", arg);
        return arg;
    }
}
