using Pedestal.Api.Data;

namespace Pedestal.Api.Features.Shop
{
    public class ShopService
    {
        private readonly PedestalDbContext _context;

        public ShopService(PedestalDbContext context)
        {
            _context = context;
        }

        // Aquí van los métodos de negocio (ej. GetProductsAsync, CreateOrderAsync...)
    }
}