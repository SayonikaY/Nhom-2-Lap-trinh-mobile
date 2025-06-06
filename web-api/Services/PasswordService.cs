using System.Security.Cryptography;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;

namespace WebApi.Services;

public interface IPasswordService
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string hash);
}

public class PasswordService : IPasswordService
{
    public string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(128 / 8);
        var hashedPassword = KeyDerivation.Pbkdf2(password, salt,
            KeyDerivationPrf.HMACSHA256, 800_000, 256 / 8);

        return $"{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hashedPassword)}";
    }

    public bool VerifyPassword(string password, string hash)
    {
        var parts = hash.Split(':');
        if (parts.Length != 2)
            throw new ArgumentException("Invalid hash format");

        var salt = Convert.FromBase64String(parts[0]);
        var storedHash = Convert.FromBase64String(parts[1]);

        var hashedPassword = KeyDerivation.Pbkdf2(password, salt,
            KeyDerivationPrf.HMACSHA256, 800_000, 256 / 8);

        return hashedPassword.SequenceEqual(storedHash);
    }
}
