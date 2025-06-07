using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Table
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public int Capacity { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    [Required]
    public bool IsAvailable { get; set; } = true;

    [Required]
    public bool IsDeleted { get; set; }

    public ICollection<Order> Orders { get; set; } = new List<Order>();

    [Key]
    public Guid Id { get; init; } = Guid.CreateVersion7();

    [Required]
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}
