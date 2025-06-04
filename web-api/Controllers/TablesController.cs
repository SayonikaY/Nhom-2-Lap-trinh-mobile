using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;

namespace WebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TablesController(RestaurantDbContext context, ILogger<TablesController> logger)
    : ControllerBase
{
    /// <summary>
    ///     Get all tables
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Table>>> GetTables(
        [FromQuery] bool availableOnly = false)
    {
        try
        {
            var query = context.Tables.AsQueryable();

            if (availableOnly)
                query = query.Where(t => t.IsAvailable);

            var tables = await query
                .OrderBy(t => t.Name)
                .ToListAsync();

            return Ok(tables);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving tables");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get table by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    public async Task<ActionResult<Table>> GetTable(
        Guid id)
    {
        try
        {
            var table = await context.Tables.FindAsync(id);

            if (table is null)
                return NotFound($"Table with ID {id} not found");

            return Ok(table);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving table with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Create a new table
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<Table>> CreateTable(
        CreateTableDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Check if table with same name already exists
            var existingTable = await context.Tables
                // .FirstOrDefaultAsync(t => t.Name.Equals(dto.Name, StringComparison.CurrentCultureIgnoreCase));
                .FirstOrDefaultAsync(t => EF.Functions.Collate(t.Name, "SQL_Latin1_General_CP1_CI_AI") == dto.Name);

            if (existingTable is not null)
                return Conflict("A table with this name already exists");

            var table = new Table
            {
                Name = dto.Name,
                Capacity = dto.Capacity,
                Description = dto.Description,
                IsAvailable = dto.IsAvailable,
            };

            context.Tables.Add(table);
            await context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetTable), new { id = table.Id }, table);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error creating table");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Update an existing table
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTable(
        Guid id,
        UpdateTableDto dto)
    {
        try
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var table = await context.Tables.FindAsync(id);

            if (table is null)
                return NotFound($"Table with ID {id} not found");

            // Check if another table with same name already exists
            var existingTable = await context.Tables
                // .FirstOrDefaultAsync(t =>
                //     t.Name.Equals(dto.Name, StringComparison.CurrentCultureIgnoreCase) && t.Id != id);
                .FirstOrDefaultAsync(t =>
                    EF.Functions.Collate(t.Name, "SQL_Latin1_General_CP1_CI_AI") == dto.Name && t.Id != id);

            if (existingTable is not null)
                return Conflict("A table with this name already exists");

            table.Name = dto.Name;
            table.Capacity = dto.Capacity;
            table.Description = dto.Description;
            table.IsAvailable = dto.IsAvailable;

            await context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error updating table with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Delete a table (soft delete)
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteTable(
        Guid id)
    {
        try
        {
            var table = await context.Tables.FindAsync(id);

            if (table is null)
                return NotFound($"Table with ID {id} not found");

            // Check if table has any active orders
            var hasActiveOrders = await context.Orders
                .AnyAsync(o => o.Table.Id == id &&
                               o.Status != OrderStatus.Completed &&
                               o.Status != OrderStatus.Cancelled);

            if (hasActiveOrders)
                return BadRequest("Cannot delete table that has active orders");

            table.IsDeleted = true;
            await context.SaveChangesAsync();

            return NoContent();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error deleting table with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Toggle table availability
    /// </summary>
    [HttpPatch("{id:guid}/availability")]
    public async Task<IActionResult> ToggleAvailability(
        Guid id)
    {
        try
        {
            var table = await context.Tables.FindAsync(id);

            if (table is null)
                return NotFound($"Table with ID {id} not found");

            table.IsAvailable = !table.IsAvailable;
            await context.SaveChangesAsync();

            return Ok(new { table.IsAvailable });
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error toggling availability for table with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get available tables with specified capacity or more
    /// </summary>
    [HttpGet("available")]
    public async Task<ActionResult<IEnumerable<Table>>> GetAvailableTables(
        [FromQuery] int? minCapacity = null)
    {
        try
        {
            var query = context.Tables.Where(t => t.IsAvailable);

            if (minCapacity.HasValue)
                query = query.Where(t => t.Capacity >= minCapacity.Value);

            var tables = await query
                .OrderBy(t => t.Capacity)
                .ThenBy(t => t.Name)
                .ToListAsync();

            return Ok(tables);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving available tables");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    ///     Get table with current active orders
    /// </summary>
    [HttpGet("{id:guid}/orders")]
    public async Task<ActionResult<IEnumerable<Order>>> GetTableOrders(
        Guid id)
    {
        try
        {
            var table = await context.Tables.FindAsync(id);

            if (table is null)
                return NotFound($"Table with ID {id} not found");

            var orders = await context.Orders
                .Include(o => o.Items)
                .ThenInclude(oi => oi.MenuItem)
                .Where(o => o.Table.Id == id)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Error retrieving orders for table with ID {Id}", id);
            return StatusCode(500, "Internal server error");
        }
    }
}

// DTOs for Table operations
public class CreateTableDto
{
    public string Name { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public string? Description { get; set; }
    public bool IsAvailable { get; set; } = true;
}

public class UpdateTableDto
{
    public string Name { get; set; } = string.Empty;
    public int Capacity { get; set; }
    public string? Description { get; set; }
    public bool IsAvailable { get; set; }
}
