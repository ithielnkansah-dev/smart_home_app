using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using SmartHome.Cloud.Services;
using SmartHome.Core.Models;

namespace SmartHome.Cloud.Controllers;

public static class DeviceController
{
    public static void MapDeviceEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/devices");

        // GET /api/devices - Get all cached device states
        group.MapGet("/", (DeviceStore store) =>
        {
            return Results.Ok(store.GetAllDevices());
        });

        // POST /api/devices - Register or update a single device state
        group.MapPost("/", (DeviceState state, DeviceStore store) =>
        {
            store.UpdateState(state);
            return Results.Ok(state);
        });

        // POST /api/devices/bulk - Register or update multiple device states at once
        group.MapPost("/bulk", (List<DeviceState> devices, DeviceStore store) =>
        {
            foreach (var dev in devices)
            {
                store.UpdateState(dev);
            }
            return Results.Ok(store.GetAllDevices());
        });

        // GET /api/devices/{id} - Get specific device state by ID
        group.MapGet("/{id}", (string id, DeviceStore store) =>
        {
            var device = store.GetDevice(id);
            return device is not null
                ? Results.Ok(device)
                : Results.NotFound(new ErrorMessage($"Device with ID {id} not found."));
        });

        // GET & POST /api/devices/{id}/toggle - Toggle device ON/OFF state
        group.MapGet("/{id}/toggle", (string id, DeviceStore store) =>
        {
            var updatedDevice = store.ToggleDevice(id);
            return updatedDevice is not null
                ? Results.Ok(updatedDevice)
                : Results.NotFound(new ErrorMessage($"Device with ID {id} not found."));
        });

        group.MapPost("/{id}/toggle", (string id, DeviceStore store) =>
        {
            var updatedDevice = store.ToggleDevice(id);
            return updatedDevice is not null
                ? Results.Ok(updatedDevice)
                : Results.NotFound(new ErrorMessage($"Device with ID {id} not found."));
        });

        // POST /api/devices/{id}/state - Directly update device state
        group.MapPost("/{id}/state", (string id, DeviceState state, DeviceStore store) =>
        {
            state.Id = id;
            store.UpdateState(state);
            return Results.Ok(state);
        });

        // POST /api/devices/command - Handle command dispatch to device
        group.MapPost("/command", (DeviceCommand command, DeviceStore store) =>
        {
            var device = store.GetDevice(command.DeviceId);
            if (device is null)
            {
                return Results.NotFound(new ErrorMessage($"Device with ID {command.DeviceId} not found."));
            }

            if (string.Equals(command.Action, "TogglePower", StringComparison.OrdinalIgnoreCase))
            {
                var toggled = store.ToggleDevice(command.DeviceId);
                return Results.Ok(toggled);
            }
            else if (string.Equals(command.Action, "SetStatus", StringComparison.OrdinalIgnoreCase) && command.Parameters.TryGetValue("status", out var newStatus))
            {
                device.Status = newStatus;
                device.LastUpdated = DateTime.UtcNow;
                store.UpdateState(device);
                return Results.Ok(device);
            }

            return Results.Ok(device);
        });
    }
}
