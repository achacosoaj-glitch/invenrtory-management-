<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SupplierController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['data' => DB::table('suppliers')->orderBy('id')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'supplier_name' => ['required', 'string', 'max:160'],
            'contact_number' => ['nullable', 'string', 'max:40'],
            'email' => ['nullable', 'email', 'max:255', 'unique:suppliers,email'],
            'address' => ['nullable', 'string'],
        ]);
        $now = now();
        $id = DB::table('suppliers')->insertGetId($data + ['created_at' => $now, 'updated_at' => $now]);

        return response()->json(['message' => 'Supplier created.', 'data' => DB::table('suppliers')->find($id)], 201);
    }
}
