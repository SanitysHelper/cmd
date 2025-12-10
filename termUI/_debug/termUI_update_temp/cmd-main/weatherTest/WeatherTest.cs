using System;
using System.Collections.Generic;
using System.Drawing;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace WeatherTest
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new WeatherForm());
        }
    }

    public class WeatherForm : Form
    {
        private readonly TextBox _cityInput;
        private readonly Button _fetchButton;
        private readonly TextBox _outputBox;
        private readonly Label _statusLabel;
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();

        public WeatherForm()
        {
            Text = "Weather Test";
            Width = 520;
            Height = 360;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;

            ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

            var cityLabel = new Label
            {
                Text = "City:",
                AutoSize = true,
                Location = new Point(14, 18)
            };

            _cityInput = new TextBox
            {
                Location = new Point(60, 14),
                Width = 320,
                Text = "New York"
            };

            _fetchButton = new Button
            {
                Text = "Fetch Weather",
                Location = new Point(392, 12),
                Width = 100,
                Height = 26
            };
            _fetchButton.Click += OnFetchClicked;

            _outputBox = new TextBox
            {
                Location = new Point(14, 54),
                Width = 478,
                Height = 220,
                ReadOnly = true,
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                Font = new Font("Consolas", 10f, FontStyle.Regular),
                BackColor = Color.White,
                ForeColor = Color.Black
            };

            _statusLabel = new Label
            {
                Text = "Status: idle",
                AutoSize = true,
                Location = new Point(14, 290),
                ForeColor = Color.Gray
            };

            Controls.Add(cityLabel);
            Controls.Add(_cityInput);
            Controls.Add(_fetchButton);
            Controls.Add(_outputBox);
            Controls.Add(_statusLabel);
        }

        private void OnFetchClicked(object sender, EventArgs e)
        {
            var city = _cityInput.Text.Trim();
            if (string.IsNullOrWhiteSpace(city))
            {
                ShowStatus("Please enter a city name.", isError: true);
                return;
            }

            _fetchButton.Enabled = false;
            ShowStatus("Fetching weather...", isError: false);
            _outputBox.Text = string.Empty;

            Task.Factory.StartNew(() => FetchWeather(city))
                .ContinueWith(t => HandleResult(t), TaskScheduler.FromCurrentSynchronizationContext());
        }

        private WeatherResult FetchWeather(string city)
        {
            try
            {
                var geo = LookupCoordinates(city);
                if (!geo.Success)
                {
                    return WeatherResult.Error(geo.Message);
                }

                var forecast = GetForecast(geo.Latitude, geo.Longitude);
                if (!forecast.Success)
                {
                    return WeatherResult.Error(forecast.Message);
                }

                var sb = new StringBuilder();
                sb.AppendLine("Location: " + geo.DisplayName);
                sb.AppendLine("Latitude: " + geo.Latitude.ToString("F4") + ", Longitude: " + geo.Longitude.ToString("F4"));
                sb.AppendLine("Temperature: " + forecast.Temperature + " C");
                sb.AppendLine("Wind Speed: " + forecast.WindSpeed + " m/s");
                sb.AppendLine("Wind Direction: " + forecast.WindDirection + " deg");
                sb.AppendLine("Time: " + forecast.Time);

                return WeatherResult.Ok(sb.ToString());
            }
            catch (Exception ex)
            {
                return WeatherResult.Error("Failed: " + ex.Message);
            }
        }

        private void HandleResult(Task<WeatherResult> task)
        {
            try
            {
                if (task.IsFaulted)
                {
                    var ex = task.Exception;
                    var message = ex != null ? ex.GetBaseException().Message : "Unknown error";
                    ShowStatus("Unhandled error: " + message, true);
                    return;
                }

                var result = task.Result;
                if (!result.Success)
                {
                    ShowStatus(result.Message, isError: true);
                    return;
                }

                _outputBox.Text = result.Message;
                ShowStatus("Fetch complete.", isError: false);
            }
            finally
            {
                _fetchButton.Enabled = true;
            }
        }

        private GeoResult LookupCoordinates(string city)
        {
            var url = "https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + Uri.EscapeDataString(city);
            var json = DownloadString(url);
            var geo = _serializer.Deserialize<GeocodingResponse>(json);

            if (geo == null || geo.results == null || geo.results.Count == 0)
            {
                return GeoResult.Error("No results for that city.");
            }

            var top = geo.results[0];
            var display = top.name;
            if (!string.IsNullOrWhiteSpace(top.country))
            {
                display += ", " + top.country;
            }

            return GeoResult.Ok(top.latitude, top.longitude, display);
        }

        private ForecastResult GetForecast(double latitude, double longitude)
        {
            var url = "https://api.open-meteo.com/v1/forecast?current_weather=true&latitude=" + latitude.ToString("F4") + "&longitude=" + longitude.ToString("F4");
            var json = DownloadString(url);
            var forecast = _serializer.Deserialize<ForecastResponse>(json);

            if (forecast == null || forecast.current_weather == null)
            {
                return ForecastResult.Error("Weather data missing.");
            }

            return ForecastResult.Ok(
                forecast.current_weather.temperature,
                forecast.current_weather.windspeed,
                forecast.current_weather.winddirection,
                forecast.current_weather.time
            );
        }

        private string DownloadString(string url)
        {
            using (var client = new WebClient())
            {
                client.Headers["User-Agent"] = "weather-test";
                return client.DownloadString(url);
            }
        }

        private void ShowStatus(string message, bool isError)
        {
            _statusLabel.Text = "Status: " + message;
            _statusLabel.ForeColor = isError ? Color.Red : Color.Gray;
        }
    }

    public class WeatherResult
    {
        public bool Success { get; private set; }
        public string Message { get; private set; }

        private WeatherResult() { }

        public static WeatherResult Ok(string message)
        {
            return new WeatherResult { Success = true, Message = message };
        }

        public static WeatherResult Error(string message)
        {
            return new WeatherResult { Success = false, Message = message };
        }
    }

    public class GeoResult
    {
        public bool Success { get; private set; }
        public string Message { get; private set; }
        public double Latitude { get; private set; }
        public double Longitude { get; private set; }
        public string DisplayName { get; private set; }

        private GeoResult() { }

        public static GeoResult Ok(double latitude, double longitude, string displayName)
        {
            return new GeoResult
            {
                Success = true,
                Latitude = latitude,
                Longitude = longitude,
                DisplayName = displayName,
                Message = ""
            };
        }

        public static GeoResult Error(string message)
        {
            return new GeoResult { Success = false, Message = message };
        }
    }

    public class ForecastResult
    {
        public bool Success { get; private set; }
        public string Message { get; private set; }
        public double Temperature { get; private set; }
        public double WindSpeed { get; private set; }
        public double WindDirection { get; private set; }
        public string Time { get; private set; }

        private ForecastResult() { }

        public static ForecastResult Ok(double temperature, double windSpeed, double windDirection, string time)
        {
            return new ForecastResult
            {
                Success = true,
                Temperature = temperature,
                WindSpeed = windSpeed,
                WindDirection = windDirection,
                Time = time,
                Message = ""
            };
        }

        public static ForecastResult Error(string message)
        {
            return new ForecastResult { Success = false, Message = message };
        }
    }

    public class GeocodingResponse
    {
        public List<GeocodingResult> results { get; set; }
    }

    public class GeocodingResult
    {
        public string name { get; set; }
        public string country { get; set; }
        public double latitude { get; set; }
        public double longitude { get; set; }
    }

    public class ForecastResponse
    {
        public CurrentWeather current_weather { get; set; }
    }

    public class CurrentWeather
    {
        public double temperature { get; set; }
        public double windspeed { get; set; }
        public double winddirection { get; set; }
        public string time { get; set; }
    }
}
