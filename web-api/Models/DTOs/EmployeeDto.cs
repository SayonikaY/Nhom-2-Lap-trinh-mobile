using System.ComponentModel.DataAnnotations;

namespace WebApi.Models.DTOs;

public class EmployeeDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = null!;

    public string Username { get; set; } = null!;

    public DateTime CreatedAt { get; set; }
}

public class CreateEmployeeDto
{
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    public string Username { get; set; } = null!;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = null!;
}
