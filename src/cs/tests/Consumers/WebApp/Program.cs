// Copyright (c) Bottlenose Labs Inc. (https://github.com/bottlenoselabs). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the Git repository root directory for full license information.

// Minimal API with the slim builder: the NativeAOT-compatible way to write an ASP.NET Core app
var builder = WebApplication.CreateSlimBuilder(args);
var app = builder.Build();
app.MapGet("/", () => "Hello from the web consumer project.");
app.Run();
