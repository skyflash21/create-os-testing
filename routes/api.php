<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\FileController;
use App\Http\Controllers\ComputerController;

use App\Models\User;

use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

use App\Http\Middleware\CheckIfBanned;
use App\Http\Middleware\CheckTokenCorrespondance;


// Groupe de Routes protégées par l'authentification
Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
    CheckIfBanned::class
])->group(function () {
    // Middleware pour vérifier si le token correspond à l'utilisateur
    Route::middleware([
        CheckTokenCorrespondance::class
    ])->group(function () {
        // Routes pour les ordinateurs
        Route::resource('/computers', ComputerController::class)->only(['index', 'show', 'store', 'update', 'destroy']);
        Route::post('/auth_computer', [ComputerController::class,'auth_computer']);
        Route::post('/auth_computer_{computer_id}', [ComputerController::class,'auth_computer_id']);
        Route::post('/double_computer_connected', [ComputerController::class,'double_computer_connected']);

        // Routes pour les fichiers
        Route::controller(FileController::class)->group(function () {
            Route::post('/retrieveFile', 'retrieveFile');
            Route::post('/retrieveAllFileVersions', 'retrieveAllFileVersions');
            Route::post('/retrieveFilesList', 'retrieveFilesList');
            Route::post('/syncFile', 'syncFile');
            Route::post('/retrieveLastVersion', 'retrieveLastVersion');
            Route::post('/syncFolder', 'syncFolder');
            
        });
    });

    // Chemin sans verification de correspondance de token
    Route::controller(ComputerController::class)->group(function () {
        Route::post('/register_computer', 'registerComputer');
    });
});

// Groupe de Routes non protégées par l'authentification
Route::get('/startup', [FileController::class, 'retrieveStartupFile']);
Route::get('/bootstrap', [FileController::class, 'retrieveBootstrapFile']);
Route::post('/verify_computer_availability', [ComputerController::class, 'verifyComputerAvailability']);

Route::post('/sync_files', [FileController::class, 'syncFileRequest']);


// Route pour tester l'API
Route::get('/api_test', function () {
    return response()->json(['message' => 'API test successful']);
});
