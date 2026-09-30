using System;
using System.Collections.Generic;
using Microsoft.Data.Sqlite;
using SmartHome.Core.Models;

namespace SmartHome.Cloud.Services;

public class DeviceStore
{
    private readonly string _connectionString = "Data Source=smart_home.db";

    public DeviceStore()
    {
        InitializeDatabase();
    }

    private void InitializeDatabase()
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = @"
            CREATE TABLE IF NOT EXISTS Devices (
                Id TEXT PRIMARY KEY,
                Name TEXT,
                Type TEXT,
                Status TEXT,
                Brightness INTEGER,
                Temperature REAL,
                LightingMode TEXT,
                KelvinTemp INTEGER,
                PowerOnState TEXT,
                TransitionSpeed REAL,
                HvacMode TEXT,
                LockMode TEXT,
                CameraArmMode TEXT,
                BlindMode TEXT,
                IsOnline INTEGER,
                LastUpdated TEXT
            );
        ";
        command.ExecuteNonQuery();

        // Safely add any new columns to existing SQLite database if missing
        string[] newColumns = {
            "ALTER TABLE Devices ADD COLUMN LightingMode TEXT;",
            "ALTER TABLE Devices ADD COLUMN KelvinTemp INTEGER;",
            "ALTER TABLE Devices ADD COLUMN PowerOnState TEXT;",
            "ALTER TABLE Devices ADD COLUMN TransitionSpeed REAL;",
            "ALTER TABLE Devices ADD COLUMN HvacMode TEXT;",
            "ALTER TABLE Devices ADD COLUMN LockMode TEXT;",
            "ALTER TABLE Devices ADD COLUMN CameraArmMode TEXT;",
            "ALTER TABLE Devices ADD COLUMN BlindMode TEXT;"
        };

        foreach (var alterSql in newColumns)
        {
            try
            {
                var alterCmd = connection.CreateCommand();
                alterCmd.CommandText = alterSql;
                alterCmd.ExecuteNonQuery();
            }
            catch
            {
                // Column already exists
            }
        }

        command.CommandText = "SELECT COUNT(*) FROM Devices;";
        long count = (long)command.ExecuteScalar()!;
        if (count == 0)
        {
            SeedDefaultDevices(connection);
        }
    }

    private void SeedDefaultDevices(SqliteConnection connection)
    {
        var defaults = new List<DeviceState>
        {
            new() { Id = "D001", Name = "Living Room Lights", Type = "light", Status = "ON", Brightness = 90, KelvinTemp = 3500, LightingMode = "Circadian", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D002", Name = "Main AC Unit", Type = "ac", Status = "ON", Temperature = 21.0, HvacMode = "Cool", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D003", Name = "Garage Door", Type = "garage", Status = "OFF", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D004", Name = "Front Porch Camera", Type = "camera", Status = "ON", CameraArmMode = "ArmedAway", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D005", Name = "Motion Sensor", Type = "sensor", Status = "ON", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D006", Name = "Smart RGB Bulb X1", Type = "light", Status = "ON", Brightness = 85, KelvinTemp = 4000, LightingMode = "Standard", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D007", Name = "SafeLock Pro", Type = "lock", Status = "Locked", LockMode = "AutoLock", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D008", Name = "Eco Thermostat Z", Type = "thermostat", Status = "ON", Temperature = 22.0, HvacMode = "Eco", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D009", Name = "HD Ultra Camera", Type = "camera", Status = "ON", CameraArmMode = "ArmedStay", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D010", Name = "Solar Inverter PV", Type = "solar", Status = "ON", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D011", Name = "Home Battery Storage", Type = "battery", Status = "ON", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D012", Name = "Smart Speaker X", Type = "speaker", Status = "ON", IsOnline = true, LastUpdated = DateTime.UtcNow },
            new() { Id = "D013", Name = "Air Purifier Pro", Type = "air_purifier", Status = "ON", IsOnline = true, LastUpdated = DateTime.UtcNow }
        };

        foreach (var dev in defaults)
        {
            SaveDevice(connection, dev);
        }
    }

    private void SaveDevice(SqliteConnection connection, DeviceState state)
    {
        var command = connection.CreateCommand();
        command.CommandText = @"
            INSERT INTO Devices (Id, Name, Type, Status, Brightness, Temperature, LightingMode, KelvinTemp, PowerOnState, TransitionSpeed, HvacMode, LockMode, CameraArmMode, BlindMode, IsOnline, LastUpdated)
            VALUES ($id, $name, $type, $status, $brightness, $temperature, $lightingMode, $kelvinTemp, $powerOnState, $transitionSpeed, $hvacMode, $lockMode, $cameraArmMode, $blindMode, $isOnline, $lastUpdated)
            ON CONFLICT(Id) DO UPDATE SET
                Name = $name,
                Type = $type,
                Status = $status,
                Brightness = $brightness,
                Temperature = $temperature,
                LightingMode = $lightingMode,
                KelvinTemp = $kelvinTemp,
                PowerOnState = $powerOnState,
                TransitionSpeed = $transitionSpeed,
                HvacMode = $hvacMode,
                LockMode = $lockMode,
                CameraArmMode = $cameraArmMode,
                BlindMode = $blindMode,
                IsOnline = $isOnline,
                LastUpdated = $lastUpdated;
        ";
        command.Parameters.AddWithValue("$id", state.Id);
        command.Parameters.AddWithValue("$name", state.Name ?? string.Empty);
        command.Parameters.AddWithValue("$type", state.Type ?? string.Empty);
        command.Parameters.AddWithValue("$status", state.Status ?? string.Empty);
        command.Parameters.AddWithValue("$brightness", (object?)state.Brightness ?? DBNull.Value);
        command.Parameters.AddWithValue("$temperature", (object?)state.Temperature ?? DBNull.Value);
        command.Parameters.AddWithValue("$lightingMode", state.LightingMode ?? "Standard");
        command.Parameters.AddWithValue("$kelvinTemp", (object?)state.KelvinTemp ?? 4000);
        command.Parameters.AddWithValue("$powerOnState", state.PowerOnState ?? "PreviousState");
        command.Parameters.AddWithValue("$transitionSpeed", state.TransitionSpeed);
        command.Parameters.AddWithValue("$hvacMode", state.HvacMode ?? "Cool");
        command.Parameters.AddWithValue("$lockMode", state.LockMode ?? "AutoLock");
        command.Parameters.AddWithValue("$cameraArmMode", state.CameraArmMode ?? "ArmedAway");
        command.Parameters.AddWithValue("$blindMode", state.BlindMode ?? "Manual");
        command.Parameters.AddWithValue("$isOnline", state.IsOnline ? 1 : 0);
        command.Parameters.AddWithValue("$lastUpdated", state.LastUpdated.ToString("o"));
        command.ExecuteNonQuery();
    }

    public void UpdateState(DeviceState state)
    {
        if (string.IsNullOrEmpty(state.Id)) return;
        state.LastUpdated = DateTime.UtcNow;

        using var connection = new SqliteConnection(_connectionString);
        connection.Open();
        SaveDevice(connection, state);
    }

    public DeviceState? GetDevice(string id)
    {
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = "SELECT Id, Name, Type, Status, Brightness, Temperature, LightingMode, KelvinTemp, PowerOnState, TransitionSpeed, HvacMode, LockMode, CameraArmMode, BlindMode, IsOnline, LastUpdated FROM Devices WHERE Id = $id;";
        command.Parameters.AddWithValue("$id", id);

        using var reader = command.ExecuteReader();
        if (reader.Read())
        {
            return new DeviceState
            {
                Id = reader.GetString(0),
                Name = reader.GetString(1),
                Type = reader.GetString(2),
                Status = reader.GetString(3),
                Brightness = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                Temperature = reader.IsDBNull(5) ? null : reader.GetDouble(5),
                LightingMode = reader.IsDBNull(6) ? "Standard" : reader.GetString(6),
                KelvinTemp = reader.IsDBNull(7) ? 4000 : reader.GetInt32(7),
                PowerOnState = reader.IsDBNull(8) ? "PreviousState" : reader.GetString(8),
                TransitionSpeed = reader.IsDBNull(9) ? 1.0 : reader.GetDouble(9),
                HvacMode = reader.IsDBNull(10) ? "Cool" : reader.GetString(10),
                LockMode = reader.IsDBNull(11) ? "AutoLock" : reader.GetString(11),
                CameraArmMode = reader.IsDBNull(12) ? "ArmedAway" : reader.GetString(12),
                BlindMode = reader.IsDBNull(13) ? "Manual" : reader.GetString(13),
                IsOnline = reader.GetInt32(14) == 1,
                LastUpdated = DateTime.Parse(reader.GetString(15))
            };
        }
        return null;
    }

    public DeviceState? ToggleDevice(string id)
    {
        var device = GetDevice(id);
        if (device is not null)
        {
            device.Status = device.Status == "ON" ? "OFF" : "ON";
            UpdateState(device);
            return device;
        }
        return null;
    }

    public List<DeviceState> GetAllDevices()
    {
        var list = new List<DeviceState>();
        using var connection = new SqliteConnection(_connectionString);
        connection.Open();

        var command = connection.CreateCommand();
        command.CommandText = "SELECT Id, Name, Type, Status, Brightness, Temperature, LightingMode, KelvinTemp, PowerOnState, TransitionSpeed, HvacMode, LockMode, CameraArmMode, BlindMode, IsOnline, LastUpdated FROM Devices;";

        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            list.Add(new DeviceState
            {
                Id = reader.GetString(0),
                Name = reader.GetString(1),
                Type = reader.GetString(2),
                Status = reader.GetString(3),
                Brightness = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                Temperature = reader.IsDBNull(5) ? null : reader.GetDouble(5),
                LightingMode = reader.IsDBNull(6) ? "Standard" : reader.GetString(6),
                KelvinTemp = reader.IsDBNull(7) ? 4000 : reader.GetInt32(7),
                PowerOnState = reader.IsDBNull(8) ? "PreviousState" : reader.GetString(8),
                TransitionSpeed = reader.IsDBNull(9) ? 1.0 : reader.GetDouble(9),
                HvacMode = reader.IsDBNull(10) ? "Cool" : reader.GetString(10),
                LockMode = reader.IsDBNull(11) ? "AutoLock" : reader.GetString(11),
                CameraArmMode = reader.IsDBNull(12) ? "ArmedAway" : reader.GetString(12),
                BlindMode = reader.IsDBNull(13) ? "Manual" : reader.GetString(13),
                IsOnline = reader.GetInt32(14) == 1,
                LastUpdated = DateTime.Parse(reader.GetString(15))
            });
        }
        return list;
    }
}
