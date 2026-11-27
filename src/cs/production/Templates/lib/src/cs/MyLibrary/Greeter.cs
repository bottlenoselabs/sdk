// Copyright (c) Bottlenose Labs Inc. (https://github.com/bottlenoselabs). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the Git repository root directory for full license information.

namespace MyLibrary;

/// <summary>
///     Greets people.
/// </summary>
public static class Greeter
{
    /// <summary>
    ///     Returns a greeting for a person.
    /// </summary>
    /// <param name="name">The name of the person to greet.</param>
    /// <returns>The greeting.</returns>
    public static string Greet(string name)
    {
        ArgumentNullException.ThrowIfNull(name);
        return "Hello, " + name + "!";
    }
}
