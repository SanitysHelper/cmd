using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SettingsManager
{
    public class MainForm : Form
    {
        private DataGridView settingsGrid;
        private RichTextBox logPanel;
        private Button btnView, btnEdit, btnAdd, btnReload, btnSave, btnDebug, btnQuit;
        private Runspace runspace;
        private string scriptPath;
        private bool debugMode = false;

        public MainForm()
        {
            InitializeComponents();
            InitializePowerShell();
            LoadSettings();
        }

        private void InitializeComponents()
        {
            // Form settings
            this.Text = "Settings Manager";
            this.Size = new Size(1024, 768);
            this.StartPosition = FormStartPosition.CenterScreen;

            // Create panel for buttons
            FlowLayoutPanel buttonPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 50,
                FlowDirection = FlowDirection.LeftToRight,
                Padding = new Padding(10)
            };

            // Create buttons
            btnView = CreateButton("View All", BtnView_Click);
            btnEdit = CreateButton("Edit Setting", BtnEdit_Click);
            btnAdd = CreateButton("Add Setting", BtnAdd_Click);
            btnReload = CreateButton("Reload", BtnReload_Click);
            btnSave = CreateButton("Save", BtnSave_Click);
            btnDebug = CreateButton("Debug Menu", BtnDebug_Click);
            btnQuit = CreateButton("Quit", BtnQuit_Click);

            buttonPanel.Controls.AddRange(new Control[] { 
                btnView, btnEdit, btnAdd, btnReload, btnSave, btnDebug, btnQuit 
            });

            // Create DataGridView for settings
            settingsGrid = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                ReadOnly = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect
            };

            settingsGrid.Columns.Add("Section", "Section");
            settingsGrid.Columns.Add("Key", "Key");
            settingsGrid.Columns.Add("Value", "Value");
            settingsGrid.Columns.Add("Description", "Description");

            // Create log panel
            logPanel = new RichTextBox
            {
                Dock = DockStyle.Bottom,
                Height = 150,
                ReadOnly = true,
                BackColor = Color.Black,
                ForeColor = Color.LimeGreen,
                Font = new Font("Consolas", 9),
                ScrollBars = RichTextBoxScrollBars.Vertical
            };

            // Add controls to form
            this.Controls.Add(settingsGrid);
            this.Controls.Add(buttonPanel);
            this.Controls.Add(logPanel);

            // Wire up event handlers for logging
            this.KeyPress += (s, e) => LogEvent($"KeyPress: {e.KeyChar}");
            this.Click += (s, e) => LogEvent($"Form clicked at ({e.X}, {e.Y})");
            settingsGrid.CellClick += (s, e) => LogEvent($"Cell clicked: [{e.RowIndex}, {e.ColumnIndex}]");
            settingsGrid.CellValueChanged += (s, e) => LogEvent($"Cell changed: [{e.RowIndex}, {e.ColumnIndex}]");
        }

        private Button CreateButton(string text, EventHandler clickHandler)
        {
            Button btn = new Button
            {
                Text = text,
                Width = 100,
                Height = 30
            };
            btn.Click += clickHandler;
            btn.Click += (s, e) => LogEvent($"Button clicked: {text}");
            return btn;
        }

        private void InitializePowerShell()
        {
            try
            {
                // Get script directory
                string exeDir = Path.GetDirectoryName(Application.ExecutablePath);
                scriptPath = Path.Combine(exeDir, "Settings-Manager.ps1");

                // Create runspace
                runspace = RunspaceFactory.CreateRunspace();
                runspace.Open();

                LogEvent("PowerShell runspace initialized");
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: Failed to initialize PowerShell: {ex.Message}");
            }
        }

        private void LoadSettings()
        {
            try
            {
                LogEvent("Loading settings...");

                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = runspace;
                    ps.AddCommand(scriptPath);
                    ps.AddParameter("Operation", "LoadSettings");

                    var results = ps.Invoke();

                    if (ps.HadErrors)
                    {
                        foreach (var error in ps.Streams.Error)
                        {
                            LogEvent($"ERROR: {error}");
                        }
                        return;
                    }

                    // Clear existing rows
                    settingsGrid.Rows.Clear();

                    // Parse results (assuming hashtable structure)
                    if (results.Count > 0 && results[0].BaseObject is System.Collections.Hashtable settings)
                    {
                        foreach (System.Collections.DictionaryEntry entry in settings)
                        {
                            string section = entry.Key.ToString();
                            if (entry.Value is System.Collections.Hashtable sectionData)
                            {
                                foreach (System.Collections.DictionaryEntry setting in sectionData)
                                {
                                    string key = setting.Key.ToString();
                                    if (setting.Value is System.Collections.Hashtable settingDetails)
                                    {
                                        string value = settingDetails.ContainsKey("Value") 
                                            ? settingDetails["Value"].ToString() 
                                            : "";
                                        string desc = settingDetails.ContainsKey("Description") 
                                            ? settingDetails["Description"].ToString() 
                                            : "";

                                        settingsGrid.Rows.Add(section, key, value, desc);
                                    }
                                }
                            }
                        }
                    }

                    LogEvent($"Loaded {settingsGrid.Rows.Count} settings");
                }
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: {ex.Message}");
            }
        }

        private void BtnView_Click(object sender, EventArgs e)
        {
            LoadSettings();
        }

        private void BtnEdit_Click(object sender, EventArgs e)
        {
            if (settingsGrid.SelectedRows.Count == 0)
            {
                MessageBox.Show("Please select a setting to edit", "No Selection");
                return;
            }

            var row = settingsGrid.SelectedRows[0];
            string section = row.Cells[0].Value?.ToString();
            string key = row.Cells[1].Value?.ToString();
            string currentValue = row.Cells[2].Value?.ToString();

            string newValue = Microsoft.VisualBasic.Interaction.InputBox(
                $"Edit {section}.{key}:",
                "Edit Setting",
                currentValue
            );

            if (!string.IsNullOrWhiteSpace(newValue))
            {
                row.Cells[2].Value = newValue;
                LogEvent($"Edited: {section}.{key} = {newValue}");
            }
        }

        private void BtnAdd_Click(object sender, EventArgs e)
        {
            using (var addForm = new AddSettingForm())
            {
                if (addForm.ShowDialog() == DialogResult.OK)
                {
                    settingsGrid.Rows.Add(
                        addForm.Section,
                        addForm.Key,
                        addForm.Value,
                        addForm.Description
                    );
                    LogEvent($"Added: {addForm.Section}.{addForm.Key}");
                }
            }
        }

        private void BtnReload_Click(object sender, EventArgs e)
        {
            LoadSettings();
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            try
            {
                LogEvent("Saving settings...");

                // Build hashtable from grid
                var settings = new System.Collections.Hashtable();

                foreach (DataGridViewRow row in settingsGrid.Rows)
                {
                    string section = row.Cells[0].Value?.ToString();
                    string key = row.Cells[1].Value?.ToString();
                    string value = row.Cells[2].Value?.ToString();
                    string desc = row.Cells[3].Value?.ToString();

                    if (string.IsNullOrWhiteSpace(section) || string.IsNullOrWhiteSpace(key))
                        continue;

                    if (!settings.ContainsKey(section))
                    {
                        settings[section] = new System.Collections.Hashtable();
                    }

                    var sectionHash = (System.Collections.Hashtable)settings[section];
                    sectionHash[key] = new System.Collections.Hashtable
                    {
                        ["Value"] = value ?? "",
                        ["Description"] = desc ?? ""
                    };
                }

                // Call PowerShell save function
                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = runspace;
                    ps.AddCommand(scriptPath);
                    ps.AddParameter("Operation", "SaveSettings");
                    ps.AddParameter("Parameters", new System.Collections.Hashtable { ["Settings"] = settings });

                    ps.Invoke();

                    if (ps.HadErrors)
                    {
                        foreach (var error in ps.Streams.Error)
                        {
                            LogEvent($"ERROR: {error}");
                        }
                    }
                    else
                    {
                        LogEvent("Settings saved successfully");
                    }
                }
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: {ex.Message}");
            }
        }

        private void BtnDebug_Click(object sender, EventArgs e)
        {
            debugMode = !debugMode;
            LogEvent($"Debug mode: {(debugMode ? "ON" : "OFF")}");
            MessageBox.Show($"Debug mode: {(debugMode ? "ON" : "OFF")}", "Debug");
        }

        private void BtnQuit_Click(object sender, EventArgs e)
        {
            LogEvent("Quitting application");
            this.Close();
        }

        private void LogEvent(string message)
        {
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            logPanel.AppendText($"[{timestamp}] {message}\n");
            logPanel.ScrollToCaret();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            base.OnFormClosing(e);
            
            try
            {
                // Cleanup PowerShell
                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = runspace;
                    ps.AddCommand(scriptPath);
                    ps.AddParameter("Operation", "Cleanup");
                    ps.Invoke();
                }

                runspace?.Close();
                runspace?.Dispose();
            }
            catch { }
        }
    }

    public class AddSettingForm : Form
    {
        private TextBox txtSection, txtKey, txtValue, txtDescription;
        public string Section => txtSection.Text;
        public string Key => txtKey.Text;
        public string Value => txtValue.Text;
        public string Description => txtDescription.Text;

        public AddSettingForm()
        {
            this.Text = "Add New Setting";
            this.Size = new Size(400, 250);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;

            TableLayoutPanel layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 5,
                Padding = new Padding(10)
            };

            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 60));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40));

            txtSection = new TextBox { Dock = DockStyle.Fill };
            txtKey = new TextBox { Dock = DockStyle.Fill };
            txtValue = new TextBox { Dock = DockStyle.Fill };
            txtDescription = new TextBox { Dock = DockStyle.Fill, Multiline = true };

            layout.Controls.Add(new Label { Text = "Section:", TextAlign = ContentAlignment.MiddleRight }, 0, 0);
            layout.Controls.Add(txtSection, 1, 0);
            layout.Controls.Add(new Label { Text = "Key:", TextAlign = ContentAlignment.MiddleRight }, 0, 1);
            layout.Controls.Add(txtKey, 1, 1);
            layout.Controls.Add(new Label { Text = "Value:", TextAlign = ContentAlignment.MiddleRight }, 0, 2);
            layout.Controls.Add(txtValue, 1, 2);
            layout.Controls.Add(new Label { Text = "Description:", TextAlign = ContentAlignment.MiddleRight }, 0, 3);
            layout.Controls.Add(txtDescription, 1, 3);

            FlowLayoutPanel buttonPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                FlowDirection = FlowDirection.RightToLeft
            };

            Button btnOk = new Button { Text = "OK", Width = 80, DialogResult = DialogResult.OK };
            Button btnCancel = new Button { Text = "Cancel", Width = 80, DialogResult = DialogResult.Cancel };

            buttonPanel.Controls.AddRange(new Control[] { btnCancel, btnOk });
            layout.Controls.Add(buttonPanel, 0, 4);
            layout.SetColumnSpan(buttonPanel, 2);

            this.Controls.Add(layout);
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;
        }
    }

    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
