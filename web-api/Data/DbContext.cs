using Microsoft.EntityFrameworkCore;
using WebApi.Models;
using WebApi.Services;

namespace WebApi.Data;

public class RestaurantDbContext(DbContextOptions<RestaurantDbContext> options)
    : DbContext(options)
{
    public DbSet<Table> Tables { get; set; }
    public DbSet<MenuItem> MenuItems { get; set; }
    public DbSet<Employee> Employees { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderDetail> OrderDetails { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        ConfigureEntities(modelBuilder);
        SeedData(modelBuilder);
    }

    private static void ConfigureEntities(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Table>(entity =>
        {
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Id)
                .ValueGeneratedOnAdd();
            entity.Property(t => t.Name)
                .HasMaxLength(100)
                .IsRequired();
            entity.Property(t => t.Capacity)
                .IsRequired();
            entity.Property(t => t.Description)
                .HasMaxLength(500);
            entity.Property(t => t.IsAvailable)
                .IsRequired()
                .HasDefaultValue(true);
            entity.Property(t => t.CreatedAt)
                .IsRequired();
            entity.Property(t => t.IsDeleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasIndex(t => t.Name)
                .IsUnique();
        });

        modelBuilder.Entity<MenuItem>(entity =>
        {
            entity.HasKey(m => m.Id);

            entity.Property(m => m.Id)
                .ValueGeneratedOnAdd();
            entity.Property(m => m.Name)
                .HasMaxLength(100)
                .IsRequired();
            entity.Property(m => m.Kind)
                .IsRequired();
            entity.Property(m => m.Price)
                .HasColumnType("decimal(18,2)")
                .IsRequired();
            entity.Property(m => m.Description)
                .HasMaxLength(500);
            entity.Property(m => m.ImageUrl)
                .HasMaxLength(200)
                .HasConversion(
                    v => v != null ? v.AbsoluteUri : null,
                    v => v != null ? new Uri(v) : null
                );
            entity.Property(m => m.IsAvailable)
                .IsRequired()
                .HasDefaultValue(true);
            entity.Property(m => m.CreatedAt)
                .IsRequired();
            entity.Property(m => m.IsDeleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasIndex(m => m.Name)
                .IsUnique();
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.Property(e => e.Id)
                .ValueGeneratedOnAdd();
            entity.Property(e => e.FullName)
                .HasMaxLength(100)
                .IsRequired();
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .IsRequired();
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(200)
                .IsRequired();
            entity.Property(e => e.CreatedAt)
                .IsRequired();
            entity.Property(e => e.IsDeleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasIndex(e => e.Username)
                .IsUnique();
        });

        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasKey(o => o.Id);

            entity.Property(o => o.Id)
                .ValueGeneratedOnAdd();
            entity.Property(o => o.Number)
                .HasMaxLength(100)
                .IsRequired();
            entity.Property(o => o.Status)
                .IsRequired()
                .HasDefaultValue(OrderStatus.Pending);
            entity.Property(o => o.Note)
                .HasMaxLength(500);
            entity.Property(o => o.TotalAmount)
                .HasColumnType("decimal(18,2)")
                .IsRequired();
            entity.Property(o => o.CreatedAt)
                .IsRequired();
            entity.Property(o => o.IsDeleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasIndex(o => o.Number)
                .IsUnique();

            entity.HasOne(o => o.Table)
                .WithMany(t => t.Orders)
                .HasForeignKey(o => o.TableId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(o => o.Employee)
                .WithMany()
                .HasForeignKey(o => o.EmployeeId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasMany(o => o.Items)
                .WithOne(od => od.Order)
                .HasForeignKey(od => od.OrderId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OrderDetail>(entity =>
        {
            entity.HasKey(od => od.Id);

            entity.Property(od => od.Id)
                .ValueGeneratedOnAdd();
            entity.Property(od => od.Quantity)
                .IsRequired();
            entity.Property(od => od.Price)
                .HasColumnType("decimal(18,2)")
                .IsRequired();
            entity.Property(od => od.CreatedAt)
                .IsRequired();

            entity.HasOne(od => od.MenuItem)
                .WithMany()
                .HasForeignKey(od => od.MenuItemId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }

    private static void SeedData(ModelBuilder modelBuilder)
    {
        var passwordService = new PasswordService();

        var employee1 = new Employee
        {
            FullName = "Nguyễn Văn A",
            Username = "nguyenvana",
            PasswordHash = passwordService.HashPassword("password123"),
        };

        var employee2 = new Employee
        {
            FullName = "Trần Thị B",
            Username = "tranthib",
            PasswordHash = passwordService.HashPassword("password456"),
        };

        List<Employee> employees =
        [
            employee1,
            employee2,
        ];
        modelBuilder.Entity<Employee>().HasData(employees);

        var table1 = new Table
        {
            Name = "Bàn 1",
            Capacity = 4,
            Description = "Bàn gần cửa sổ",
            IsAvailable = true,
            CreatedAt = DateTime.UtcNow.AddDays(-20),
        };

        var table2 = new Table
        {
            Name = "Bàn 2",
            Capacity = 6,
            Description = "Bàn ở giữa nhà",
            IsAvailable = false,
            CreatedAt = DateTime.UtcNow.AddDays(-20),
        };

        var table3 = new Table
        {
            Name = "Bàn 3",
            Capacity = 2,
            Description = "Bàn nhỏ ở góc",
            IsAvailable = false,
            CreatedAt = DateTime.UtcNow.AddDays(-20),
        };

        var table4 = new Table
        {
            Name = "Bàn 4",
            Capacity = 8,
            Description = "Bàn lớn cho nhóm đông người",
            CreatedAt = DateTime.UtcNow.AddDays(-3),
        };

        List<Table> tables =
        [
            table1,
            table2,
            table3,
            table4,
        ];
        modelBuilder.Entity<Table>().HasData(tables);

        var menuItem1 = new MenuItem
        {
            Name = "Phở Bò",
            Kind = ItemKind.MainCourse,
            Price = 50_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/pho-bo.jpg"),
            Description = "Phở bò truyền thống với nước dùng đậm đà.",
        };

        var menuItem2 = new MenuItem
        {
            Name = "Bánh Mì Thịt Nướng",
            Kind = ItemKind.MainCourse,
            Price = 30_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/banh-mi-thit-nuong.jpg"),
            Description = "Bánh mì thịt nướng thơm ngon, giòn rụm.",
        };

        var menuItem3 = new MenuItem
        {
            Name = "Trà Sữa Trân Châu",
            Kind = ItemKind.Beverage,
            Price = 20_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/tra-sua-tran-chau.jpg"),
            Description = "Trà sữa thơm ngon với trân châu dai.",
        };

        var menuItem4 = new MenuItem
        {
            Name = "Gỏi Cuốn",
            Kind = ItemKind.Appetizer,
            Price = 15_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/goi-cuon.jpg"),
            Description = "Gỏi cuốn tươi ngon với nước chấm đặc biệt.",
        };

        var menuItem5 = new MenuItem
        {
            Name = "Bánh Flan",
            Kind = ItemKind.Dessert,
            Price = 10_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/banh-flan.jpg"),
            Description = "Bánh flan mềm mịn, ngọt ngào.",
        };

        var menuItem6 = new MenuItem
        {
            Name = "Cà Phê Sữa Đá",
            Kind = ItemKind.Beverage,
            Price = 25_000,
            ImageUrl = new Uri("http://10.0.2.2:5127/images/ca-phe-sua-da.jpg"),
            Description = "Cà phê sữa đá thơm ngon, đậm đà.",
        };

        List<MenuItem> menuItems =
        [
            menuItem1,
            menuItem2,
            menuItem3,
            menuItem4,
            menuItem5,
            menuItem6,
        ];
        modelBuilder.Entity<MenuItem>().HasData(menuItems);

        var order1CreatedAt = DateTime.UtcNow.AddDays(-1);
        var order1 = new Order
        {
            Number = Order.CreateNumber(),
            TableId = table1.Id,
            EmployeeId = employee1.Id,
            Status = OrderStatus.Completed,
            CreatedAt = order1CreatedAt,
        };

        var order2CreatedAt = DateTime.UtcNow.AddMinutes(-10);
        var order2 = new Order
        {
            Number = Order.CreateNumber(),
            TableId = table2.Id,
            EmployeeId = employee2.Id,
            Status = OrderStatus.InProgress,
            CreatedAt = order2CreatedAt,
        };

        var order3CreatedAt = DateTime.UtcNow;
        var order3 = new Order
        {
            Number = Order.CreateNumber(),
            TableId = table3.Id,
            EmployeeId = employee1.Id,
            CreatedAt = order3CreatedAt,
        };

        List<Order> orders =
        [
            order1,
            order2,
            order3,
        ];
        modelBuilder.Entity<Order>().HasData(orders);

        List<OrderDetail> order1Details =
        [
            new()
            {
                OrderId = order1.Id,
                MenuItemId = menuItem1.Id,
                Quantity = 2,
                Price = menuItem1.Price,
                CreatedAt = order1CreatedAt,
            },
            new()
            {
                OrderId = order1.Id,
                MenuItemId = menuItem3.Id,
                Quantity = 1,
                Price = menuItem3.Price,
                CreatedAt = order1CreatedAt,
            },
        ];
        order1.TotalAmount = order1Details.Sum(od => od.Quantity * od.Price);

        List<OrderDetail> order2Details =
        [
            new()
            {
                OrderId = order2.Id,
                MenuItemId = menuItem2.Id,
                Quantity = 1,
                Price = menuItem2.Price,
                CreatedAt = order2CreatedAt,
            },
            new()
            {
                OrderId = order2.Id,
                MenuItemId = menuItem4.Id,
                Quantity = 3,
                Price = menuItem4.Price,
                CreatedAt = order2CreatedAt,
            },
        ];
        order2.TotalAmount = order2Details.Sum(od => od.Quantity * od.Price);

        List<OrderDetail> order3Details =
        [
            new()
            {
                OrderId = order3.Id,
                MenuItemId = menuItem5.Id,
                Quantity = 2,
                Price = menuItem5.Price,
                CreatedAt = order3CreatedAt,
            },
            new()
            {
                OrderId = order3.Id,
                MenuItemId = menuItem6.Id,
                Quantity = 1,
                Price = menuItem6.Price,
                CreatedAt = order3CreatedAt,
            },
        ];
        order3.TotalAmount = order3Details.Sum(od => od.Quantity * od.Price);

        List<OrderDetail> orderDetails =
        [
            ..order1Details,
            ..order2Details,
            ..order3Details,
        ];
        modelBuilder.Entity<OrderDetail>().HasData(orderDetails);
    }
}
