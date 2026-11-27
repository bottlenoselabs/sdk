using MyWebApp;

// The slim builder, minimal APIs and source-generated JSON are what work with NativeAOT (used for Release)
var builder = WebApplication.CreateSlimBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options => options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default));

var app = builder.Build();
app.MapGet("/", () => new Greeting("Hello from MyWebApp."));
app.Run();
