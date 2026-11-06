<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FunctionController extends Controller
{
    public function calculateSaleTotal(Request $request): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['required', 'integer', 'min:1', 'exists:products,id'],
            'quantity' => ['required', 'integer', 'min:1'],
        ]);

        $result = DB::selectOne(
            'SELECT fn_calculate_sale_total(?, ?) AS subtotal',
            [$data['product_id'], $data['quantity']]
        );

        return response()->json([
            'product_id' => $data['product_id'],
            'quantity' => $data['quantity'],
            'subtotal' => $result->subtotal,
        ]);
    }

    public function productStockStatus(int $id): JsonResponse
    {
        if (! DB::table('products')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Product not found.'], 404);
        }

        $result = DB::selectOne(
            'SELECT fn_get_product_stock_status(?) AS stock_status',
            [$id]
        );

        return response()->json(['product_id' => $id, 'stock_status' => $result->stock_status]);
    }
}
