// Copyright (c) Bottlenose Labs Inc. (https://github.com/bottlenoselabs). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the Git repository root directory for full license information.

using MyWebApp;

// The slim builder, minimal APIs and source-generated JSON are what work with NativeAOT (used for Release)
var builder = WebApplication.CreateSlimBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options => options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default));

var app = builder.Build();
app.MapGet("/", () => new Greeting("Hello from MyWebApp."));
app.Run();
