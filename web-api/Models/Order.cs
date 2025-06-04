using System.ComponentModel.DataAnnotations;

namespace WebApi.Models;

public class Order
{
    [Key]
    public Guid Id { get; set; } = Guid.CreateVersion7();

    [Required]
    [MaxLength(100)]
    public string Number { get; set; } = string.Empty;

    public Table Table { get; set; } = null!;
    [Required]
    public Guid TableId { get; set; }

    [Required]
    public OrderStatus Status { get; set; } = OrderStatus.Pending;

    [MaxLength(500)]
    public string? Note { get; set; }

    [Required]
    public decimal TotalAmount { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [Required]
    public bool IsDeleted { get; set; }

    public ICollection<OrderDetail> Items { get; set; } = new List<OrderDetail>();

    public static string CreateNumber()
        => $"ORD-{DateTime.UtcNow:yyMMdd}-{Guid.NewGuid().ToString()[..8]}";
}

public enum OrderStatus
{
    [Display(Name = "Pending")]
    Pending,

    [Display(Name = "In Progress")]
    InProgress,

    [Display(Name = "Completed")]
    Completed,

    [Display(Name = "Cancelled")]
    Cancelled,
}

public class OrderDetail
{
    [Key]
    public Guid Id { get; set; } = Guid.CreateVersion7();

    public Order Order { get; set; } = null!;
    [Required]
    public Guid OrderId { get; set; }

    public MenuItem MenuItem { get; set; } = null!;
    [Required]
    public Guid MenuItemId { get; set; }

    [Required]
    public int Quantity { get; set; } = 1;

    [Required]
    public decimal Price { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public decimal TotalPrice => Quantity * Price;
}
