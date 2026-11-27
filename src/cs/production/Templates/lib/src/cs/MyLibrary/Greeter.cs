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
