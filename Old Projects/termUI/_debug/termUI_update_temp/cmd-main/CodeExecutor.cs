using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;

namespace CodeExecutor
{
    public class MainForm : Form
    {
        private TextBox codeEditor;
        private TextBox outputBox;
        private Label langLabel;
        private Button detectBtn;
        private Button runBtn;
        private Button clearBtn;
        private Button openBtn;
        private Button saveBtn;
        private string detectedLang = "unknown";

        public MainForm()
        {
            InitializeComponent();
            this.AllowDrop = true;
            this.DragEnter += MainForm_DragEnter;
            this.DragDrop += MainForm_DragDrop;
        }

        private void InitializeComponent()
        {
            this.Text = "Universal Code Executor";
            this.Width = 900;
            this.Height = 750;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.WhiteSmoke;

            // Title
            Label titleLabel = new Label();
            titleLabel.Text = "Drag & drop code files here or paste code:";
            titleLabel.Location = new Point(10, 10);
            titleLabel.Width = 300;
            this.Controls.Add(titleLabel);

            // Code Editor
            codeEditor = new TextBox();
            codeEditor.Multiline = true;
            codeEditor.Location = new Point(10, 35);
            codeEditor.Width = 870;
            codeEditor.Height = 350;
            codeEditor.Font = new Font("Courier New", 10);
            codeEditor.ScrollBars = ScrollBars.Both;
            codeEditor.WordWrap = false;
            this.Controls.Add(codeEditor);

            // Language detection row
            Label langTitleLabel = new Label();
            langTitleLabel.Text = "Detected Language:";
            langTitleLabel.Location = new Point(10, 395);
            langTitleLabel.Width = 120;
            this.Controls.Add(langTitleLabel);

            langLabel = new Label();
            langLabel.Text = "unknown";
            langLabel.Location = new Point(140, 395);
            langLabel.Width = 100;
            langLabel.ForeColor = Color.Blue;
            langLabel.Font = new Font(langLabel.Font, FontStyle.Bold);
            this.Controls.Add(langLabel);

            // Buttons
            detectBtn = new Button();
            detectBtn.Text = "Detect";
            detectBtn.Location = new Point(10, 425);
            detectBtn.Width = 100;
            detectBtn.Height = 35;
            detectBtn.Click += DetectBtn_Click;
            this.Controls.Add(detectBtn);

            runBtn = new Button();
            runBtn.Text = "Compile & Run";
            runBtn.Location = new Point(120, 425);
            runBtn.Width = 100;
            runBtn.Height = 35;
            runBtn.BackColor = Color.LightGreen;
            runBtn.Click += RunBtn_Click;
            this.Controls.Add(runBtn);

            clearBtn = new Button();
            clearBtn.Text = "Clear";
            clearBtn.Location = new Point(230, 425);
            clearBtn.Width = 100;
            clearBtn.Height = 35;
            clearBtn.Click += ClearBtn_Click;
            this.Controls.Add(clearBtn);

            openBtn = new Button();
            openBtn.Text = "Open File";
            openBtn.Location = new Point(340, 425);
            openBtn.Width = 100;
            openBtn.Height = 35;
            openBtn.Click += OpenBtn_Click;
            this.Controls.Add(openBtn);

            saveBtn = new Button();
            saveBtn.Text = "Save Output";
            saveBtn.Location = new Point(450, 425);
            saveBtn.Width = 100;
            saveBtn.Height = 35;
            saveBtn.Click += SaveBtn_Click;
            this.Controls.Add(saveBtn);

            // Output label
            Label outputLabel = new Label();
            outputLabel.Text = "Output:";
            outputLabel.Location = new Point(10, 470);
            outputLabel.Width = 100;
            this.Controls.Add(outputLabel);

            // Output Box
            outputBox = new TextBox();
            outputBox.Multiline = true;
            outputBox.Location = new Point(10, 490);
            outputBox.Width = 870;
            outputBox.Height = 200;
            outputBox.Font = new Font("Courier New", 9);
            outputBox.ScrollBars = ScrollBars.Both;
            outputBox.ReadOnly = true;
            outputBox.WordWrap = false;
            this.Controls.Add(outputBox);
        }

        private void MainForm_DragEnter(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
                e.Effect = DragDropEffects.Copy;
        }

        private void MainForm_DragDrop(object sender, DragEventArgs e)
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
            if (files.Length > 0)
            {
                try
                {
                    string content = File.ReadAllText(files[0]);
                    codeEditor.Text = content;
                    DetectLanguage();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error reading file: " + ex.Message);
                }
            }
        }

        private void DetectBtn_Click(object sender, EventArgs e)
        {
            DetectLanguage();
        }

        private void DetectLanguage()
        {
            string code = codeEditor.Text;

            if (string.IsNullOrEmpty(code))
                detectedLang = "unknown";
            else if (code.Contains("Write-Host") || code.Contains("Get-") || code.Contains("$"))
                detectedLang = "powershell";
            else if (code.Contains("console.log") || code.Contains("const ") || code.Contains("function "))
                detectedLang = "javascript";
            else if (code.Contains("print(") || code.Contains("import ") || code.Contains("def "))
                detectedLang = "python";
            else if (code.Contains("#include <iostream>") || code.Contains("std::"))
                detectedLang = "cpp";
            else if (code.Contains("#include"))
                detectedLang = "c";
            else if (code.Contains("@echo off") || code.Contains("setlocal"))
                detectedLang = "batch";
            else if (code.Contains("#!/bin/bash"))
                detectedLang = "bash";
            else
                detectedLang = "unknown";

            langLabel.Text = detectedLang;
        }

        private void RunBtn_Click(object sender, EventArgs e)
        {
            CompileAndRun();
        }

        private void CompileAndRun()
        {
            string code = codeEditor.Text;

            if (string.IsNullOrEmpty(code))
            {
                outputBox.Text = "[ERROR] No code to execute!";
                return;
            }

            DetectLanguage();

            string tempDir = Path.Combine(Path.GetTempPath(), "CodeExecutor_" + Environment.TickCount);
            Directory.CreateDirectory(tempDir);

            try
            {
                switch (detectedLang)
                {
                    case "c":
                        ExecuteC(code, tempDir);
                        break;
                    case "cpp":
                        ExecuteCPP(code, tempDir);
                        break;
                    case "python":
                        ExecutePython(code, tempDir);
                        break;
                    case "javascript":
                        ExecuteJavaScript(code, tempDir);
                        break;
                    case "powershell":
                        ExecutePowerShell(code, tempDir);
                        break;
                    case "batch":
                        ExecuteBatch(code, tempDir);
                        break;
                    default:
                        outputBox.Text = "[ERROR] Unknown language: " + detectedLang + "\n\nSupported: C, C++, Python, JavaScript, PowerShell, Batch";
                        break;
                }
            }
            catch (Exception ex)
            {
                outputBox.Text = "[ERROR] " + ex.Message;
            }
        }

        private void ExecuteC(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.c");
            string exeFile = Path.Combine(tempDir, "code.exe");
            
            File.WriteAllText(srcFile, code);

            // Compile
            var compileProc = new ProcessStartInfo("gcc", "-o code.exe code.c")
            {
                WorkingDirectory = tempDir,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var proc = Process.Start(compileProc))
            {
                string compileOut = proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
                proc.WaitForExit();

                if (proc.ExitCode != 0 || compileOut.Contains("error"))
                {
                    outputBox.Text = "[COMPILE ERROR]\n" + compileOut;
                    return;
                }
            }

            // Run
            var runProc = new ProcessStartInfo(exeFile)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var proc = Process.Start(runProc))
            {
                string runOut = proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
                proc.WaitForExit();
                outputBox.Text = "[OUTPUT]\n" + runOut;
            }
        }

        private void ExecuteCPP(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.cpp");
            string exeFile = Path.Combine(tempDir, "code.exe");
            
            File.WriteAllText(srcFile, code);

            // Compile
            var compileProc = new ProcessStartInfo("g++", "-o code.exe code.cpp")
            {
                WorkingDirectory = tempDir,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var proc = Process.Start(compileProc))
            {
                string compileOut = proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
                proc.WaitForExit();

                if (proc.ExitCode != 0 || compileOut.Contains("error"))
                {
                    outputBox.Text = "[COMPILE ERROR]\n" + compileOut;
                    return;
                }
            }

            // Run
            var runProc = new ProcessStartInfo(exeFile)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var proc = Process.Start(runProc))
            {
                string runOut = proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
                proc.WaitForExit();
                outputBox.Text = "[OUTPUT]\n" + runOut;
            }
        }

        private void ExecutePython(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.py");
            File.WriteAllText(srcFile, code);

            var proc = new ProcessStartInfo("python", srcFile)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var p = Process.Start(proc))
            {
                string output = p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
                p.WaitForExit();
                outputBox.Text = "[OUTPUT]\n" + output;
            }
        }

        private void ExecuteJavaScript(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.js");
            File.WriteAllText(srcFile, code);

            var proc = new ProcessStartInfo("node", srcFile)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var p = Process.Start(proc))
            {
                string output = p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
                p.WaitForExit();
                if (p.ExitCode != 0)
                    outputBox.Text = "[ERROR] Node.js not found or execution failed\n" + output;
                else
                    outputBox.Text = "[OUTPUT]\n" + output;
            }
        }

        private void ExecutePowerShell(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.ps1");
            File.WriteAllText(srcFile, code);

            var proc = new ProcessStartInfo("powershell", "-NoProfile -ExecutionPolicy Bypass -File " + srcFile)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var p = Process.Start(proc))
            {
                string output = p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
                p.WaitForExit();
                outputBox.Text = "[OUTPUT]\n" + output;
            }
        }

        private void ExecuteBatch(string code, string tempDir)
        {
            string srcFile = Path.Combine(tempDir, "code.bat");
            File.WriteAllText(srcFile, code);

            var proc = new ProcessStartInfo("cmd", "/c " + srcFile)
            {
                WorkingDirectory = tempDir,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var p = Process.Start(proc))
            {
                string output = p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd();
                p.WaitForExit();
                outputBox.Text = "[OUTPUT]\n" + output;
            }
        }

        private void ClearBtn_Click(object sender, EventArgs e)
        {
            codeEditor.Text = "";
            outputBox.Text = "";
            langLabel.Text = "unknown";
            detectedLang = "unknown";
        }

        private void OpenBtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog ofd = new OpenFileDialog();
            ofd.Filter = "All Files (*.*)|*.*|C Files (*.c)|*.c|C++ Files (*.cpp)|*.cpp|Python Files (*.py)|*.py|JS Files (*.js)|*.js|PowerShell Files (*.ps1)|*.ps1|Batch Files (*.bat)|*.bat";
            
            if (ofd.ShowDialog() == DialogResult.OK)
            {
                try
                {
                    string content = File.ReadAllText(ofd.FileName);
                    codeEditor.Text = content;
                    DetectLanguage();
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error: " + ex.Message);
                }
            }
        }

        private void SaveBtn_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(outputBox.Text))
            {
                MessageBox.Show("No output to save!");
                return;
            }

            SaveFileDialog sfd = new SaveFileDialog();
            sfd.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*";
            
            if (sfd.ShowDialog() == DialogResult.OK)
            {
                try
                {
                    File.WriteAllText(sfd.FileName, outputBox.Text);
                    MessageBox.Show("Output saved to: " + sfd.FileName);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error: " + ex.Message);
                }
            }
        }

        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.Run(new MainForm());
        }
    }
}
