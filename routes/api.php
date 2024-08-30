<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\FileController;
use App\Http\Controllers\ComputerController;

use App\Models\User;

use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;


// Groupe de Routes protégées par l'authentification
Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {

    // Route pour récupérer les informations de l'utilisateur connecté
    Route::get('/user', function (Request $request) { return $request->user(); });
    
    // Routes pour les fichiers
    Route::controller(FileController::class)->group(function () {
        Route::post('/retrieve_file', 'retrieveFile');
        Route::post('/retrieve_file_version', 'retrieveFileVersion');
        Route::post('/retrieve_files_list', 'retrieveFilesList');
    });

    // Routes pour les ordinateurs
    Route::controller(ComputerController::class)->group(function () {
        Route::post('/register_computer', 'registerComputer');
    });

    Route::resource('/computers', ComputerController::class)->only(['index', 'show', 'store', 'update', 'destroy']);

    Route::post('/auth_computer', [ComputerController::class,'auth_computer']);
});

// Groupe de Routes non protégées par l'authentification
Route::get('/startup', [FileController::class, 'retrieveStartupFile']);
Route::get('/bootstrap', [FileController::class, 'retrieveBootstrapFile']);
Route::post('/verify_computer_availability', [ComputerController::class, 'verifyComputerAvailability']);

// Route pour tester l'API
Route::get('/api_test', function () {
    return response()->json(['message' => 'API test successful']);
});
