<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProductController extends Controller
{
    public function index(): JsonResponse
    {
        $products = DB::table('products as p')
            ->join('categories as c', 'c.id', '=', 'p.category_id')
            ->leftJoin('suppliers as s', 's.id', '=', 'p.supplier_id')
            ->select('p.*', 'c.category_name', 's.supplier_name')
            ->orderBy('p.id')
            ->get();

        return response()->json(['data' => $products]);
    }

    public function show(int $id): JsonResponse
    {
        $product = DB::table('products as p')
            ->join('categories as c', 'c.id', '=', 'p.category_id')
            ->leftJoin('suppliers as s', 's.id', '=', 'p.supplier_id')
            ->select('p.*', 'c.category_name', 's.supplier_name')
            ->where('p.id', $id)
            ->first();

        if ($product === null) {
            return response()->json(['message' => 'Product not found.'], 404);
        }

        return response()->json(['data' => $product]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_id' => ['required', 'integer', 'exists:categories,id'],
            'supplier_id' => ['nullable', 'integer', 'exists:suppliers,id'],
            'sku' => ['required', 'string', 'max:80', 'unique:products,sku'],
            'product_name' => ['required', 'string', 'max:180'],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'gt:0'],
            'minimum_stock' => ['sometimes', 'integer', 'min:0'],
        ]);

        $now = now();
        $id = DB::table('products')->insertGetId($data + [
            'stock_quantity' => 0,
            'minimum_stock' => 0,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['message' => 'Product created.', 'data' => DB::table('products')->find($id)], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        if (! DB::table('products')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Product not found.'], 404);
        }

        $data = $request->validate([
            'category_id' => ['sometimes', 'required', 'integer', 'exists:categories,id'],
            'supplier_id' => ['sometimes', 'nullable', 'integer', 'exists:suppliers,id'],
            'sku' => ['sometimes', 'required', 'string', 'max:80', Rule::unique('products', 'sku')->ignore($id)],
            'product_name' => ['sometimes', 'required', 'string', 'max:180'],
            'description' => ['sometimes', 'nullable', 'string'],
            'price' => ['sometimes', 'required', 'numeric', 'gt:0'],
            'minimum_stock' => ['sometimes', 'required', 'integer', 'min:0'],
        ]);

        DB::table('products')->where('id', $id)->update($data + ['updated_at' => now()]);

        return response()->json(['message' => 'Product updated.', 'data' => DB::table('products')->find($id)]);
    }

    public function destroy(int $id): JsonResponse
    {
        $deleted = DB::table('products')->where('id', $id)->delete();
        if ($deleted === 0) {
            return response()->json(['message' => 'Product not found.'], 404);
        }

        return response()->json(['message' => 'Product deleted.']);
    }
}
