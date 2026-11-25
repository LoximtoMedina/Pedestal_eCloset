using Microsoft.AspNetCore.Mvc;
using Pedestal.Api.Features.Shop;

namespace Pedestal.Api.Features.Shop
{
    [ApiController]
    [Route("api/[controller]")]
    public class ShopController : ControllerBase
    {
        private readonly ShopService _shopService;

        public ShopController(ShopService shopService)
        {
            _shopService = shopService;
        }

        // Aquí van los endpoints: [HttpGet], [HttpPost], [HttpPut], [HttpDelete]
    }
}