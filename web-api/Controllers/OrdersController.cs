using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;
using WebApi.Models.DTOs;

namespace WebApi.Controllers;

[ApiController]
[Route("api/orders")]
[Authorize]
public class OrdersController(RestaurantDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetOrders(
        [FromQuery] OrderStatus? status = null,
        [FromQuery] Guid? tableId = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        var query = context.Orders
            .Include(o => o.Table)
            .Include(o => o.Employee)
            .Include(o => o.Items)
            .ThenInclude(od => od.MenuItem)
            .Where(o => !o.IsDeleted);

        if (status.HasValue)
            query = query.Where(o => o.Status == status.Value);

        if (tableId.HasValue)
            query = query.Where(o => o.TableId == tableId.Value);

        if (fromDate.HasValue)
            query = query.Where(o => o.CreatedAt >= fromDate.Value);

        if (toDate.HasValue)
            query = query.Where(o => o.CreatedAt <= toDate.Value);

        var orders = await query
            .OrderByDescending(o => o.CreatedAt)
            .Select(o => new OrderDto
            {
                Id = o.Id,
                Number = o.Number,
                TableId = o.TableId,
                TableName = o.Table.Name,
                Status = o.Status,
                Note = o.Note,
                TotalAmount = o.TotalAmount,
                EmployeeId = o.EmployeeId,
                EmployeeName = o.Employee.FullName,
                CreatedAt = o.CreatedAt,
                Items = o.Items.Select(od => new OrderDetailDto
                {
                    Id = od.Id,
                    MenuItemId = od.MenuItemId,
                    MenuItemName = od.MenuItem.Name,
                    Quantity = od.Quantity,
                    Price = od.Price,
                    TotalPrice = od.TotalPrice,
                }).ToList(),
            })
            .ToListAsync();

        return Ok(orders);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetOrder(
        Guid id)
    {
        var order = await context.Orders
            .Include(o => o.Table)
            .Include(o => o.Employee)
            .Include(o => o.Items)
            .ThenInclude(od => od.MenuItem)
            .Where(o => o.Id == id && !o.IsDeleted)
            .Select(o => new OrderDto
            {
                Id = o.Id,
                Number = o.Number,
                TableId = o.TableId,
                TableName = o.Table.Name,
                Status = o.Status,
                Note = o.Note,
                TotalAmount = o.TotalAmount,
                EmployeeId = o.EmployeeId,
                EmployeeName = o.Employee.FullName,
                CreatedAt = o.CreatedAt,
                Items = o.Items.Select(od => new OrderDetailDto
                {
                    Id = od.Id,
                    MenuItemId = od.MenuItemId,
                    MenuItemName = od.MenuItem.Name,
                    Quantity = od.Quantity,
                    Price = od.Price,
                    TotalPrice = od.TotalPrice,
                }).ToList(),
            })
            .FirstOrDefaultAsync();

        if (order is null)
            return NotFound(new { message = "Order not found" });

        return Ok(order);
    }

    [HttpPost]
    public async Task<IActionResult> CreateOrder(
        [FromBody] CreateOrderDto createOrderDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Get current user ID
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var employeeId))
            return Unauthorized();

        // Verify table exists and is available
        var table = await context.Tables
            .FirstOrDefaultAsync(t => t.Id == createOrderDto.TableId && !t.IsDeleted);

        if (table is null)
            return BadRequest(new { message = "Table not found" });

        if (!table.IsAvailable)
            return BadRequest(new { message = "Table is not available" });

        // Get menu items and verify they exist and are available
        var menuItemIds = createOrderDto.Items.Select(i => i.MenuItemId).ToList();
        var menuItems = await context.MenuItems
            .Where(m => menuItemIds.Contains(m.Id) && !m.IsDeleted)
            .ToListAsync();

        if (menuItems.Count != menuItemIds.Count)
            return BadRequest(new { message = "One or more menu items not found" });

        var unavailableItems = menuItems.Where(m => !m.IsAvailable).ToList();
        if (unavailableItems.Count != 0)
            return BadRequest(new
                { message = $"Menu items not available: {string.Join(", ", unavailableItems.Select(m => m.Name))}" });

        // Create order
        var order = new Order
        {
            Number = Order.CreateNumber(),
            TableId = createOrderDto.TableId,
            Note = createOrderDto.Note,
            EmployeeId = employeeId,
        };

        // Create order details
        var orderDetails = new List<OrderDetail>();
        decimal totalAmount = 0;

        foreach (var item in createOrderDto.Items)
        {
            var menuItem = menuItems.First(m => m.Id == item.MenuItemId);
            var orderDetail = new OrderDetail
            {
                OrderId = order.Id,
                MenuItemId = item.MenuItemId,
                Quantity = item.Quantity,
                Price = menuItem.Price,
            };

            orderDetails.Add(orderDetail);
            totalAmount += orderDetail.TotalPrice;
        }

        order.TotalAmount = totalAmount;

        context.Orders.Add(order);
        context.OrderDetails.AddRange(orderDetails);
        await context.SaveChangesAsync();

        // Load the created order with related data
        var createdOrder = await context.Orders
            .Include(o => o.Table)
            .Include(o => o.Employee)
            .Include(o => o.Items)
            .ThenInclude(od => od.MenuItem)
            .FirstAsync(o => o.Id == order.Id);

        var orderDto = new OrderDto
        {
            Id = createdOrder.Id,
            Number = createdOrder.Number,
            TableId = createdOrder.TableId,
            TableName = createdOrder.Table.Name,
            Status = createdOrder.Status,
            Note = createdOrder.Note,
            TotalAmount = createdOrder.TotalAmount,
            EmployeeId = createdOrder.EmployeeId,
            EmployeeName = createdOrder.Employee.FullName,
            CreatedAt = createdOrder.CreatedAt,
            Items = createdOrder.Items.Select(od => new OrderDetailDto
            {
                Id = od.Id,
                MenuItemId = od.MenuItemId,
                MenuItemName = od.MenuItem.Name,
                Quantity = od.Quantity,
                Price = od.Price,
                TotalPrice = od.TotalPrice,
            }).ToList(),
        };

        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, orderDto);
    }

    [HttpPut("{id:guid}/status")]
    public async Task<IActionResult> UpdateOrderStatus(
        Guid id,
        [FromBody] UpdateOrderStatusDto updateStatusDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var order = await context.Orders
            .FirstOrDefaultAsync(o => o.Id == id && !o.IsDeleted);

        if (order is null)
            return NotFound(new { message = "Order not found" });

        // Validate status transition
        if (!IsValidStatusTransition(order.Status, updateStatusDto.Status))
            return BadRequest(new
                { message = $"Invalid status transition from {order.Status} to {updateStatusDto.Status}" });

        order.Status = updateStatusDto.Status;
        await context.SaveChangesAsync();

        return Ok(new { message = "Order status updated successfully", status = order.Status });
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteOrder(Guid id)
    {
        var order = await context.Orders
            .FirstOrDefaultAsync(o => o.Id == id && !o.IsDeleted);

        if (order is null)
            return NotFound(new { message = "Order not found" });

        // Only allow deletion of pending orders
        if (order.Status != OrderStatus.Pending)
            return BadRequest(new { message = "Only pending orders can be deleted" });

        order.IsDeleted = true;
        await context.SaveChangesAsync();

        return NoContent();
    }

    [HttpGet("statuses")]
    [AllowAnonymous]
    public IActionResult GetOrderStatuses()
    {
        var statuses = Enum.GetValues<OrderStatus>()
            .Select(s => new { value = (int)s, name = s.ToString() })
            .ToList();

        return Ok(statuses);
    }

    private static bool IsValidStatusTransition(OrderStatus currentStatus, OrderStatus newStatus)
    {
        return currentStatus switch
        {
            OrderStatus.Pending => newStatus is OrderStatus.InProgress or OrderStatus.Cancelled,
            OrderStatus.InProgress => newStatus is OrderStatus.Completed or OrderStatus.Cancelled,
            OrderStatus.Completed => false, // Completed orders cannot be changed
            OrderStatus.Cancelled => false, // Cancelled orders cannot be changed
            _ => false,
        };
    }
}
