using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Employee
{
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = null!;

    [Required]
    [MaxLength(50)]
    public string Username { get; set; } = null!;

    [Required]
    [MaxLength(100)]
    public string PasswordHash { get; set; } = null!;

    [Required]
    public bool IsDeleted { get; set; }

    [Key]
    public Guid Id { get; init; } = Guid.CreateVersion7();

    [Required]
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}
