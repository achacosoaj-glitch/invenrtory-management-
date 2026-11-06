<?php

use App\Http\Controllers\CategoryController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\FunctionController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ProcedureController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SupplierController;
use Illuminate\Support\Facades\Route;

Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class, 'show'])->whereNumber('id');
Route::post('/products', [ProductController::class, 'store']);
Route::put('/products/{id}', [ProductController::class, 'update'])->whereNumber('id');
Route::delete('/products/{id}', [ProductController::class, 'destroy'])->whereNumber('id');

Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/categories', [CategoryController::class, 'store']);
Route::get('/suppliers', [SupplierController::class, 'index']);
Route::post('/suppliers', [SupplierController::class, 'store']);
Route::get('/customers', [CustomerController::class, 'index']);
Route::post('/customers', [CustomerController::class, 'store']);

Route::get('/functions/calculate-sale-total', [FunctionController::class, 'calculateSaleTotal']);
Route::get('/functions/product-stock-status/{id}', [FunctionController::class, 'productStockStatus'])->whereNumber('id');

Route::post('/procedures/create-sale', [ProcedureController::class, 'createSale']);
Route::post('/procedures/add-stock', [ProcedureController::class, 'addStock']);
Route::post('/procedures/cancel-sale', [ProcedureController::class, 'cancelSale']);

Route::get('/reports/stock-movements', [ReportController::class, 'stockMovements']);
Route::get('/reports/sales', [ReportController::class, 'sales']);
Route::get('/reports/inventory', [ReportController::class, 'inventory']);
