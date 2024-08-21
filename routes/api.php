<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\FilesController;
use App\Http\Controllers\ComputerController;

// Route pour récupérer l'utilisateur authentifié
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Route pour tester l'API
Route::get('/api_test', function () {
    return response()->json(['message' => 'API test successful']);
});

// Routes protégées par l'authentification
Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {

    // Routes pour les fichiers
    Route::controller(FilesController::class)->group(function () {
        Route::post('/retrieve_file', 'retrieveFile');
        Route::post('/retrieve_file_version', 'retrieveFileVersion');
        Route::post('/retrieve_files_list', 'retrieveFilesList');
    });

    // Routes pour les ordinateurs
    Route::controller(ComputerController::class)->group(function () {
        Route::post('/register_computer', 'registerComputer');
    });
});

// Route pour récupérer le fichier de démarrage (startup)
Route::get('/startup', [FilesController::class, 'retrieveStartupFile']);
Route::get('/bootstrap', [FilesController::class, 'retrieveBootstrapFile']);

Route::post('/verify_computer_availability', [ComputerController::class, 'verifyComputerAvailability']);
