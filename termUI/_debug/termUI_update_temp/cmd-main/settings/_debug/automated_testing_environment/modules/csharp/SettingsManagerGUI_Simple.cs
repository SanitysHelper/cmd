using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace SettingsManager
{
    public class MainForm : Form
    {
        private DataGridView settingsGrid;
        private RichTextBox logPanel;
        private Button btnView, btnEdit, btnAdd, btnReload, btnSave, btnDebug, btnQuit;
        private string scriptDir;
        private string scriptPath;
        private string settingsFile;
        private bool debugMode = false;

        public MainForm()
        {
            scriptDir = Path.GetDirectoryName(Application.ExecutablePath);
            scriptPath = Path.Combine(scriptDir, "Settings-Manager.ps1");
            settingsFile = Path.Combine(scriptDir, "modules", "config", "settings.ini");

            InitializeComponents();
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
            btnView = CreateButton("1. View All", BtnView_Click);
            btnEdit = CreateButton("2. Edit Setting", BtnEdit_Click);
            btnAdd = CreateButton("3. Add Setting", BtnAdd_Click);
            btnReload = CreateButton("4. Reload", BtnReload_Click);
            btnSave = CreateButton("5. Save", BtnSave_Click);
            btnDebug = CreateButton("6. Debug Menu", BtnDebug_Click);
            btnQuit = CreateButton("7. Quit", BtnQuit_Click);

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

            // Make only Value column editable
            settingsGrid.Columns[0].ReadOnly = true; // Section
            settingsGrid.Columns[1].ReadOnly = true; // Key
            settingsGrid.Columns[2].ReadOnly = false; // Value
            settingsGrid.Columns[3].ReadOnly = true; // Description

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
            this.Click += (s, e) => LogEvent($"Form clicked");
            settingsGrid.CellClick += (s, e) => 
            {
                if (e.RowIndex >= 0 && e.ColumnIndex >= 0)
                    LogEvent($"Cell clicked: Row {e.RowIndex}, Column {settingsGrid.Columns[e.ColumnIndex].Name}");
            };
            settingsGrid.CellValueChanged += (s, e) => 
            {
                if (e.RowIndex >= 0)
                {
                    string key = settingsGrid.Rows[e.RowIndex].Cells[1].Value?.ToString();
                    string newValue = settingsGrid.Rows[e.RowIndex].Cells[2].Value?.ToString();
                    LogEvent($"Value changed: {key} = {newValue}");
                }
            };

            LogEvent("Settings Manager initialized");
        }

        private Button CreateButton(string text, EventHandler clickHandler)
        {
            Button btn = new Button
            {
                Text = text,
                Width = 110,
                Height = 30
            };
            btn.Click += clickHandler;
            btn.Click += (s, e) => LogEvent($"Button clicked: {text}");
            return btn;
        }

        private void LoadSettings()
        {
            try
            {
                LogEvent("Loading settings from file...");

                if (!File.Exists(settingsFile))
                {
                    LogEvent($"ERROR: Settings file not found: {settingsFile}");
                    return;
                }

                // Clear existing rows
                settingsGrid.Rows.Clear();

                // Parse INI file directly (simple parser)
                string currentSection = "";
                foreach (string line in File.ReadAllLines(settingsFile))
                {
                    string trimmed = line.Trim();
                    
                    // Skip empty lines and comments
                    if (string.IsNullOrWhiteSpace(trimmed) || trimmed.StartsWith(";"))
                        continue;

                    // Section header
                    if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
                    {
                        currentSection = trimmed.Substring(1, trimmed.Length - 2);
                        continue;
                    }

                    // Key=Value#Description format
                    if (trimmed.Contains("="))
                    {
                        int equalsIndex = trimmed.IndexOf('=');
                        string key = trimmed.Substring(0, equalsIndex).Trim();
                        string rest = trimmed.Substring(equalsIndex + 1);

                        string value = "";
                        string description = "";

                        // Split value and description
                        if (rest.Contains("#"))
                        {
                            int hashIndex = rest.IndexOf('#');
                            value = rest.Substring(0, hashIndex).Trim();
                            description = rest.Substring(hashIndex + 1).Trim();
                        }
                        else
                        {
                            value = rest.Trim();
                        }

                        settingsGrid.Rows.Add(currentSection, key, value, description);
                    }
                }

                LogEvent($"Loaded {settingsGrid.Rows.Count} settings");
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
                MessageBox.Show("Please select a setting to edit.\n\nTip: You can also directly edit values in the Value column.", 
                    "No Selection", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var row = settingsGrid.SelectedRows[0];
            string section = row.Cells[0].Value?.ToString();
            string key = row.Cells[1].Value?.ToString();
            string currentValue = row.Cells[2].Value?.ToString();

            using (var editForm = new EditSettingForm(section, key, currentValue))
            {
                if (editForm.ShowDialog() == DialogResult.OK)
                {
                    row.Cells[2].Value = editForm.NewValue;
                    LogEvent($"Edited: {section}.{key} = {editForm.NewValue}");
                }
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
                    LogEvent($"Added: {addForm.Section}.{addForm.Key} = {addForm.Value}");
                }
            }
        }

        private void BtnReload_Click(object sender, EventArgs e)
        {
            DialogResult result = MessageBox.Show(
                "Reload settings from file? Unsaved changes will be lost.",
                "Confirm Reload",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (result == DialogResult.Yes)
            {
                LoadSettings();
            }
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            try
            {
                LogEvent("Saving settings to file...");

                // Build INI content from grid
                var sections = new Dictionary<string, List<string>>();

                foreach (DataGridViewRow row in settingsGrid.Rows)
                {
                    string section = row.Cells[0].Value?.ToString();
                    string key = row.Cells[1].Value?.ToString();
                    string value = row.Cells[2].Value?.ToString();
                    string desc = row.Cells[3].Value?.ToString();

                    if (string.IsNullOrWhiteSpace(section) || string.IsNullOrWhiteSpace(key))
                        continue;

                    if (!sections.ContainsKey(section))
                    {
                        sections[section] = new List<string>();
                    }

                    string line = $"{key}={value ?? ""}";
                    if (!string.IsNullOrWhiteSpace(desc))
                    {
                        line += $" # {desc}";
                    }

                    sections[section].Add(line);
                }

                // Write to file
                using (StreamWriter writer = new StreamWriter(settingsFile, false, Encoding.ASCII))
                {
                    foreach (var section in sections)
                    {
                        writer.WriteLine($"[{section.Key}]");
                        foreach (var line in section.Value)
                        {
                            writer.WriteLine(line);
                        }
                        writer.WriteLine(); // Blank line between sections
                    }
                }

                LogEvent($"Settings saved successfully: {settingsGrid.Rows.Count} settings written");
                MessageBox.Show("Settings saved successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                LogEvent($"ERROR: {ex.Message}");
                MessageBox.Show($"Error saving settings:\n{ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnDebug_Click(object sender, EventArgs e)
        {
            debugMode = !debugMode;
            LogEvent($"Debug mode: {(debugMode ? "ON" : "OFF")}");
            
            string debugInfo = $"Debug Mode: {(debugMode ? "ON" : "OFF")}\n\n" +
                $"Script Directory: {scriptDir}\n" +
                $"Settings File: {settingsFile}\n" +
                $"Total Settings: {settingsGrid.Rows.Count}\n" +
                $"Log Entries: {logPanel.Lines.Length}";

            MessageBox.Show(debugInfo, "Debug Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }

        private void BtnQuit_Click(object sender, EventArgs e)
        {
            // Check for unsaved changes (simple check: compare file vs grid)
            DialogResult result = MessageBox.Show(
                "Are you sure you want to quit?",
                "Confirm Quit",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question
            );

            if (result == DialogResult.Yes)
            {
                LogEvent("Quitting application");
                this.Close();
            }
        }

        private void LogEvent(string message)
        {
            string timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            logPanel.AppendText($"[{timestamp}] {message}\n");
            logPanel.SelectionStart = logPanel.Text.Length;
            logPanel.ScrollToCaret();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            base.OnFormClosing(e);
            LogEvent("Application closing");
        }
    }

    public class EditSettingForm : Form
    {
        private TextBox txtValue;
        public string NewValue => txtValue.Text;

        public EditSettingForm(string section, string key, string currentValue)
        {
            this.Text = $"Edit {section}.{key}";
            this.Size = new Size(400, 150);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            TableLayoutPanel layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 2,
                Padding = new Padding(10)
            };

            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40));

            txtValue = new TextBox { Dock = DockStyle.Fill, Text = currentValue };

            layout.Controls.Add(new Label { Text = "New Value:", TextAlign = ContentAlignment.MiddleRight }, 0, 0);
            layout.Controls.Add(txtValue, 1, 0);

            FlowLayoutPanel buttonPanel = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                FlowDirection = FlowDirection.RightToLeft
            };

            Button btnOk = new Button { Text = "OK", Width = 80, DialogResult = DialogResult.OK };
            Button btnCancel = new Button { Text = "Cancel", Width = 80, DialogResult = DialogResult.Cancel };

            buttonPanel.Controls.AddRange(new Control[] { btnCancel, btnOk });
            layout.Controls.Add(buttonPanel, 0, 1);
            layout.SetColumnSpan(buttonPanel, 2);

            this.Controls.Add(layout);
            this.AcceptButton = btnOk;
            this.CancelButton = btnCancel;
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
            this.Size = new Size(450, 250);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;

            TableLayoutPanel layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 5,
                Padding = new Padding(10)
            };

            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 100));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

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

            Button btnOk = new Button { Text = "Add", Width = 80, DialogResult = DialogResult.OK };
            Button btnCancel = new Button { Text = "Cancel", Width = 80, DialogResult = DialogResult.Cancel };

            btnOk.Click += (s, e) => 
            {
                if (string.IsNullOrWhiteSpace(txtSection.Text) || string.IsNullOrWhiteSpace(txtKey.Text))
                {
                    MessageBox.Show("Section and Key are required.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    this.DialogResult = DialogResult.None;
                }
            };

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
