<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\FilesController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::post('/retrieve_file', function (Request $request) {
        return (new FilesController)->retrieve_file($request);});
    Route::post('/retrieve_files_list', function (Request $request) {
        return (new FilesController)->retrieve_files_list($request);});
});

Route::post('/retrieve_bootstrap', function (Request $request) {
    return (new FilesController)->retrieve_bootstrap($request);
});


