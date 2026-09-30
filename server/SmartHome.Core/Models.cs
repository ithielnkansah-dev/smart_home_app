using System;
using System.Collections.Generic;

namespace SmartHome.Core.Models;

public class DeviceState
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty; // e.g., Light, Thermostat, Lock
    public bool IsOnline { get; set; }
    public string Status { get; set; } = string.Empty; // e.g., On, Off, Locked
    public int? Brightness { get; set; }
    public double? Temperature { get; set; }
    public string LightingMode { get; set; } = "Standard";
    public int? KelvinTemp { get; set; } = 4000;
    public string PowerOnState { get; set; } = "PreviousState";
    public double TransitionSpeed { get; set; } = 1.0;
    public string HvacMode { get; set; } = "Cool";
    public string LockMode { get; set; } = "AutoLock";
    public string CameraArmMode { get; set; } = "ArmedAway";
    public string BlindMode { get; set; } = "Manual";
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
}

public class DeviceCommand
{
    public string CommandId { get; set; } = Guid.NewGuid().ToString();
    public string DeviceId { get; set; } = string.Empty;
    public string HomeId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty; // e.g., "TogglePower", "SetBrightness"
    public Dictionary<string, string> Parameters { get; set; } = new();
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
