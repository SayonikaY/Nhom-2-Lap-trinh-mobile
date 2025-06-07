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

public class EmployeeSalesSummaryDto
{
    public Guid EmployeeId { get; set; }

    public string EmployeeName { get; set; } = null!;

    public DateTime Date { get; set; }

    public decimal TotalAmount { get; set; }

    public int TotalOrders { get; set; }

    public int TotalItems { get; set; }

    public List<SalesOrderDto> Orders { get; set; } = [];
}

public class SalesOrderDto
{
    public Guid OrderId { get; set; }

    public string OrderNumber { get; set; } = null!;

    public decimal TotalAmount { get; set; }

    public DateTime CreatedAt { get; set; }

    public int ItemCount { get; set; }
}
