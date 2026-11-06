<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProcedureController extends Controller
{
    public function createSale(Request $request): JsonResponse
    {
        $data = $request->validate([
            'customer_id' => ['required', 'integer', 'min:1'],
            'product_id' => ['required', 'integer', 'min:1'],
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $result = DB::selectOne('CALL sp_create_sale(?, ?, ?)', [
            $data['customer_id'],
            $data['product_id'],
            $data['quantity'],
        ]);

        return response()->json(['message' => 'Sale created.', 'data' => $result], 201);
    }

    public function addStock(Request $request): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['required', 'integer', 'min:1'],
            'quantity' => ['required', 'integer', 'min:1'],
            'remarks' => ['nullable', 'string', 'max:500'],
        ]);

        $result = DB::selectOne('CALL sp_add_product_stock(?, ?, ?)', [
            $data['product_id'],
            $data['quantity'],
            $data['remarks'] ?? null,
        ]);

        return response()->json(['message' => 'Product stock added.', 'data' => $result]);
    }

    public function cancelSale(Request $request): JsonResponse
    {
        $data = $request->validate([
            'sale_id' => ['required', 'integer', 'min:1'],
        ]);

        $result = DB::selectOne('CALL sp_cancel_sale(?)', [$data['sale_id']]);

        return response()->json(['message' => 'Sale cancelled and stock restored.', 'data' => $result]);
    }
}
