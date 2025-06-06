using System.ComponentModel.DataAnnotations;

namespace WebApi.Models.DTOs;

public class MenuItemDto
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public ItemKind Kind { get; set; }

    public decimal Price { get; set; }

    public string? Description { get; set; }

    public Uri? ImageUrl { get; set; }

    public bool IsAvailable { get; set; }

    public DateTime CreatedAt { get; set; }
}

public class CreateMenuItemDto
{
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = null!;

    [Required]
    public ItemKind Kind { get; set; }

    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public Uri? ImageUrl { get; set; }
}

public class UpdateMenuItemDto
{
    [MaxLength(100)]
    public string? Name { get; set; }

    public ItemKind? Kind { get; set; }

    [Range(0.01, double.MaxValue)]
    public decimal? Price { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public Uri? ImageUrl { get; set; }

    public bool? IsAvailable { get; set; }
}
