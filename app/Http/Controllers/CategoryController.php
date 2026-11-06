<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CategoryController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['data' => DB::table('categories')->orderBy('id')->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'category_name' => ['required', 'string', 'max:120', 'unique:categories,category_name'],
            'description' => ['nullable', 'string'],
        ]);
        $now = now();
        $id = DB::table('categories')->insertGetId($data + ['created_at' => $now, 'updated_at' => $now]);

        return response()->json(['message' => 'Category created.', 'data' => DB::table('categories')->find($id)], 201);
    }
}
