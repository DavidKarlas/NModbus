# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
ARG RUNTIME=linux-musl-x64
WORKDIR /src

# Copy only project files for caching
COPY ["Samples/Samples.csproj", "Samples/"]

# Restore dependencies
RUN dotnet restore \
    "./Samples/Samples.csproj" \
    -r "$RUNTIME"

# Copy the entire source after restore to prevent re-restoring
COPY . .

# Publish the application
RUN dotnet publish \
    "./Samples/Samples.csproj" \
    -c "$BUILD_CONFIGURATION" \
    -r "$RUNTIME" \
    --self-contained false \
    -o /app/publish \
    /p:UseAppHost=false \
    /p:PublishReadyToRun=true

# Final Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT false
RUN apk add --no-cache icu-libs tzdata

WORKDIR /app
USER app
EXPOSE 1503

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Samples.dll"]