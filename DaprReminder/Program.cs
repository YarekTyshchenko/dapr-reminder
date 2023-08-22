using Dapr.Actors;
using Dapr.Actors.Client;
using DaprReminder.Actor;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddActors(options =>
{
    // Register actor types and configure actor settings
    options.Actors.RegisterActor<CronActor>();
    // options.ReentrancyConfig = new Dapr.Actors.ActorReentrancyConfig
    // {
    //     Enabled = true,
    //     MaxStackDepth = 32,
    // };
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapActorsHandlers();
app.Map("/create", async context =>
{
    const string actorType = nameof(CronActor);
    await Task.WhenAll(Enumerable.Range(1, 10).Select(async i =>
    {
        // Create the local proxy by using the same interface that the service implements.
        // You need to provide the type and id so the actor can be located.
        var actorId = new ActorId(i.ToString());
        var proxy = ActorProxy.Create<ICronActor>(actorId, actorType);

        // Now you can use the actor interface to call the actor's methods.
        Console.WriteLine($"Calling StartAsync on {actorType}:{actorId}...");

        await proxy.CreateAsync();
        Console.WriteLine($"Got response {actorId}:{actorId}");
    }).ToArray());
});

app.Run();
