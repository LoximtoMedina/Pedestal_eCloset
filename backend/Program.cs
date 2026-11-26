using Microsoft.EntityFrameworkCore;
using Pedestal.Api.Data;

//Features
using Pedestal.Api.Features.Shop;
// Descomentar conforme se creen sus clases:
// using Pedestal.Api.Features.Admin;
// using Pedestal.Api.Features.Auth;
// using Pedestal.Api.Features.Dashboards;
// using Pedestal.Api.Features.Ecloset;
// using Pedestal.Api.Features.Hr;
// using Pedestal.Api.Features.Inventory;
// using Pedestal.Api.Features.Pos;
// using Pedestal.Api.Features.Promotions;
// using Pedestal.Api.Features.Purchases;
// using Pedestal.Api.Features.User;

var builder = WebApplication.CreateBuilder(args);

// --- Base de datos (EF Core / User Secrets) ---
builder.Services.AddDbContext<PedestalDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- Servicios por feature (Scoped por petición HTTP) ---
builder.Services.AddScoped<ShopService>();
// Descomentar conforme se creen sus clases:
// builder.Services.AddScoped<AdminService>();
// builder.Services.AddScoped<AuthService>();
// builder.Services.AddScoped<DashboardsService>();
// builder.Services.AddScoped<EclosetService>();
// builder.Services.AddScoped<HrService>();
// builder.Services.AddScoped<InventoryService>();
// builder.Services.AddScoped<PosService>();
// builder.Services.AddScoped<PromotionsService>();
// builder.Services.AddScoped<PurchasesService>();
// builder.Services.AddScoped<UserService>();

// --- Infraestructura y reglas ---
// builder.Services.AddScoped<StorageService>();

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();