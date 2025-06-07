using System.ComponentModel.DataAnnotations;

namespace WebApi.Models.DTOs;

public class TableDto
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public int Capacity { get; set; }

    public string? Description { get; set; }

    public bool IsAvailable { get; set; }

    public DateTime CreatedAt { get; set; }

    public OrderDto? CurrentOrder { get; set; }
}

public class CreateTableDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = null!;

    [Required]
    [Range(1, 20)]
    public int Capacity { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }
}

public class UpdateTableDto
{
    [MaxLength(100)]
    public string? Name { get; set; }

    [Range(1, 20)]
    public int? Capacity { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool? IsAvailable { get; set; }
}
