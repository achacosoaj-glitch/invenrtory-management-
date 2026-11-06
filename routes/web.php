<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'name' => 'Inventory Management System API',
        'api' => '/api',
    ]);
});
