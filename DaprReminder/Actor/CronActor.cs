// <copyright file="ReminderActor.cs" company="HARK">
// Copyright (c) HARK. All rights reserved.
// </copyright>

namespace DaprReminder.Actor;

using Cronos;
using Dapr.Actors.Runtime;

public class CronActor : Actor, ICronActor, IRemindable
{
    private readonly CronExpression cron;
    private readonly TimeZoneInfo timeZone;
    public const string State = nameof(State);
    public const string NextOccurrenceReminder = nameof(NextOccurrenceReminder);

    /// <inheritdoc />
    public CronActor(
        ActorHost host)
        : base(host)
    {
        cron = CronExpression.Parse("* * * * *");
        timeZone = TimeZoneInfo.FindSystemTimeZoneById("UTC");
    }

    protected override async Task OnActivateAsync()
    {
        // Provides opportunity to perform some optional setup.
        var state = await this.StateManager.TryGetStateAsync<CronActorState>(State);
        Logger.LogInformation(
            "Activating actor id: {Id} with state {State}",
            Id,
            state.Value);
    }

    protected override Task OnDeactivateAsync()
    {
        // Provides opportunity to perform optional cleanup.
        Logger.LogInformation("Deactivating actor id: {Id}", Id);
        return Task.CompletedTask;
    }

    /// <inheritdoc />
    public async Task CreateAsync()
    {
        // Create an instance of the actor and setup reminder
        Logger.LogInformation("Starting Actor {Id}", this.Id);
        await this.CreateReminder(DateTime.UtcNow);
    }

    private async Task CreateReminder(DateTime now)
    {
        var nextOccurrenceUtc = cron.GetNextOccurrence(now, timeZone);
        if (nextOccurrenceUtc == null)
        {
            Logger.LogError("Actor {Id} Unable to calculate Next Occurence", this.Id);
            return;
        }

        // Execute now if we missed the deadline
        var dueTime = now >= nextOccurrenceUtc.Value
            ? TimeSpan.Zero
            : nextOccurrenceUtc.Value - now;

        Logger.LogInformation(
            "{Id} will fire in {Due} ({Next})",
            this.Id,
            nextOccurrenceUtc,
            dueTime);

        // TODO: Should state be supporting setting Reminders somehow?
        // await this.StateManager.SetStateAsync(State, new CronActorState(
        //     now,
        //     nextOccurrenceUtc.Value,
        //     dueTime));

        // TODO: Two ways to set reminders, either overwrite, or create new
        await this.RegisterReminderAsync(
            //$"{NextOccurrenceReminder}-{nextOccurrenceUtc.Value:O}",
            NextOccurrenceReminder,
            null,
            dueTime,
            TimeSpan.FromMilliseconds(-1));
    }

    /// <inheritdoc />
    public async Task ReceiveReminderAsync(
        string reminderName,
        byte[] state,
        TimeSpan dueTime,
        TimeSpan period)
    {
        Logger.LogInformation(
            "Firing reminder {Name} from Actor {Id}, Due: {Due}",
            reminderName,
            this.Id,
            dueTime);
        // var stateResult = await this.StateManager.TryGetStateAsync<CronActorState>(State);
        // if (!stateResult.HasValue)
        // {
        //     Logger.LogError("Actor {Id} executing reminder but has no state", this.Id);
        //     return;
        // }
        var now = DateTime.UtcNow;
        // var nextOccurrenceUtc = cron.GetNextOccurrence(
        //     stateResult.Value.LastEvaluationUtc,
        //     timeZone);
        //
        // if (now < nextOccurrenceUtc)
        // {
        //     // Reminder fired too early? No this doesn't make sense.
        //     return;
        // }

        await this.CreateReminder(now);
    }

    public sealed record CronActorState(
        DateTime LastEvaluationUtc,
        DateTime NextEvaluationUtc,
        TimeSpan DueTime);
}
