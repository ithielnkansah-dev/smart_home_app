using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SmartHome.Cloud.Controllers;
using SmartHome.Cloud.Hubs;
using SmartHome.Cloud.Services;
using SmartHome.Core.Models;

var builder = WebApplication.CreateSlimBuilder(args);

// Add the DeviceStore as a singleton
builder.Services.AddSingleton<DeviceStore>();

// Configure HTTP JSON options for Minimal APIs to use Native AOT Source Generator
builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolver = AppJsonSerializerContext.Default;
});

// Add SignalR and configure the JSON protocol to use Native AOT Source Generator
builder.Services.AddSignalR()
    .AddJsonProtocol(options =>
    {
        options.PayloadSerializerOptions.TypeInfoResolver = AppJsonSerializerContext.Default;
    });

var app = builder.Build();

// Map SignalR Hub
app.MapHub<SmartHomeHub>("/hubs/smarthome");

// Map RESTful Minimal API Endpoints (DeviceController)
app.MapDeviceEndpoints();

// Root endpoint
app.MapGet("/", () => "Smart Home Cloud Relay is running (.NET 10 Native AOT)");

app.Run();

// Native AOT JSON Source Generator Context
[JsonSerializable(typeof(DeviceState))]
[JsonSerializable(typeof(DeviceCommand))]
[JsonSerializable(typeof(List<DeviceState>))]
[JsonSerializable(typeof(Dictionary<string, string>))]
[JsonSerializable(typeof(string))]
[JsonSerializable(typeof(ErrorMessage))]
public partial class AppJsonSerializerContext : JsonSerializerContext
{
}

public record ErrorMessage(string Message);
