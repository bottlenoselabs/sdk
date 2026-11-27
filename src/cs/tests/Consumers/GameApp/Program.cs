// Copyright (c) Bottlenose Labs Inc. (https://github.com/bottlenoselabs). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the Git repository root directory for full license information.

// Reads an asset from next to the executable, to check that the SDK copied the Assets folder
var assetFilePath = Path.Combine(AppContext.BaseDirectory, "Assets", "Text", "hello.txt");
Console.WriteLine(File.ReadAllText(assetFilePath).Trim());
