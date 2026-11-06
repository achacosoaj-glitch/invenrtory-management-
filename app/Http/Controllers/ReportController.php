<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function stockMovements(): JsonResponse
    {
        $movements = DB::table('stock_movements as sm')
            ->join('products as p', 'p.id', '=', 'sm.product_id')
            ->select('sm.*', 'p.sku', 'p.product_name')
            ->orderByDesc('sm.id')
            ->get();

        return response()->json(['data' => $movements]);
    }

    public function sales(): JsonResponse
    {
        $sales = DB::table('sales as s')
            ->join('customers as c', 'c.id', '=', 's.customer_id')
            ->leftJoin('sale_items as si', 'si.sale_id', '=', 's.id')
            ->select(
                's.id',
                's.customer_id',
                'c.customer_name',
                's.total_amount',
                's.sale_status',
                's.sale_date',
                DB::raw('COUNT(si.id) AS item_lines')
            )
            ->groupBy('s.id', 's.customer_id', 'c.customer_name', 's.total_amount', 's.sale_status', 's.sale_date')
            ->orderByDesc('s.id')
            ->get();

        return response()->json(['data' => $sales]);
    }

    public function inventory(): JsonResponse
    {
        $inventory = DB::select(
            'SELECT p.id, p.sku, p.product_name, p.price, p.stock_quantity, p.minimum_stock,
                    c.category_name, fn_get_product_stock_status(p.id) AS stock_status
             FROM products p
             INNER JOIN categories c ON c.id = p.category_id
             ORDER BY p.id'
        );

        return response()->json(['data' => $inventory]);
    }
}
