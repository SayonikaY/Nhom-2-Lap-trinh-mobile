using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;

namespace WebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MenuItemsController(RestaurantDbContext context, ILogger<MenuItemsController> logger)
    : ControllerBase
{
    /// <summary>
    ///     Get all menu items
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<MenuItem>>> GetMenuItems(
        [FromQuery] ItemKind? kind = null,
        [FromQuery] bool availableOnly = false)
    {
        try
        {
            var query = context.MenuItems.AsQueryable();

            if (kind.HasValue)
                query = query.Where(m => m.Kind == kind.Value);

            if (availableOnly)
                query = query.Where(m => m.IsAvailable);

            var menuItems = await query
                .OrderBy(m => m.Kind)
                .ThenBy(m => m.Name)
                .ToListAsync();

            return Ok(menuItems);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving menu items");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get menu item by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<MenuItem>> GetMenuItem(
        Guid id)
    {
        try
        {
            var menuItem = await context.MenuItems.FindAsync(id);

            if (menuItem is null)
                return NotFound($"Menu item with ID {id} not found");

            return Ok(menuItem);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving menu item with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Create a new menu item
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<MenuItem>> CreateMenuItem(
        CreateMenuItemDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Check if menu item with same name already exists
            var existingItem = await context.MenuItems
                // .FirstOrDefaultAsync(m => m.Name.Equals(dto.Name, StringComparison.CurrentCultureIgnoreCase));
                .FirstOrDefaultAsync(m => EF.Functions.Collate(m.Name, "SQL_Latin1_General_CP1_CI_AI") == dto.Name);

            if (existingItem is not null)
                return Conflict("A menu item with this name already exists");

            var menuItem = new MenuItem
            {
                Name = dto.Name,
                Kind = dto.Kind,
                Price = dto.Price,
                Description = dto.Description,
                ImageUrl = !string.IsNullOrEmpty(dto.ImageUrl) ? new Uri(dto.ImageUrl) : null,
                IsAvailable = dto.IsAvailable,
            };

            context.MenuItems.Add(menuItem);
            await context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetMenuItem), new { id = menuItem.Id }, menuItem);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error creating menu item");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Update an existing menu item
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateMenuItem(
        Guid id,
        UpdateMenuItemDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var menuItem = await context.MenuItems.FindAsync(id);

            if (menuItem is null)
                return NotFound($"Menu item with ID {id} not found");

            // Check if another menu item with same name already exists
            var existingItem = await context.MenuItems
                // .FirstOrDefaultAsync(m =>
                //     m.Name.Equals(dto.Name, StringComparison.CurrentCultureIgnoreCase) && m.Id != id);
                .FirstOrDefaultAsync(m =>
                    EF.Functions.Collate(m.Name, "SQL_Latin1_General_CP1_CI_AI") == dto.Name && m.Id != id);

            if (existingItem is not null)
                return Conflict("A menu item with this name already exists");

            menuItem.Name = dto.Name;
            menuItem.Kind = dto.Kind;
            menuItem.Price = dto.Price;
            menuItem.Description = dto.Description;
            menuItem.ImageUrl = !string.IsNullOrEmpty(dto.ImageUrl) ? new Uri(dto.ImageUrl) : null;
            menuItem.IsAvailable = dto.IsAvailable;

            await context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error updating menu item with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Delete a menu item (soft delete)
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteMenuItem(
        Guid id)
    {
        try
        {
            var menuItem = await context.MenuItems.FindAsync(id);

            if (menuItem is null)
                return NotFound($"Menu item with ID {id} not found");

            // Check if menu item is used in any active orders
            var hasActiveOrders = await context.OrderDetails
                .Include(od => od.Order)
                .AnyAsync(od => od.MenuItem.Id == id &&
                                od.Order.Status != OrderStatus.Completed &&
                                od.Order.Status != OrderStatus.Cancelled);

            if (hasActiveOrders)
                return BadRequest("Cannot delete menu item that is part of active orders");

            menuItem.IsDeleted = true;
            await context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error deleting menu item with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Toggle menu item availability
    /// </summary>
    [HttpPatch("{id:guid}/availability")]
    public async Task<IActionResult> ToggleAvailability(
        Guid id)
    {
        try
        {
            var menuItem = await context.MenuItems.FindAsync(id);

            if (menuItem is null)
                return NotFound($"Menu item with ID {id} not found");

            menuItem.IsAvailable = !menuItem.IsAvailable;
            await context.SaveChangesAsync();

            return Ok(new { menuItem.IsAvailable });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error toggling availability for menu item with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get menu items by category
    /// </summary>
    [HttpGet("category/{kind}")]
    public async Task<ActionResult<IEnumerable<MenuItem>>> GetMenuItemsByCategory(
        ItemKind kind)
    {
        try
        {
            var menuItems = await context.MenuItems
                .Where(m => m.Kind == kind)
                .OrderBy(m => m.Name)
                .ToListAsync();

            return Ok(menuItems);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving menu items for category {Kind}", kind);
            return StatusCode(500, "Internal server error");
        }
    }
}

// DTOs for MenuItem operations
public class CreateMenuItemDto
{
    public string Name { get; set; } = string.Empty;
    public ItemKind Kind { get; set; }
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsAvailable { get; set; } = true;
}

public class UpdateMenuItemDto
{
    public string Name { get; set; } = string.Empty;
    public ItemKind Kind { get; set; }
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsAvailable { get; set; }
}
