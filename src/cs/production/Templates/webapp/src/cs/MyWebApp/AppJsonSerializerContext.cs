using System.Text.Json.Serialization;

namespace MyWebApp;

// Every type returned as JSON needs a [JsonSerializable] line here, so NativeAOT can serialize it without reflection
[JsonSerializable(typeof(Greeting))]
internal sealed partial class AppJsonSerializerContext : JsonSerializerContext;
