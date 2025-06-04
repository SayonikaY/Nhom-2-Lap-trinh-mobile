using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Table
{
    [Key]
    public Guid Id { get; set; } = Guid.CreateVersion7();

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int Capacity { get; set; } = 0;

    [MaxLength(500)]
    public string? Description { get; set; } = null;

    [Required]
    public bool IsAvailable { get; set; } = true;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required]
    public bool IsDeleted { get; set; } = false;
}
