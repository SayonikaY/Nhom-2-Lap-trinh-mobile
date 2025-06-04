using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class MenuItem
{
    [Key]
    public Guid Id { get; set; } = Guid.CreateVersion7();

    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    public ItemKind Kind { get; set; }

    [Required]
    public decimal Price { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    [MaxLength(200)]
    public Uri? ImageUrl { get; set; }

    [Required]
    public bool IsAvailable { get; set; } = true;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required]
    public bool IsDeleted { get; set; }
}

public enum ItemKind
{
    [Display(Name = "Main Course")]
    MainCourse,

    [Display(Name = "Appetizer")]
    Appetizer,

    [Display(Name = "Dessert")]
    Dessert,

    [Display(Name = "Beverage")]
    Beverage,
}
