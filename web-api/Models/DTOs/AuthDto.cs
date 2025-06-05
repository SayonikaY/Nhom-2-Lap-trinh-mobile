using System.ComponentModel.DataAnnotations;

namespace WebApi.Models.DTOs;

public class LoginDto
{
    [Required]
    [MaxLength(50)]
    public string Username { get; set; } = null!;

    [Required]
    public string Password { get; set; } = null!;
}

public class LoginResponseDto
{
    public string Token { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public EmployeeDto Employee { get; set; } = null!;
}
