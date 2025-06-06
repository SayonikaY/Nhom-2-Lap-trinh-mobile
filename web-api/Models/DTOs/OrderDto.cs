using System.ComponentModel.DataAnnotations;

namespace WebApi.Models.DTOs;

public class OrderDto
{
    public Guid Id { get; set; }

    public string Number { get; set; } = null!;

    public Guid TableId { get; set; }

    public string TableName { get; set; } = null!;

    public OrderStatus Status { get; set; }

    public string? Note { get; set; }

    public decimal TotalAmount { get; set; }

    public Guid EmployeeId { get; set; }

    public string EmployeeName { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public List<OrderDetailDto> Items { get; set; } = [];
}

public class OrderDetailDto
{
    public Guid Id { get; set; }

    public Guid MenuItemId { get; set; }

    public string MenuItemName { get; set; } = null!;

    public int Quantity { get; set; }

    public decimal Price { get; set; }

    public decimal TotalPrice { get; set; }
}

public class CreateOrderDto
{
    [Required]
    public Guid TableId { get; set; }

    [MaxLength(500)]
    public string? Note { get; set; }

    [Required]
    [MinLength(1)]
    public List<CreateOrderDetailDto> Items { get; set; } = [];
}

public class CreateOrderDetailDto
{
    [Required]
    public Guid MenuItemId { get; set; }

    [Required]
    [Range(1, 100)]
    public int Quantity { get; set; }
}

public class UpdateOrderStatusDto
{
    [Required]
    public OrderStatus Status { get; set; }
}
