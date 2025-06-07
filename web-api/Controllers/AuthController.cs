using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;
using WebApi.Models.DTOs;
using WebApi.Services;

namespace WebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController(
    RestaurantDbContext context,
    IJwtService jwtService,
    IPasswordService passwordService)
    : ControllerBase
{
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginDto loginDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var employee = await context.Employees
            .FirstOrDefaultAsync(e => e.Username == loginDto.Username && !e.IsDeleted);

        if (employee is null || !passwordService.VerifyPassword(loginDto.Password, employee.PasswordHash))
            return Unauthorized(new { message = "Invalid username or password" });

        var token = jwtService.GenerateToken(employee);
        var response = new LoginResponseDto
        {
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            Employee = new EmployeeDto
            {
                Id = employee.Id,
                FullName = employee.FullName,
                Username = employee.Username,
                CreatedAt = employee.CreatedAt,
            },
        };

        return Ok(response);
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        [FromBody] CreateEmployeeDto createEmployeeDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if username already exists
        var existingEmployee = await context.Employees
            .FirstOrDefaultAsync(e => e.Username == createEmployeeDto.Username && !e.IsDeleted);

        if (existingEmployee is not null)
            return Conflict(new { message = "Username already exists" });

        var employee = new Employee
        {
            FullName = createEmployeeDto.FullName,
            Username = createEmployeeDto.Username,
            PasswordHash = passwordService.HashPassword(createEmployeeDto.Password),
        };

        context.Employees.Add(employee);
        await context.SaveChangesAsync();

        var employeeDto = new EmployeeDto
        {
            Id = employee.Id,
            FullName = employee.FullName,
            Username = employee.Username,
            CreatedAt = employee.CreatedAt,
        };

        return CreatedAtAction(nameof(GetProfile), new { id = employee.Id }, employeeDto);
    }

    [HttpGet("profile")]
    [Authorize]
    public async Task<IActionResult> GetProfile()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var employeeId))
            return Unauthorized();

        var employee = await context.Employees
            .FirstOrDefaultAsync(e => e.Id == employeeId && !e.IsDeleted);

        if (employee is null)
            return NotFound();

        var employeeDto = new EmployeeDto
        {
            Id = employee.Id,
            FullName = employee.FullName,
            Username = employee.Username,
            CreatedAt = employee.CreatedAt,
        };

        return Ok(employeeDto);
    }

    [HttpGet("sales-summary")]
    [Authorize]
    public async Task<IActionResult> GetEmployeeSalesSummary([FromQuery] DateTime? date = null)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var employeeId))
            return Unauthorized();

        var employee = await context.Employees
            .FirstOrDefaultAsync(e => e.Id == employeeId && !e.IsDeleted);

        if (employee is null)
            return NotFound();

        // Use today's date if no date provided
        var targetDate = date ?? DateTime.UtcNow.Date;
        var startOfDay = targetDate;
        var endOfDay = targetDate.AddDays(1).AddTicks(-1);

        // Get all completed orders for this employee on the specified date
        var orders = await context.Orders
            .Include(o => o.Items)
            .ThenInclude(oi => oi.MenuItem)
            .Where(o => o.EmployeeId == employeeId
                       && !o.IsDeleted
                       && o.Status == OrderStatus.Completed
                       && o.CreatedAt >= startOfDay
                       && o.CreatedAt <= endOfDay)
            .ToListAsync();

        var totalAmount = orders.Sum(o => o.TotalAmount);
        var totalOrders = orders.Count;
        var totalItems = orders.SelectMany(o => o.Items).Sum(i => i.Quantity);

        var salesSummary = new EmployeeSalesSummaryDto
        {
            EmployeeId = employeeId,
            EmployeeName = employee.FullName,
            Date = targetDate,
            TotalAmount = totalAmount,
            TotalOrders = totalOrders,
            TotalItems = totalItems,
            Orders = orders.Select(o => new SalesOrderDto
            {
                OrderId = o.Id,
                OrderNumber = o.Number,
                TotalAmount = o.TotalAmount,
                CreatedAt = o.CreatedAt,
                ItemCount = o.Items.Sum(i => i.Quantity)
            }).ToList()
        };

        return Ok(salesSummary);
    }
}
