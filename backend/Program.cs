using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Pedestal.Api.Data;
using Pedestal.Api.Features.Auth;
using Pedestal.Api.Features.Shop;
// Descomentar conforme se creen sus clases:
// using Pedestal.Api.Features.Admin;
// using Pedestal.Api.Features.Dashboards;
// using Pedestal.Api.Features.Ecloset;
// using Pedestal.Api.Features.Hr;
// using Pedestal.Api.Features.Inventory;
// using Pedestal.Api.Features.Pos;
// using Pedestal.Api.Features.Promotions;
// using Pedestal.Api.Features.Purchases;
// using Pedestal.Api.Features.User;
// using Pedestal.Api.Infrastructure.Storage;

var builder = WebApplication.CreateBuilder(args);

// --- Base de datos (EF Core / User Secrets) ---
builder.Services.AddDbContext<PedestalDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- CORS para el frontend en http://localhost:5173 ---
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy.WithOrigins("http://localhost:5173")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// --- JWT desde User Secrets ---
var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"]
    ?? throw new InvalidOperationException("Falta Jwt:Key en User Secrets.");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSection["Issuer"] ?? "PedestalApi",
            ValidAudience = jwtSection["Audience"] ?? "PedestalClient",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

// --- Servicios por feature (Scoped por petición HTTP) ---
builder.Services.AddScoped<ShopService>();
builder.Services.AddScoped<AuthService>();
// Descomentar conforme se creen sus clases:
// builder.Services.AddScoped<AdminService>();
// builder.Services.AddScoped<DashboardsService>();
// builder.Services.AddScoped<EclosetService>();
// builder.Services.AddScoped<HrService>();
// builder.Services.AddScoped<InventoryService>();
// builder.Services.AddScoped<PosService>();
// builder.Services.AddScoped<PromotionsService>();
// builder.Services.AddScoped<PurchasesService>();
// builder.Services.AddScoped<UserService>();

// --- Infraestructura (IImageStorage según configuración) ---
// builder.Services.AddScoped<IImageStorage, LocalDiskImageStorage>();

builder.Services.AddControllers();
builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();

var app = builder.Build();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseCors("FrontendPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();