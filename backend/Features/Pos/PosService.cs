using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Pedestal.Api.Data;
using Pedestal.Api.Data.Entities;
using Pedestal.Api.Features.Pos.Dtos;

namespace Pedestal.Api.Features.Pos;

public sealed record PosServiceResult<T>(
    bool IsSuccess,
    int StatusCode,
    string? ErrorTitle,
    string? ErrorDetail,
    T? Data = default)
{
    public static PosServiceResult<T> Ok(T data, int statusCode = 200) => new(true, statusCode, null, null, data);
    public static PosServiceResult<T> Fail(int statusCode, string title, string detail) => new(false, statusCode, title, detail);
}

public sealed class PosService
{
    private readonly PedestalDbContext _db;

    public PosService(PedestalDbContext db)
    {
        _db = db;
    }

    public async Task<PosServiceResult<List<CashRegisterDto>>> GetRegistersAsync(
        ClaimsPrincipal user, int? requestedStoreId, CancellationToken ct = default)
    {
        var storeScope = ResolveStoreScope(user, requestedStoreId);
        if (!storeScope.IsAllowed)
            return PosServiceResult<List<CashRegisterDto>>.Fail(403, "Acceso denegado", storeScope.Reason!);

        var query = _db.CashRegisters.AsNoTracking().Where(r => r.Active);
        if (storeScope.StoreId.HasValue)
            query = query.Where(r => r.StoreId == storeScope.StoreId.Value);

        var items = await query
            .OrderBy(r => r.Id)
            .Select(r => new CashRegisterDto
            {
                Id = r.Id,
                StoreId = r.StoreId,
                Name = r.Name,
                Description = r.Description,
                Active = r.Active
            })
            .ToListAsync(ct);

        return PosServiceResult<List<CashRegisterDto>>.Ok(items);
    }

    public async Task<PosServiceResult<CashRegisterDto>> CreateRegisterAsync(
        ClaimsPrincipal user, CashRegisterUpsertDto dto, int? requestedStoreId, CancellationToken ct = default)
    {
        if (!IsSupervisorOrHigher(user))
            return PosServiceResult<CashRegisterDto>.Fail(403, "Permiso insuficiente", "Solo un supervisor o superior puede crear cajas.");

        var storeScope = ResolveStoreScope(user, requestedStoreId);
        if (!storeScope.IsAllowed || !storeScope.StoreId.HasValue)
            return PosServiceResult<CashRegisterDto>.Fail(400, "Tienda requerida", "No se pudo determinar la tienda para la caja.");

        var nameNorm = dto.Name.Trim();
        var duplicate = await _db.CashRegisters.AnyAsync(r => r.StoreId == storeScope.StoreId.Value && r.Name == nameNorm, ct);
        if (duplicate)
            return PosServiceResult<CashRegisterDto>.Fail(409, "Caja duplicada", "Ya existe una caja con ese nombre en la tienda.");

        var register = new CashRegister
        {
            StoreId = storeScope.StoreId.Value,
            Name = nameNorm,
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim(),
            RegistrationDate = DateTime.UtcNow,
            Active = true
        };

        _db.CashRegisters.Add(register);
        await _db.SaveChangesAsync(ct);

        return PosServiceResult<CashRegisterDto>.Ok(new CashRegisterDto
        {
            Id = register.Id,
            StoreId = register.StoreId,
            Name = register.Name,
            Description = register.Description,
            Active = register.Active
        }, StatusCodes.Status201Created);
    }

    public async Task<PosServiceResult<CashRegisterDto>> UpdateRegisterAsync(
        ClaimsPrincipal user, int registerId, CashRegisterUpsertDto dto, CancellationToken ct = default)
    {
        if (!IsSupervisorOrHigher(user))
            return PosServiceResult<CashRegisterDto>.Fail(403, "Permiso insuficiente", "Solo un supervisor o superior puede editar cajas.");

        var register = await _db.CashRegisters.FirstOrDefaultAsync(r => r.Id == registerId, ct);
        if (register is null)
            return PosServiceResult<CashRegisterDto>.Fail(404, "Caja no encontrada", "No existe la caja especificada.");

        if (!HasStoreAccess(user, register.StoreId))
            return PosServiceResult<CashRegisterDto>.Fail(403, "Fuera de alcance", "No tienes acceso a la tienda de esta caja.");

        register.Name = dto.Name.Trim();
        register.Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim();
        register.Active = dto.Active;
        await _db.SaveChangesAsync(ct);

        return PosServiceResult<CashRegisterDto>.Ok(new CashRegisterDto
        {
            Id = register.Id,
            StoreId = register.StoreId,
            Name = register.Name,
            Description = register.Description,
            Active = register.Active
        });
    }

    public async Task<PosServiceResult<ShiftSummaryDto>> OpenShiftAsync(
        ClaimsPrincipal user, OpenShiftDto dto, CancellationToken ct = default)
    {
        var employeeId = GetClaimInt(user, "employeeId");
        if (!employeeId.HasValue)
            return PosServiceResult<ShiftSummaryDto>.Fail(403, "Empleado requerido", "La sesión no tiene un empleado asociado.");

        var register = await _db.CashRegisters.FirstOrDefaultAsync(r => r.Id == dto.CashRegisterId && r.Active, ct);
        if (register is null)
            return PosServiceResult<ShiftSummaryDto>.Fail(404, "Caja no encontrada", "La caja no existe o está inactiva.");

        if (!HasStoreAccess(user, register.StoreId))
            return PosServiceResult<ShiftSummaryDto>.Fail(403, "Fuera de alcance", "La caja pertenece a otra tienda.");

        var existingOpen = await _db.CashShifts.AnyAsync(s =>
            s.Status == "OPEN" &&
            (s.EmployeeId == employeeId.Value || s.CashRegisterId == register.Id), ct);

        if (existingOpen)
            return PosServiceResult<ShiftSummaryDto>.Fail(409, "Turno abierto existente", "El empleado o la caja ya tienen un turno OPEN.");

        var shift = new CashShift
        {
            CashRegisterId = register.Id,
            EmployeeId = employeeId.Value,
            OpenedAt = DateTime.UtcNow,
            OpeningAmount = dto.OpeningAmount,
            Status = "OPEN"
        };

        _db.CashShifts.Add(shift);
        await _db.SaveChangesAsync(ct);

        return await GetShiftSummaryAsync(shift.Id, ct);
    }

    public async Task<PosServiceResult<ShiftSummaryDto>> CloseShiftAsync(
        ClaimsPrincipal user, int shiftId, CloseShiftDto dto, CancellationToken ct = default)
    {
        var shift = await _db.CashShifts.FirstOrDefaultAsync(s => s.Id == shiftId, ct);
        if (shift is null)
            return PosServiceResult<ShiftSummaryDto>.Fail(404, "Turno no encontrado", "No existe el turno indicado.");

        var register = await _db.CashRegisters.FirstOrDefaultAsync(r => r.Id == shift.CashRegisterId, ct);
        if (register is null || !HasStoreAccess(user, register.StoreId))
            return PosServiceResult<ShiftSummaryDto>.Fail(403, "Fuera de alcance", "No tienes acceso a este turno.");

        if (!string.Equals(shift.Status, "OPEN", StringComparison.OrdinalIgnoreCase))
            return PosServiceResult<ShiftSummaryDto>.Fail(409, "Estado inválido", "Solo se puede cerrar un turno en estado OPEN.");

        shift.ClosingAmount = dto.ClosingAmount;
        shift.ClosedAt = DateTime.UtcNow;
        shift.Status = "CLOSED";

        await _db.SaveChangesAsync(ct);

        return await GetShiftSummaryAsync(shift.Id, ct);
    }

    public async Task<PosServiceResult<ShiftSummaryDto?>> GetCurrentShiftAsync(
        ClaimsPrincipal user, CancellationToken ct = default)
    {
        var employeeId = GetClaimInt(user, "employeeId");
        if (!employeeId.HasValue)
            return PosServiceResult<ShiftSummaryDto?>.Fail(403, "Empleado requerido", "La sesión no tiene un empleado asociado.");

        var shift = await _db.CashShifts
            .AsNoTracking()
            .Where(s => s.EmployeeId == employeeId.Value && s.Status == "OPEN")
            .OrderByDescending(s => s.Id)
            .FirstOrDefaultAsync(ct);

        if (shift is null)
            return PosServiceResult<ShiftSummaryDto?>.Ok(null);

        var summary = await GetShiftSummaryAsync(shift.Id, ct);
        return summary.IsSuccess
            ? PosServiceResult<ShiftSummaryDto?>.Ok(summary.Data)
            : PosServiceResult<ShiftSummaryDto?>.Fail(summary.StatusCode, summary.ErrorTitle!, summary.ErrorDetail!);
    }

    public async Task<PosServiceResult<List<ShiftSummaryDto>>> GetShiftsHistoryAsync(
        ClaimsPrincipal user, int? requestedStoreId, CancellationToken ct = default)
    {
        if (!IsSupervisorOrHigher(user))
            return PosServiceResult<List<ShiftSummaryDto>>.Fail(403, "Permiso insuficiente", "Solo un supervisor o superior puede ver el historial de turnos.");

        var storeScope = ResolveStoreScope(user, requestedStoreId);
        if (!storeScope.IsAllowed)
            return PosServiceResult<List<ShiftSummaryDto>>.Fail(403, "Acceso denegado", storeScope.Reason!);

        var query = _db.VwCashShiftSummaries.AsNoTracking();
        if (storeScope.StoreId.HasValue)
            query = query.Where(v => v.StoreId == storeScope.StoreId.Value);

        var rows = await query.OrderByDescending(v => v.CashShiftId).Take(100).ToListAsync(ct);

        var list = rows.Select(MapShiftSummary).ToList();
        return PosServiceResult<List<ShiftSummaryDto>>.Ok(list);
    }

    public async Task<PosServiceResult<List<PosProductDto>>> SearchProductsAsync(
        ClaimsPrincipal user, string? queryText, int? requestedStoreId, CancellationToken ct = default)
    {
        var storeScope = ResolveStoreScope(user, requestedStoreId);
        if (!storeScope.IsAllowed || !storeScope.StoreId.HasValue)
            return PosServiceResult<List<PosProductDto>>.Fail(400, "Tienda requerida", "No se pudo determinar la tienda.");

        var term = (queryText ?? string.Empty).Trim().ToLowerInvariant();

        var stockByVariant = await _db.VwStoreStocks
            .AsNoTracking()
            .Where(s => s.StoreId == storeScope.StoreId.Value)
            .ToDictionaryAsync(s => s.ClotheVariantId, s => s.Quantity ?? 0, ct);

        var variants = await _db.ClotheVariants
            .AsNoTracking()
            .Include(v => v.Clothe)
            .Include(v => v.Size)
            .Include(v => v.Color)
            .Where(v => v.Active && v.Clothe != null && v.Clothe.Active)
            .ToListAsync(ct);

        var results = variants
            .Where(v => string.IsNullOrEmpty(term) ||
                         v.Sku.ToLowerInvariant().Contains(term) ||
                         v.Clothe!.Name.ToLowerInvariant().Contains(term))
            .Select(v => new PosProductDto
            {
                ClotheVariantId = v.Id,
                ClotheId = v.ClotheId,
                Sku = v.Sku,
                ClotheName = v.Clothe!.Name,
                SizeName = v.Size?.Name,
                ColorName = v.Color?.Name,
                UnitPrice = v.PriceOverride ?? v.Clothe.BasePrice,
                AvailableStock = stockByVariant.TryGetValue(v.Id, out var qty) ? qty : 0
            })
            .ToList();

        return PosServiceResult<List<PosProductDto>>.Ok(results);
    }

    public async Task<PosServiceResult<List<CustomerSearchResultDto>>> SearchCustomersAsync(
        string? queryText, CancellationToken ct = default)
    {
        var term = (queryText ?? string.Empty).Trim().ToLowerInvariant();

        var people = await _db.People
            .AsNoTracking()
            .Include(p => p.Phones)
            .Where(p => p.Active)
            .ToListAsync(ct);

        var list = people
            .Where(p =>
            {
                if (string.IsNullOrEmpty(term)) return true;
                var docMatch = p.DocumentId != null && p.DocumentId.ToLowerInvariant().Contains(term);
                var nameMatch = ($"{p.FirstName} {p.FirstSurname}").ToLowerInvariant().Contains(term);
                var phoneMatch = p.Phones.Any(ph => ph.Active && ph.Phone1.ToLowerInvariant().Contains(term));
                return docMatch || nameMatch || phoneMatch;
            })
            .Take(30)
            .Select(p => new CustomerSearchResultDto
            {
                PersonId = p.Id,
                DocumentId = p.DocumentId,
                FullName = $"{p.FirstName} {p.FirstSurname}".Trim(),
                Email = p.Email,
                Phone = p.Phones.FirstOrDefault(ph => ph.Active)?.Phone1
            })
            .ToList();

        return PosServiceResult<List<CustomerSearchResultDto>>.Ok(list);
    }

    public async Task<PosServiceResult<CustomerSearchResultDto>> CreateQuickCustomerAsync(
        QuickCustomerCreateDto dto, CancellationToken ct = default)
    {
        var doc = dto.DocumentId.Trim();
        var exists = await _db.People.AnyAsync(p => p.DocumentId == doc && p.Active, ct);
        if (exists)
            return PosServiceResult<CustomerSearchResultDto>.Fail(409, "Documento duplicado", "Ya existe una persona activa con ese documento.");

        var now = DateTime.UtcNow;
        var person = new Person
        {
            DocumentId = doc,
            FirstName = dto.FirstName.Trim(),
            MiddleName = string.IsNullOrWhiteSpace(dto.MiddleName) ? null : dto.MiddleName.Trim(),
            FirstSurname = dto.FirstSurname.Trim(),
            SecondSurname = string.IsNullOrWhiteSpace(dto.SecondSurname) ? null : dto.SecondSurname.Trim(),
            Email = string.IsNullOrWhiteSpace(dto.Email) ? null : dto.Email.Trim().ToLowerInvariant(),
            RegistrationDate = now,
            Active = true
        };

        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            _db.People.Add(person);
            await _db.SaveChangesAsync(ct);

            if (!string.IsNullOrWhiteSpace(dto.Phone))
            {
                _db.Phones.Add(new Phone
                {
                    PersonId = person.Id,
                    Phone1 = dto.Phone.Trim(),
                    RegistrationDate = now,
                    Active = true
                });
                await _db.SaveChangesAsync(ct);
            }

            await tx.CommitAsync(ct);
        }
        catch
        {
            await tx.RollbackAsync(ct);
            throw;
        }

        return PosServiceResult<CustomerSearchResultDto>.Ok(new CustomerSearchResultDto
        {
            PersonId = person.Id,
            DocumentId = person.DocumentId,
            FullName = $"{person.FirstName} {person.FirstSurname}".Trim(),
            Email = person.Email,
            Phone = string.IsNullOrWhiteSpace(dto.Phone) ? null : dto.Phone.Trim()
        }, StatusCodes.Status201Created);
    }

    public async Task<PosServiceResult<ReceiptDto>> CreateBillAsync(
        ClaimsPrincipal user, PosSaleRequestDto dto, CancellationToken ct = default)
    {
        var employeeId = GetClaimInt(user, "employeeId");
        if (!employeeId.HasValue)
            return PosServiceResult<ReceiptDto>.Fail(403, "Empleado requerido", "Solo un empleado en sesión puede registrar ventas POS.");

        var openShift = await _db.CashShifts
            .FirstOrDefaultAsync(s => s.EmployeeId == employeeId.Value && s.Status == "OPEN", ct);

        if (openShift is null)
            return PosServiceResult<ReceiptDto>.Fail(409, "Turno cerrado", "Debe abrir un turno de caja antes de registrar una venta.");

        var register = await _db.CashRegisters
            .FirstOrDefaultAsync(r => r.Id == openShift.CashRegisterId && r.Active, ct);

        if (register is null)
            return PosServiceResult<ReceiptDto>.Fail(404, "Caja no encontrada", "No se encontró la caja del turno.");

        var storeId = register.StoreId;
        if (!HasStoreAccess(user, storeId))
            return PosServiceResult<ReceiptDto>.Fail(403, "Fuera de alcance", "No tienes acceso a la tienda del turno.");

        int customerPersonId;
        if (dto.PersonId.HasValue)
        {
            var personExists = await _db.People.AnyAsync(p => p.Id == dto.PersonId.Value && p.Active, ct);
            if (!personExists)
                return PosServiceResult<ReceiptDto>.Fail(404, "Cliente no encontrado", "El cliente indicado no existe.");
            customerPersonId = dto.PersonId.Value;
        }
        else
        {
            var fallbackPersonId = await _db.People.Where(p => p.Active).Select(p => p.Id).FirstOrDefaultAsync(ct);
            if (fallbackPersonId == 0)
                return PosServiceResult<ReceiptDto>.Fail(400, "Cliente requerido", "Debe indicar un cliente válido (PersonId).");
            customerPersonId = fallbackPersonId;
        }

        var activeTax = await _db.Taxes
            .AsNoTracking()
            .Where(t => t.Active)
            .OrderBy(t => t.Id)
            .FirstOrDefaultAsync(ct);
        var taxRate = activeTax is not null ? activeTax.Percentage / 100m : 0.15m;

        var now = DateTime.UtcNow;
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            decimal subTotal = 0m;
            decimal discountTotal = 0m;
            decimal taxTotal = 0m;
            var receiptLines = new List<ReceiptLineDto>();
            var pendingDetails = new List<(int VariantId, int Qty, decimal UnitPrice, decimal LineSub, decimal LineDisc, decimal LineTax, decimal LineTot, string Sku, string ClotheName)>();

            foreach (var line in dto.Lines)
            {
                var variant = await _db.ClotheVariants
                    .Include(v => v.Clothe)
                    .FirstOrDefaultAsync(v => v.Id == line.ClotheVariantId && v.Active, ct);

                if (variant is null || variant.Clothe is null)
                    return PosServiceResult<ReceiptDto>.Fail(404, "Variante no encontrada", $"La variante {line.ClotheVariantId} no existe.");

                var cubicles = await _db.ClothesInCubicles
                    .Include(cic => cic.Cubicle)
                        .ThenInclude(c => c!.Rack)
                    .Where(cic => cic.ClotheVariantId == variant.Id &&
                                  cic.Cubicle != null &&
                                  cic.Cubicle.Rack != null &&
                                  cic.Cubicle.Rack.StoreId == storeId &&
                                  cic.Quantity > 0)
                    .OrderByDescending(cic => cic.Quantity)
                    .ToListAsync(ct);

                var available = cubicles.Sum(c => c.Quantity);
                if (available < line.Quantity)
                    return PosServiceResult<ReceiptDto>.Fail(409, "Stock insuficiente", $"Stock insuficiente para SKU {variant.Sku} en la tienda.");

                var remaining = line.Quantity;
                foreach (var cub in cubicles)
                {
                    if (remaining == 0) break;
                    var take = Math.Min(cub.Quantity, remaining);
                    cub.Quantity -= take;
                    remaining -= take;

                    _db.StockMovements.Add(new StockMovement
                    {
                        ClotheVariantId = variant.Id,
                        FromStoreId = storeId,
                        FromCubicleId = cub.CubicleId,
                        EmployeeId = employeeId.Value,
                        Quantity = take,
                        MovementType = "OUT",
                        Reason = "POS_SALE",
                        RegistrationDate = now,
                        Active = true
                    });
                }

                var unitPrice = variant.PriceOverride ?? variant.Clothe.BasePrice;
                var lineSub = Math.Round(unitPrice * line.Quantity, 2);
                var lineDisc = 0m;
                var lineTax = Math.Round((lineSub - lineDisc) * taxRate, 2);
                var lineTot = Math.Round(lineSub - lineDisc + lineTax, 2);

                subTotal += lineSub;
                discountTotal += lineDisc;
                taxTotal += lineTax;

                pendingDetails.Add((variant.Id, line.Quantity, unitPrice, lineSub, lineDisc, lineTax, lineTot, variant.Sku, variant.Clothe.Name));
            }

            var couponTotal = 0m;
            var shippingTotal = 0m;
            var total = Math.Round(subTotal - discountTotal - couponTotal + taxTotal + shippingTotal, 2);
            var paidSum = Math.Round(dto.Payments.Sum(p => p.Amount), 2);

            if (paidSum != total)
                return PosServiceResult<ReceiptDto>.Fail(409, "Pago inválido", $"La suma de pagos ({paidSum}) debe igualar el total de la factura ({total}).");

            var billCode = $"POS-{storeId}-{now:yyyyMMddHHmmss}-{Random.Shared.Next(100, 999)}";
            var bill = new Bill
            {
                BillCode = billCode,
                PersonId = customerPersonId,
                EmployeeId = employeeId.Value,
                CashShiftId = openShift.Id,
                StoreId = storeId,
                Channel = "INSTORE",
                Status = "PAID",
                SubTotal = subTotal,
                DiscountTotal = discountTotal,
                CouponTotal = couponTotal,
                ShippingTotal = shippingTotal,
                TaxTotal = taxTotal,
                Total = total,
                RegistrationDate = now,
                Active = true
            };

            _db.Bills.Add(bill);
            await _db.SaveChangesAsync(ct);

            foreach (var d in pendingDetails)
            {
                _db.BillDetails.Add(new BillDetail
                {
                    BillId = bill.Id,
                    ClotheVariantId = d.VariantId,
                    Quantity = d.Qty,
                    UnitPrice = d.UnitPrice,
                    DiscountAmount = d.LineDisc,
                    TaxAmount = d.LineTax
                });

                receiptLines.Add(new ReceiptLineDto
                {
                    ClotheVariantId = d.VariantId,
                    Sku = d.Sku,
                    ClotheName = d.ClotheName,
                    Quantity = d.Qty,
                    UnitPrice = d.UnitPrice,
                    SubTotal = d.LineSub,
                    DiscountAmount = d.LineDisc,
                    TaxAmount = d.LineTax,
                    Total = d.LineTot
                });
            }

            var receiptPayments = new List<ReceiptPaymentDto>();
            foreach (var pay in dto.Payments)
            {
                var method = await _db.PaymentMethods.FirstOrDefaultAsync(pm => pm.Id == pay.PaymentMethodId && pm.Active, ct);
                if (method is null)
                    return PosServiceResult<ReceiptDto>.Fail(404, "Método de pago inválido", $"No existe el método de pago {pay.PaymentMethodId}.");

                if (!method.AllowedInStore)
                    return PosServiceResult<ReceiptDto>.Fail(409, "Método no permitido", $"El método '{method.Name}' no está habilitado en tienda.");

                var reference = string.IsNullOrWhiteSpace(pay.PaymentReference)
                    ? $"PAY-{bill.Id}-{Guid.NewGuid().ToString("N")[..6].ToUpperInvariant()}"
                    : pay.PaymentReference.Trim();

                _db.BillHasPaymentMethods.Add(new BillHasPaymentMethod
                {
                    BillId = bill.Id,
                    PaymentMethodId = method.Id,
                    PaymentCardId = pay.PaymentCardId,
                    PaidAmount = pay.Amount,
                    PaymentReference = reference,
                    RegistrationDate = now
                });

                receiptPayments.Add(new ReceiptPaymentDto
                {
                    PaymentMethodId = method.Id,
                    PaymentMethodName = method.Name,
                    PaidAmount = pay.Amount,
                    PaymentReference = reference
                });
            }

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);

            var person = await _db.People.AsNoTracking().FirstOrDefaultAsync(p => p.Id == customerPersonId, ct);
            var customerName = person is null ? "Cliente" : $"{person.FirstName} {person.FirstSurname}".Trim();

            return PosServiceResult<ReceiptDto>.Ok(new ReceiptDto
            {
                BillId = bill.Id,
                BillCode = bill.BillCode,
                StoreId = storeId,
                CashShiftId = openShift.Id,
                EmployeeId = employeeId.Value,
                PersonId = customerPersonId,
                CustomerName = customerName,
                Channel = bill.Channel,
                Status = bill.Status,
                RegistrationDate = bill.RegistrationDate,
                SubTotal = bill.SubTotal,
                DiscountTotal = bill.DiscountTotal,
                CouponTotal = bill.CouponTotal,
                TaxTotal = bill.TaxTotal,
                Total = bill.Total,
                Lines = receiptLines,
                Payments = receiptPayments
            }, StatusCodes.Status201Created);
        }
        catch
        {
            await tx.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<PosServiceResult<List<ReceiptDto>>> GetBillsAsync(
        ClaimsPrincipal user, int? requestedStoreId, CancellationToken ct = default)
    {
        var storeScope = ResolveStoreScope(user, requestedStoreId);
        if (!storeScope.IsAllowed)
            return PosServiceResult<List<ReceiptDto>>.Fail(403, "Acceso denegado", storeScope.Reason!);

        var query = _db.Bills
            .AsNoTracking()
            .Include(b => b.Person)
            .Where(b => b.Active && b.Channel == "POS");

        if (storeScope.StoreId.HasValue)
            query = query.Where(b => b.StoreId == storeScope.StoreId.Value);

        var bills = await query.OrderByDescending(b => b.Id).Take(100).ToListAsync(ct);

        var items = bills.Select(b => new ReceiptDto
        {
            BillId = b.Id,
            BillCode = b.BillCode,
            StoreId = b.StoreId,
            CashShiftId = b.CashShiftId,
            EmployeeId = b.EmployeeId,
            PersonId = b.PersonId,
            CustomerName = b.Person is null ? string.Empty : $"{b.Person.FirstName} {b.Person.FirstSurname}".Trim(),
            Channel = b.Channel,
            Status = b.Status,
            RegistrationDate = b.RegistrationDate,
            SubTotal = b.SubTotal,
            DiscountTotal = b.DiscountTotal,
            CouponTotal = b.CouponTotal,
            TaxTotal = b.TaxTotal,
            Total = b.Total
        }).ToList();

        return PosServiceResult<List<ReceiptDto>>.Ok(items);
    }

    public async Task<PosServiceResult<ReceiptDto>> GetBillByIdAsync(
        ClaimsPrincipal user, int billId, CancellationToken ct = default)
    {
        var bill = await _db.Bills
            .AsNoTracking()
            .Include(b => b.Person)
            .Include(b => b.BillDetails)
                .ThenInclude(d => d.ClotheVariant)
                    .ThenInclude(v => v.Clothe)
            .Include(b => b.BillHasPaymentMethods)
                .ThenInclude(bp => bp.PaymentMethod)
            .FirstOrDefaultAsync(b => b.Id == billId && b.Active, ct);

        if (bill is null)
            return PosServiceResult<ReceiptDto>.Fail(404, "Factura no encontrada", "No existe la factura solicitada.");

        if (!HasStoreAccess(user, bill.StoreId))
            return PosServiceResult<ReceiptDto>.Fail(403, "Fuera de alcance", "No tienes acceso a esta factura.");

        return PosServiceResult<ReceiptDto>.Ok(new ReceiptDto
        {
            BillId = bill.Id,
            BillCode = bill.BillCode,
            StoreId = bill.StoreId,
            CashShiftId = bill.CashShiftId,
            EmployeeId = bill.EmployeeId,
            PersonId = bill.PersonId,
            CustomerName = bill.Person is null ? string.Empty : $"{bill.Person.FirstName} {bill.Person.FirstSurname}".Trim(),
            Channel = bill.Channel,
            Status = bill.Status,
            RegistrationDate = bill.RegistrationDate,
            SubTotal = bill.SubTotal,
            DiscountTotal = bill.DiscountTotal,
            CouponTotal = bill.CouponTotal,
            TaxTotal = bill.TaxTotal,
            Total = bill.Total,
            Lines = bill.BillDetails.Select(d => new ReceiptLineDto
            {
                ClotheVariantId = d.ClotheVariantId,
                Sku = d.ClotheVariant?.Sku ?? string.Empty,
                ClotheName = d.ClotheVariant?.Clothe?.Name ?? string.Empty,
                Quantity = d.Quantity,
                UnitPrice = d.UnitPrice,
                SubTotal = d.SubTotal ?? Math.Round(d.Quantity * d.UnitPrice, 2),
                DiscountAmount = d.DiscountAmount,
                TaxAmount = d.TaxAmount,
                Total = d.Total ?? Math.Round((d.Quantity * d.UnitPrice - d.DiscountAmount) + d.TaxAmount, 2)
            }).ToList(),
            Payments = bill.BillHasPaymentMethods.Select(bp => new ReceiptPaymentDto
            {
                PaymentMethodId = bp.PaymentMethodId,
                PaymentMethodName = bp.PaymentMethod?.Name ?? string.Empty,
                PaidAmount = bp.PaidAmount,
                PaymentReference = bp.PaymentReference
            }).ToList()
        });
    }

    public async Task<PosServiceResult<ReceiptDto>> CancelBillAsync(
        ClaimsPrincipal user, int billId, CancellationToken ct = default)
    {
        if (!IsSupervisorOrHigher(user))
            return PosServiceResult<ReceiptDto>.Fail(403, "Permiso insuficiente", "Solo un supervisor o superior puede anular facturas.");

        var employeeId = GetClaimInt(user, "employeeId");
        var bill = await _db.Bills
            .Include(b => b.BillDetails)
            .FirstOrDefaultAsync(b => b.Id == billId && b.Active, ct);

        if (bill is null)
            return PosServiceResult<ReceiptDto>.Fail(404, "Factura no encontrada", "No existe la factura indicada.");

        if (!HasStoreAccess(user, bill.StoreId))
            return PosServiceResult<ReceiptDto>.Fail(403, "Fuera de alcance", "No tienes acceso a la tienda de esta factura.");

        if (string.Equals(bill.Status, "CANCELLED", StringComparison.OrdinalIgnoreCase))
            return PosServiceResult<ReceiptDto>.Fail(409, "Ya anulada", "La factura ya se encuentra en estado CANCELLED.");

        var now = DateTime.UtcNow;
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            bill.Status = "CANCELLED";

            foreach (var detail in bill.BillDetails)
            {
                var targetCubicle = await _db.ClothesInCubicles
                    .Include(cic => cic.Cubicle)
                        .ThenInclude(c => c!.Rack)
                    .Where(cic => cic.ClotheVariantId == detail.ClotheVariantId &&
                                  cic.Cubicle != null &&
                                  cic.Cubicle.Rack != null &&
                                  cic.Cubicle.Rack.StoreId == bill.StoreId)
                    .OrderBy(cic => cic.CubicleId)
                    .FirstOrDefaultAsync(ct);

                if (targetCubicle is not null)
                {
                    targetCubicle.Quantity += detail.Quantity;
                }

                _db.StockMovements.Add(new StockMovement
                {
                    ClotheVariantId = detail.ClotheVariantId,
                    ToStoreId = bill.StoreId,
                    ToCubicleId = targetCubicle?.CubicleId,
                    BillDetailsId = detail.Id,
                    EmployeeId = employeeId,
                    Quantity = detail.Quantity,
                    MovementType = "IN",
                    Reason = $"CANCEL_BILL_{bill.BillCode}",
                    RegistrationDate = now,
                    Active = true
                });
            }

            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
        }
        catch
        {
            await tx.RollbackAsync(ct);
            throw;
        }

        return await GetBillByIdAsync(user, bill.Id, ct);
    }

    private async Task<PosServiceResult<ShiftSummaryDto>> GetShiftSummaryAsync(int shiftId, CancellationToken ct)
    {
        var row = await _db.VwCashShiftSummaries
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.CashShiftId == shiftId, ct);

        if (row is null)
            return PosServiceResult<ShiftSummaryDto>.Fail(404, "Turno no encontrado", "No se encontró el resumen del turno.");

        return PosServiceResult<ShiftSummaryDto>.Ok(MapShiftSummary(row));
    }

    private static ShiftSummaryDto MapShiftSummary(VwCashShiftSummary row) => new()
    {
        CashShiftId = row.CashShiftId,
        StoreId = row.StoreId,
        CashRegisterId = row.CashRegisterId,
        CashRegisterName = row.CashRegisterName,
        EmployeeId = row.EmployeeId,
        EmployeeName = row.EmployeeName ?? string.Empty,
        OpenedAt = row.OpenedAt,
        ClosedAt = row.ClosedAt,
        Status = row.Status,
        OpeningAmount = row.OpeningAmount,
        CashSales = row.CashSales,
        CardSales = row.CardSales,
        ExpectedCash = row.ExpectedCash ?? 0m,
        ClosingAmount = row.ClosingAmount,
        CashDifference = row.CashDifference
    };

    private static (bool IsAllowed, int? StoreId, string? Reason) ResolveStoreScope(ClaimsPrincipal user, int? requestedStoreId)
    {
        var roles = GetRoles(user);
        var tokenStoreId = GetClaimInt(user, "storeId");

        if (roles.Contains("Admin") || roles.Contains("National Manager"))
            return (true, requestedStoreId ?? tokenStoreId, null);

        if (roles.Contains("AreaManager"))
        {
            if (requestedStoreId.HasValue && tokenStoreId.HasValue && requestedStoreId.Value != tokenStoreId.Value)
                return (false, null, "Tienda fuera de alcance para el rol actual.");

            return (true, requestedStoreId ?? tokenStoreId, null);
        }

        if (!tokenStoreId.HasValue)
            return (false, null, "El token no contiene storeId asignado.");

        if (requestedStoreId.HasValue && requestedStoreId.Value != tokenStoreId.Value)
            return (false, null, "No puedes consultar otra tienda distinta a la asignada en tu token.");

        return (true, tokenStoreId.Value, null);
    }

    private static bool HasStoreAccess(ClaimsPrincipal user, int targetStoreId)
    {
        var roles = GetRoles(user);
        if (roles.Contains("Admin") || roles.Contains("National Manager") || roles.Contains("AreaManager"))
            return true;

        var tokenStoreId = GetClaimInt(user, "storeId");
        return tokenStoreId.HasValue && tokenStoreId.Value == targetStoreId;
    }

    private static bool IsSupervisorOrHigher(ClaimsPrincipal user)
    {
        var roles = GetRoles(user);
        return roles.Contains("StoreSupervisor") || roles.Contains("AreaManager") ||
               roles.Contains("National Manager") || roles.Contains("Admin");
    }

    private static HashSet<string> GetRoles(ClaimsPrincipal user) =>
        user.FindAll(ClaimTypes.Role)
            .Concat(user.FindAll("role"))
            .Select(c => c.Value)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

    private static int? GetClaimInt(ClaimsPrincipal user, string claimType)
    {
        var raw = user.FindFirstValue(claimType);
        return int.TryParse(raw, out var value) ? value : null;
    }
}