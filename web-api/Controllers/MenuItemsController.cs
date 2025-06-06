using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WebApi.Data;
using WebApi.Models;
using WebApi.Models.DTOs;

namespace WebApi.Controllers;

[ApiController]
[Route("api/menuitems")]
[Authorize]
public class MenuItemsController(RestaurantDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetMenuItems(
        [FromQuery] ItemKind? kind = null,
        [FromQuery] bool includeUnavailable = false)
    {
        var query = context.MenuItems.Where(m => !m.IsDeleted);

        if (kind.HasValue)
            query = query.Where(m => m.Kind == kind.Value);

        if (!includeUnavailable)
            query = query.Where(m => m.IsAvailable);

        var menuItems = await query
            .OrderBy(m => m.Kind)
            .ThenBy(m => m.Name)
            .Select(m => new MenuItemDto
            {
                Id = m.Id,
                Name = m.Name,
                Kind = m.Kind,
                Price = m.Price,
                Description = m.Description,
                ImageUrl = m.ImageUrl,
                IsAvailable = m.IsAvailable,
                CreatedAt = m.CreatedAt,
            })
            .ToListAsync();

        return Ok(menuItems);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetMenuItem(
        Guid id)
    {
        var menuItem = await context.MenuItems
            .Where(m => m.Id == id && !m.IsDeleted)
            .Select(m => new MenuItemDto
            {
                Id = m.Id,
                Name = m.Name,
                Kind = m.Kind,
                Price = m.Price,
                Description = m.Description,
                ImageUrl = m.ImageUrl,
                IsAvailable = m.IsAvailable,
                CreatedAt = m.CreatedAt,
            })
            .FirstOrDefaultAsync();

        if (menuItem is null)
            return NotFound(new { message = "Menu item not found" });

        return Ok(menuItem);
    }

    [HttpGet("kinds")]
    [AllowAnonymous]
    public IActionResult GetItemKinds()
    {
        var kinds = Enum.GetValues<ItemKind>()
            .Select(k => new { value = (int)k, name = k.ToString() })
            .ToList();

        return Ok(kinds);
    }

    [HttpPost]
    public async Task<IActionResult> CreateMenuItem(
        [FromBody] CreateMenuItemDto createMenuItemDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        // Check if menu item name already exists
        var existingMenuItem = await context.MenuItems
            .FirstOrDefaultAsync(m => m.Name == createMenuItemDto.Name && !m.IsDeleted);

        if (existingMenuItem is not null)
            return Conflict(new { message = "Menu item name already exists" });

        var menuItem = new MenuItem
        {
            Name = createMenuItemDto.Name,
            Kind = createMenuItemDto.Kind,
            Price = createMenuItemDto.Price,
            Description = createMenuItemDto.Description,
            ImageUrl = createMenuItemDto.ImageUrl,
        };

        context.MenuItems.Add(menuItem);
        await context.SaveChangesAsync();

        var menuItemDto = new MenuItemDto
        {
            Id = menuItem.Id,
            Name = menuItem.Name,
            Kind = menuItem.Kind,
            Price = menuItem.Price,
            Description = menuItem.Description,
            ImageUrl = menuItem.ImageUrl,
            IsAvailable = menuItem.IsAvailable,
            CreatedAt = menuItem.CreatedAt,
        };

        return CreatedAtAction(nameof(GetMenuItem), new { id = menuItem.Id }, menuItemDto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateMenuItem(
        Guid id,
        [FromBody] UpdateMenuItemDto updateMenuItemDto)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var menuItem = await context.MenuItems
            .FirstOrDefaultAsync(m => m.Id == id && !m.IsDeleted);

        if (menuItem is null)
            return NotFound(new { message = "Menu item not found" });

        // Check if new name conflicts with existing menu item
        if (!string.IsNullOrEmpty(updateMenuItemDto.Name) && updateMenuItemDto.Name != menuItem.Name)
        {
            var existingMenuItem = await context.MenuItems
                .FirstOrDefaultAsync(m => m.Name == updateMenuItemDto.Name && !m.IsDeleted && m.Id != id);

            if (existingMenuItem is not null)
                return Conflict(new { message = "Menu item name already exists" });

            menuItem.Name = updateMenuItemDto.Name;
        }

        if (updateMenuItemDto.Kind.HasValue)
            menuItem.Kind = updateMenuItemDto.Kind.Value;

        if (updateMenuItemDto.Price.HasValue)
            menuItem.Price = updateMenuItemDto.Price.Value;

        if (updateMenuItemDto.Description is not null)
            menuItem.Description = updateMenuItemDto.Description;

        if (updateMenuItemDto.ImageUrl is not null)
            menuItem.ImageUrl = updateMenuItemDto.ImageUrl;

        if (updateMenuItemDto.IsAvailable.HasValue)
            menuItem.IsAvailable = updateMenuItemDto.IsAvailable.Value;

        await context.SaveChangesAsync();

        var menuItemDto = new MenuItemDto
        {
            Id = menuItem.Id,
            Name = menuItem.Name,
            Kind = menuItem.Kind,
            Price = menuItem.Price,
            Description = menuItem.Description,
            ImageUrl = menuItem.ImageUrl,
            IsAvailable = menuItem.IsAvailable,
            CreatedAt = menuItem.CreatedAt,
        };

        return Ok(menuItemDto);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteMenuItem(Guid id)
    {
        var menuItem = await context.MenuItems
            .FirstOrDefaultAsync(m => m.Id == id && !m.IsDeleted);

        if (menuItem is null)
            return NotFound(new { message = "Menu item not found" });

        menuItem.IsDeleted = true;
        await context.SaveChangesAsync();

        return NoContent();
    }
}
