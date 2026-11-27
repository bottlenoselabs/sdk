// Copyright (c) Bottlenose Labs Inc. (https://github.com/bottlenoselabs). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the Git repository root directory for full license information.

using System.Text.Json.Serialization;

namespace MyWebApp;

// Every type returned as JSON needs a [JsonSerializable] line here, so NativeAOT can serialize it without reflection
[JsonSerializable(typeof(Greeting))]
internal sealed partial class AppJsonSerializerContext : JsonSerializerContext;
