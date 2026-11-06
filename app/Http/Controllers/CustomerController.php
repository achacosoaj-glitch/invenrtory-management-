<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CustomerController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['data' => DB::table('customers')->orderBy('id')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'customer_name' => ['required', 'string', 'max:180'],
            'email' => ['nullable', 'email', 'max:255', 'unique:customers,email'],
            'contact_number' => ['nullable', 'string', 'max:40'],
            'address' => ['nullable', 'string'],
        ]);
        $now = now();
        $id = DB::table('customers')->insertGetId($data + ['created_at' => $now, 'updated_at' => $now]);

        return response()->json(['message' => 'Customer created.', 'data' => DB::table('customers')->find($id)], 201);
    }
}
