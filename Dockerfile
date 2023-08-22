FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS runtime
WORKDIR /app

COPY DaprReminder/bin/Debug/net7.0/publish/ ./

ENTRYPOINT ["dotnet", "DaprReminder.dll"]
