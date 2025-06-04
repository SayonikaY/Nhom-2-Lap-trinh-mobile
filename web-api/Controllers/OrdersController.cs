using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;

namespace WebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class OrdersController(RestaurantDbContext context, ILogger<OrdersController> logger)
    : ControllerBase
{
    /// <summary>
    ///     Get all orders
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrders(
        [FromQuery] OrderStatus? status = null,
        [FromQuery] Guid? tableId = null,
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            var query = context.Orders
                .Include(o => o.Table)
                .Include(o => o.Items)
                .ThenInclude(oi => oi.MenuItem)
                .AsQueryable();

            if (status.HasValue)
                query = query.Where(o => o.Status == status.Value);

            if (tableId.HasValue)
                query = query.Where(o => o.Table.Id == tableId.Value);

            if (fromDate.HasValue)
                query = query.Where(o => o.CreatedAt >= fromDate.Value);

            if (toDate.HasValue)
                query = query.Where(o => o.CreatedAt <= toDate.Value);

            var orders = await query
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            var orderDtos = orders.Select(o => new OrderDto
            {
                Id = o.Id,
                Number = o.Number,
                TableName = o.Table.Name,
                TableId = o.Table.Id,
                Status = o.Status,
                Note = o.Note,
                TotalAmount = o.TotalAmount,
                CreatedAt = o.CreatedAt,
                Items = o.Items.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    MenuItemId = oi.MenuItem.Id,
                    MenuItemName = oi.MenuItem.Name,
                    Quantity = oi.Quantity,
                    Price = oi.Price,
                    TotalPrice = oi.TotalPrice,
                }).ToList(),
            }).ToList();

            return Ok(orderDtos);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving orders");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get order by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<OrderDto>> GetOrder(
        Guid id)
    {
        try
        {
            var order = await context.Orders
                .Include(o => o.Table)
                .Include(o => o.Items)
                .ThenInclude(oi => oi.MenuItem)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order is null)
                return NotFound($"Order with ID {id} not found");

            var orderDto = new OrderDto
            {
                Id = order.Id,
                Number = order.Number,
                TableName = order.Table.Name,
                TableId = order.Table.Id,
                Status = order.Status,
                Note = order.Note,
                TotalAmount = order.TotalAmount,
                CreatedAt = order.CreatedAt,
                Items = order.Items.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    MenuItemId = oi.MenuItem.Id,
                    MenuItemName = oi.MenuItem.Name,
                    Quantity = oi.Quantity,
                    Price = oi.Price,
                    TotalPrice = oi.TotalPrice,
                }).ToList(),
            };

            return Ok(orderDto);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving order with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Create a new order
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<OrderDto>> CreateOrder(
        CreateOrderDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Validate table exists and is available
            var table = await context.Tables.FindAsync(dto.TableId);

            if (table is null)
                return BadRequest("Table not found");

            if (!table.IsAvailable)
                return BadRequest("Table is not available");

            // Validate menu items exist and are available
            var menuItemIds = dto.Items.Select(i => i.MenuItemId).ToList();
            var menuItems = await context.MenuItems
                .Where(mi => menuItemIds.Contains(mi.Id))
                .ToListAsync();

            if (menuItems.Count != menuItemIds.Count)
                return BadRequest("One or more menu items not found");

            var unavailableItems = menuItems.Where(mi => !mi.IsAvailable).ToList();

            if (unavailableItems.Count != 0)
                return BadRequest(
                    $"Menu items are not available: {string.Join(", ", unavailableItems.Select(mi => mi.Name))}");

            var order = new Order
            {
                Number = Order.CreateNumber(),
                Table = table,
                Note = dto.Note,
                Status = OrderStatus.Pending,
            };

            var orderDetails = new List<OrderDetail>();
            decimal totalAmount = 0;

            foreach (var item in dto.Items)
            {
                var menuItem = menuItems.First(mi => mi.Id == item.MenuItemId);
                var orderDetail = new OrderDetail
                {
                    Order = order,
                    MenuItem = menuItem,
                    Quantity = item.Quantity,
                    Price = menuItem.Price,
                };
                orderDetails.Add(orderDetail);
                totalAmount += orderDetail.TotalPrice;
            }

            order.Items = orderDetails;
            order.TotalAmount = totalAmount;

            context.Orders.Add(order);
            await context.SaveChangesAsync();

            // Return the created order
            var createdOrderDto = new OrderDto
            {
                Id = order.Id,
                Number = order.Number,
                TableName = table.Name,
                TableId = table.Id,
                Status = order.Status,
                Note = order.Note,
                TotalAmount = order.TotalAmount,
                CreatedAt = order.CreatedAt,
                Items = orderDetails.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    MenuItemId = oi.MenuItem.Id,
                    MenuItemName = oi.MenuItem.Name,
                    Quantity = oi.Quantity,
                    Price = oi.Price,
                    TotalPrice = oi.TotalPrice,
                }).ToList(),
            };

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, createdOrderDto);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error creating order");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Update order status
    /// </summary>
    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateOrderStatus(
        Guid id,
        UpdateOrderStatusDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var order = await context.Orders.FindAsync(id);

            if (order is null)
                return NotFound($"Order with ID {id} not found");

            // Validate status transition
            if (!IsValidStatusTransition(order.Status, dto.Status))
                return BadRequest($"Invalid status transition from {order.Status} to {dto.Status}");

            order.Status = dto.Status;
            await context.SaveChangesAsync();

            return Ok(new { order.Status });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error updating order status for ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Add items to existing order
    /// </summary>
    [HttpPost("{id:guid}/items")]
    public async Task<ActionResult<OrderDto>> AddOrderItems(
        Guid id,
        AddOrderItemsDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var order = await context.Orders
                .Include(o => o.Items)
                .ThenInclude(oi => oi.MenuItem)
                .Include(o => o.Table)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order is null)
                return NotFound($"Order with ID {id} not found");

            if (order.Status is OrderStatus.Completed or OrderStatus.Cancelled)
                return BadRequest("Cannot add items to completed or cancelled orders");

            // Validate menu items
            var menuItemIds = dto.Items.Select(i => i.MenuItemId).ToList();
            var menuItems = await context.MenuItems
                .Where(mi => menuItemIds.Contains(mi.Id))
                .ToListAsync();

            if (menuItems.Count != menuItemIds.Count)
                return BadRequest("One or more menu items not found");

            var unavailableItems = menuItems.Where(mi => !mi.IsAvailable).ToList();

            if (unavailableItems.Count != 0)
                return BadRequest(
                    $"Menu items are not available: {string.Join(", ", unavailableItems.Select(mi => mi.Name))}");

            decimal additionalAmount = 0;
            foreach (var item in dto.Items)
            {
                var menuItem = menuItems.First(mi => mi.Id == item.MenuItemId);
                var orderDetail = new OrderDetail
                {
                    Order = order,
                    MenuItem = menuItem,
                    Quantity = item.Quantity,
                    Price = menuItem.Price,
                };
                context.OrderDetails.Add(orderDetail);
                additionalAmount += orderDetail.TotalPrice;
            }

            order.TotalAmount += additionalAmount;
            await context.SaveChangesAsync();

            return await GetOrder(id);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error adding items to order with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Cancel an order
    /// </summary>
    [HttpPatch("{id:guid}/cancel")]
    public async Task<IActionResult> CancelOrder(
        Guid id)
    {
        try
        {
            var order = await context.Orders.FindAsync(id);

            if (order is null)
                return NotFound($"Order with ID {id} not found");

            if (order.Status == OrderStatus.Completed)
                return BadRequest("Cannot cancel a completed order");

            if (order.Status == OrderStatus.Cancelled)
                return BadRequest("Order is already cancelled");

            order.Status = OrderStatus.Cancelled;
            await context.SaveChangesAsync();

            return Ok(new { order.Status });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error cancelling order with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get orders by status
    /// </summary>
    [HttpGet("status/{status}")]
    public async Task<ActionResult<IEnumerable<OrderDto>>> GetOrdersByStatus(
        OrderStatus status)
    {
        try
        {
            var orders = await context.Orders
                .Include(o => o.Table)
                .Include(o => o.Items)
                .ThenInclude(oi => oi.MenuItem)
                .Where(o => o.Status == status)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            var orderDtos = orders.Select(o => new OrderDto
            {
                Id = o.Id,
                Number = o.Number,
                TableName = o.Table.Name,
                TableId = o.Table.Id,
                Status = o.Status,
                Note = o.Note,
                TotalAmount = o.TotalAmount,
                CreatedAt = o.CreatedAt,
                Items = o.Items.Select(oi => new OrderItemDto
                {
                    Id = oi.Id,
                    MenuItemId = oi.MenuItem.Id,
                    MenuItemName = oi.MenuItem.Name,
                    Quantity = oi.Quantity,
                    Price = oi.Price,
                    TotalPrice = oi.TotalPrice,
                }).ToList(),
            }).ToList();

            return Ok(orderDtos);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving orders with status {Status}", status);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get orders summary by date range
    /// </summary>
    [HttpGet("summary")]
    public async Task<ActionResult<OrderSummaryDto>> GetOrdersSummary(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate = null)
    {
        try
        {
            var query = context.Orders.AsQueryable();

            var from = fromDate ?? DateTime.Today;
            var to = toDate ?? DateTime.Today.AddDays(1);

            query = query.Where(o => o.CreatedAt >= from && o.CreatedAt < to);

            var orders = await query.ToListAsync();

            var summary = new OrderSummaryDto
            {
                TotalOrders = orders.Count,
                PendingOrders = orders.Count(o => o.Status == OrderStatus.Pending),
                InProgressOrders = orders.Count(o => o.Status == OrderStatus.InProgress),
                CompletedOrders = orders.Count(o => o.Status == OrderStatus.Completed),
                CancelledOrders = orders.Count(o => o.Status == OrderStatus.Cancelled),
                TotalRevenue = orders.Where(o => o.Status == OrderStatus.Completed).Sum(o => o.TotalAmount),
                FromDate = from,
                ToDate = to,
            };

            return Ok(summary);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving orders summary");
            return StatusCode(500, "Internal server error");
        }
    }

    private static bool IsValidStatusTransition(OrderStatus current, OrderStatus target)
    {
        return current switch
        {
            OrderStatus.Pending => target is OrderStatus.InProgress or OrderStatus.Cancelled,
            OrderStatus.InProgress => target is OrderStatus.Completed or OrderStatus.Cancelled,
            _ => false,
        };
    }
}

// DTOs for Order operations
public class CreateOrderDto
{
    public Guid TableId { get; set; }
    public string? Note { get; set; }
    public List<CreateOrderItemDto> Items { get; set; } = [];
}

public class CreateOrderItemDto
{
    public Guid MenuItemId { get; set; }
    public int Quantity { get; set; } = 1;
}

public class UpdateOrderStatusDto
{
    public OrderStatus Status { get; set; }
}

public class AddOrderItemsDto
{
    public List<CreateOrderItemDto> Items { get; set; } = [];
}

public class OrderDto
{
    public Guid Id { get; set; }
    public string Number { get; set; } = string.Empty;
    public string TableName { get; set; } = string.Empty;
    public Guid TableId { get; set; }
    public OrderStatus Status { get; set; }
    public string? Note { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<OrderItemDto> Items { get; set; } = [];
}

public class OrderItemDto
{
    public Guid Id { get; set; }
    public Guid MenuItemId { get; set; }
    public string MenuItemName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Price { get; set; }
    public decimal TotalPrice { get; set; }
}

public class OrderSummaryDto
{
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public int InProgressOrders { get; set; }
    public int CompletedOrders { get; set; }
    public int CancelledOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
}
