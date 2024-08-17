<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::middleware('auth:sanctum')->get('/demo', function (Request $request) {
    if ($request->user()->tokenCan('storage_management:delete_storages')) {
        return response()->json([
            'message' => 'You have the permission to delete storages'
        ]);
    } else {
        return response()->json([
            'message' => 'You do not have the permission to delete storages'
        ]);
    }
});