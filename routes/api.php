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

    // Protéger la route de mise à jour des ordinateurs
    Route::post('/auth-sanctum', function (Request $request) {

        // Get the user
        $user = $request->user();

        if (!$user) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }
    
        // Pusher credentials
        $pusherKey = "7axlwwvifanpbi53vh1z";
        $pusherSecret = "84ic8pxf3qwctgahtpeu";
    
        // Prepare the data to sign
        $socketId = $request->input('socket_id');
        $channelName = $request->input('channel_name');
        
        // Create the string to sign based on the type of channel
        if (strpos($channelName, 'presence-') === 0) {
            // Presence channel 
            // exemple "user_id":"1","user_info":{"id":1,"name":"Administrateur","profile_photo_url":"https:\/\/ui-avatars.com\/api\/?name=A&color=7F9CF5&background=EBF4FF"
            $userData = json_encode(["user_id" => $user->id, "user_info" => $user]);
            $stringToSign = "$socketId:$channelName:$userData";
        } else {
            // Private channel
            $stringToSign = "$socketId:$channelName";
        }
    
        // Generate the HMAC SHA256 signature
        $authSignature = hash_hmac('sha256', $stringToSign, $pusherSecret);
    
        // Create the auth string
        $auth = "$pusherKey:$authSignature";
    
        // Prepare the response
        $response = [
            'auth' => $auth,
        ];
    
        // If it's a presence channel, add user data
        if (strpos($channelName, 'presence-') === 0) {
            $response['channel_data'] = $userData;
        }
    
        // Return the JSON response
        return response()->json($response);
    });

});

// Groupe de Routes non protégées par l'authentification
Route::get('/startup', [FileController::class, 'retrieveStartupFile']);
Route::get('/bootstrap', [FileController::class, 'retrieveBootstrapFile']);
Route::post('/verify_computer_availability', [ComputerController::class, 'verifyComputerAvailability']);

// Route pour tester l'API
Route::get('/api_test', function () {
    return response()->json(['message' => 'API test successful']);
});
