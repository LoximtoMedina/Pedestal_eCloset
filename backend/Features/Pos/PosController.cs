using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pedestal.Api.Features.Pos.Dtos;

namespace Pedestal.Api.Features.Pos;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class PosController : ControllerBase
{
    private readonly PosService _posService;

    public PosController(PosService posService)
    {
        _posService = posService;
    }

    [HttpGet("registers")]
    [ProducesResponseType(typeof(List<CashRegisterDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRegisters([FromQuery] int? storeId, CancellationToken ct)
    {
        var result = await _posService.GetRegistersAsync(User, storeId, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpPost("registers")]
    [ProducesResponseType(typeof(CashRegisterDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateRegister([FromBody] CashRegisterUpsertDto dto, [FromQuery] int? storeId, CancellationToken ct)
    {
        var result = await _posService.CreateRegisterAsync(User, dto, storeId, ct);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [HttpPut("registers/{id:int}")]
    [ProducesResponseType(typeof(CashRegisterDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateRegister([FromRoute] int id, [FromBody] CashRegisterUpsertDto dto, CancellationToken ct)
    {
        var result = await _posService.UpdateRegisterAsync(User, id, dto, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpPost("shifts/open")]
    [ProducesResponseType(typeof(ShiftSummaryDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> OpenShift([FromBody] OpenShiftDto dto, CancellationToken ct)
    {
        var result = await _posService.OpenShiftAsync(User, dto, ct);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [HttpPost("shifts/{id:int}/close")]
    [ProducesResponseType(typeof(ShiftSummaryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> CloseShift([FromRoute] int id, [FromBody] CloseShiftDto dto, CancellationToken ct)
    {
        var result = await _posService.CloseShiftAsync(User, id, dto, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("shifts/current")]
    [ProducesResponseType(typeof(ShiftSummaryDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCurrentShift(CancellationToken ct)
    {
        var result = await _posService.GetCurrentShiftAsync(User, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("shifts")]
    [ProducesResponseType(typeof(List<ShiftSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetShifts([FromQuery] int? storeId, CancellationToken ct)
    {
        var result = await _posService.GetShiftsHistoryAsync(User, storeId, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("products/search")]
    [ProducesResponseType(typeof(List<PosProductDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SearchProducts([FromQuery] string? q, [FromQuery] int? storeId, CancellationToken ct)
    {
        var result = await _posService.SearchProductsAsync(User, q, storeId, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("customers/search")]
    [ProducesResponseType(typeof(List<CustomerSearchResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SearchCustomers([FromQuery] string? q, CancellationToken ct)
    {
        var result = await _posService.SearchCustomersAsync(q, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpPost("customers")]
    [ProducesResponseType(typeof(CustomerSearchResultDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateQuickCustomer([FromBody] QuickCustomerCreateDto dto, CancellationToken ct)
    {
        var result = await _posService.CreateQuickCustomerAsync(dto, ct);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [HttpPost("bills")]
    [ProducesResponseType(typeof(ReceiptDto), StatusCodes.Status201Created)]
    public async Task<IActionResult> CreateBill([FromBody] PosSaleRequestDto dto, CancellationToken ct)
    {
        var result = await _posService.CreateBillAsync(User, dto, ct);
        return ToActionResult(result, StatusCodes.Status201Created);
    }

    [HttpGet("bills")]
    [ProducesResponseType(typeof(List<ReceiptDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBills([FromQuery] int? storeId, CancellationToken ct)
    {
        var result = await _posService.GetBillsAsync(User, storeId, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpGet("bills/{id:int}")]
    [ProducesResponseType(typeof(ReceiptDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBillById([FromRoute] int id, CancellationToken ct)
    {
        var result = await _posService.GetBillByIdAsync(User, id, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    [HttpPost("bills/{id:int}/cancel")]
    [ProducesResponseType(typeof(ReceiptDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> CancelBill([FromRoute] int id, CancellationToken ct)
    {
        var result = await _posService.CancelBillAsync(User, id, ct);
        return ToActionResult(result, StatusCodes.Status200OK);
    }

    private IActionResult ToActionResult<T>(PosServiceResult<T> result, int successStatus)
    {
        if (!result.IsSuccess)
            return Problem(statusCode: result.StatusCode, title: result.ErrorTitle, detail: result.ErrorDetail);

        return StatusCode(successStatus, result.Data);
    }
}