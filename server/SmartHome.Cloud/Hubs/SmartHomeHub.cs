using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using SmartHome.Core.Models;
using SmartHome.Cloud.Services;

namespace SmartHome.Cloud.Hubs;

public class SmartHomeHub : Hub
{
    private readonly DeviceStore _deviceStore;

    public SmartHomeHub(DeviceStore deviceStore)
    {
        _deviceStore = deviceStore;
    }

    /// <summary>
    /// Registers a connection into a specific group based on HomeId and role.
    /// role should be either "App" or "Bridge".
    /// </summary>
    public async Task JoinHomeGroup(string homeId, string role)
    {
        if (string.IsNullOrWhiteSpace(homeId) || string.IsNullOrWhiteSpace(role))
        {
            throw new HubException("HomeId and role must be provided.");
        }

        // Add client to their own group: e.g., "home123:App" or "home123:Bridge"
        string groupName = $"{homeId}:{role}";
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);

        // Notify caller of successful registration
        await Clients.Caller.SendAsync("Notification", $"Joined group: {groupName}");
    }

    /// <summary>
    /// Relays a command from an App client to the Local Bridge group for that HomeId.
    /// </summary>
    public async Task SendCommandToBridge(string homeId, DeviceCommand command)
    {
        if (string.IsNullOrWhiteSpace(homeId))
        {
            throw new HubException("HomeId is required to relay commands.");
        }

        string targetGroup = $"{homeId}:Bridge";
        await Clients.Group(targetGroup).SendAsync("ReceiveCommand", command);
    }

    /// <summary>
    /// Relays a state update from a Local Bridge client to the App group for that HomeId,
    /// and caches it in the server store for RESTful queries.
    /// </summary>
    public async Task SendStateToApp(string homeId, DeviceState state)
    {
        if (string.IsNullOrWhiteSpace(homeId))
        {
            throw new HubException("HomeId is required to relay state updates.");
        }

        // Cache the state in the DeviceStore for REST queries
        _deviceStore.UpdateState(state);

        string targetGroup = $"{homeId}:App";
        await Clients.Group(targetGroup).SendAsync("ReceiveStateUpdate", state);
    }
}
