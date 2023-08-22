// <copyright file="ICronActor.cs" company="HARK">
// Copyright (c) HARK. All rights reserved.
// </copyright>

namespace DaprReminder.Actor;

using Dapr.Actors;

public interface ICronActor : IActor
{
    Task CreateAsync();
}
