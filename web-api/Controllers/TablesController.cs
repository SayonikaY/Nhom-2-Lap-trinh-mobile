using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;
using WebApi.Models.DTOs;

namespace WebApi.Controllers;

[ApiController]
[Route("api/tables")]
[Authorize]
public class TablesController(RestaurantDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetTables(
        [FromQuery] bool includeUnavailable = false)
    {
        var query = context.Tables.Where(t => !t.IsDeleted);

        if (!includeUnavailable)
            query = query.Where(t => t.IsAvailable);

        var tables = await query
            .OrderBy(t => t.Name)
            .Select(t => new TableDto
            {
                Id = t.Id,
                Name = t.Name,
                Capacity = t.Capacity,
                Description = t.Description,
                IsAvailable = t.IsAvailable,
                CreatedAt = t.CreatedAt,
            })
            .ToListAsync();

        return Ok(tables);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetTable(
        Guid id)
    {
        var table = await context.Tables
            .Where(t => t.Id == id && !t.IsDeleted)
            .Select(t => new TableDto
            {
                Id = t.Id,
                Name = t.Name,
                Capacity = t.Capacity,
                Description = t.Description,
                IsAvailable = t.IsAvailable,
                CreatedAt = t.CreatedAt,
            })
            .FirstOrDefaultAsync();

        if (table is null)
            return NotFound(new { message = "Table not found" });

        return Ok(table);
    }

    [HttpPost]
    public async Task<IActionResult> CreateTable(
        [FromBody] CreateTableDto createTableDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if table name already exists
        var existingTable = await context.Tables
            .FirstOrDefaultAsync(t => t.Name == createTableDto.Name && !t.IsDeleted);

        if (existingTable is not null)
            return Conflict(new { message = "Table name already exists" });

        var table = new Table
        {
            Name = createTableDto.Name,
            Capacity = createTableDto.Capacity,
            Description = createTableDto.Description,
        };

        context.Tables.Add(table);
        await context.SaveChangesAsync();

        var tableDto = new TableDto
        {
            Id = table.Id,
            Name = table.Name,
            Capacity = table.Capacity,
            Description = table.Description,
            IsAvailable = table.IsAvailable,
            CreatedAt = table.CreatedAt,
        };

        return CreatedAtAction(nameof(GetTable), new { id = table.Id }, tableDto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTable(
        Guid id,
        [FromBody] UpdateTableDto updateTableDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var table = await context.Tables
            .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);

        if (table is null)
            return NotFound(new { message = "Table not found" });

        // Check if new name conflicts with existing table
        if (!string.IsNullOrEmpty(updateTableDto.Name) && updateTableDto.Name != table.Name)
        {
            var existingTable = await context.Tables
                .FirstOrDefaultAsync(t => t.Name == updateTableDto.Name && !t.IsDeleted && t.Id != id);

            if (existingTable is not null)
                return Conflict(new { message = "Table name already exists" });

            table.Name = updateTableDto.Name;
        }

        if (updateTableDto.Capacity.HasValue)
            table.Capacity = updateTableDto.Capacity.Value;

        if (updateTableDto.Description is not null)
            table.Description = updateTableDto.Description;

        if (updateTableDto.IsAvailable.HasValue)
            table.IsAvailable = updateTableDto.IsAvailable.Value;

        await context.SaveChangesAsync();

        var tableDto = new TableDto
        {
            Id = table.Id,
            Name = table.Name,
            Capacity = table.Capacity,
            Description = table.Description,
            IsAvailable = table.IsAvailable,
            CreatedAt = table.CreatedAt,
        };

        return Ok(tableDto);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteTable(Guid id)
    {
        var table = await context.Tables
            .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);

        if (table is null)
            return NotFound(new { message = "Table not found" });

        // Check if table has active orders
        var hasActiveOrders = await context.Orders
            .AnyAsync(o => o.TableId == id && !o.IsDeleted &&
                           (o.Status == OrderStatus.Pending || o.Status == OrderStatus.InProgress));

        if (hasActiveOrders)
            return BadRequest(new { message = "Cannot delete table with active orders" });

        table.IsDeleted = true;
        await context.SaveChangesAsync();

        return NoContent();
    }
}
