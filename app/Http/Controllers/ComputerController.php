<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Laravel\Jetstream\Jetstream;
use App\Models\Computer;

use Laravel\Sanctum\PersonalAccessToken;

class ComputerController extends Controller
{
    /**
     * Display a listing of the computers.
     *
     * @param Request $request
     * @return \Inertia\Response
     */
    public function index(Request $request)
    {
        // Get the user's personal access tokens
        $tokens = $request->user()->tokens;

        // Fetch computers associated with these tokens, eager loading the related PersonalAccessToken
        $computers = Computer::whereIn('personal_access_token_id', $tokens->pluck('id'))
            ->with('personalAccessToken') // Eager load the PersonalAccessToken relationship
            ->get();

        return Jetstream::inertia()->render($request, 'Computers/Index', [
            'computers' => $computers->map(function ($computer) {
                // Convert the computer and its associated personal access token to array
                return [
                    'computer_id' => $computer->id,
                    'computer_name' => $computer->name,
                    'computer_description' => $computer->description,
                    'token_name' => $computer->personalAccessToken->name,
                    'token_id' => $computer->personalAccessToken->id,
                ];
            }),
        ]);
    }
    
    /**
     * Store a newly created computer in storage.
     *
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        // Log the incoming request data to check
        \Log::debug('Incoming Request Data:', $request->all());

        $request->validate([
            'personal_access_token_id' => 'required|exists:personal_access_tokens,id',
            'id' => 'required|unique:computers,id',  // Ensure the computer ID is unique
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:255',
        ]);

        // Create a new computer
        $computer = Computer::create([
            'id' => $request->id,
            'personal_access_token_id' => $request->personal_access_token_id,
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return redirect()->route('computers.index')->with('success', 'Computer added successfully.');
    }

    /**
     * Register a new computer from the api.
     * 
     * @param Request $request
     * @return json
     */
    public function registerComputer(Request $request)
    {
        // the incoming request is from a post request, the data is in the request body
        // this is the list of data :
        // - personal_access_token (not the id but the token itself), the token is not in the body but in the authorization header
        // - id
        // - name
        // - description
        
        // get the personal access token from the request header
        $personal_access_token = PersonalAccessToken::findToken($request->bearerToken());

        // check if the personal access token is valid
        if (!$personal_access_token) {
            return response()->json(['error' => 'Unauthorized action or invalid token.'], 401);
        }

        //Check if the computer_id is already in the database
        if ($request->id == null) {
            return response()->json(['error' => 'Computer ID is required.'], 400);
        }

        if (Computer::where('id', $request->id)->exists()) {
            return response()->json(['error' => 'Computer already exists.'], 409);
        }

        // validate the incoming request data
        $request->validate([
            'id' => 'required|unique:computers,id',  // Ensure the computer ID is unique
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:255',
        ]);

        // check if the computer already exists
        if (Computer::where('id', $request->id)->exists()) {
            return response()->json(['error' => 'Computer already exists.'], 409);
        }

        // Create a new computer
        $computer = Computer::create([
            'id' => $request->id,
            'personal_access_token_id' => $personal_access_token->id,
            'name' => $request->name,
            'description' => $request->description,
        ]);

        return response()->json(['message' => 'Computer added successfully.'], 201);
    }

    /**
     * Verify if the computer is registered.
     * 
     * @param Request $request
     * @return json
     */
    public function verifyComputerAvailability(Request $request)
    {
        // check if the computer already exists, if it does return "available" = false and the computer data
        if (Computer::where('id', $request->id)->exists()) {
            $computer = Computer::where('id', $request->id)->first();
            return response()->json(['available' => false, 'created_at' => $computer->created_at], 200);
        }else
        {
            return response()->json(['available' => true], 200);
        }
    }

    
    /**
     * Remove the specified computer from storage.
     * 
     * @param Request $request
     * @param Computer $computer
     * @return \Illuminate\Http\Response
     */
    public function destroy(Request $request, Computer $computer)
    {
        // Check if the computer has a linked personal access token
        if (!$computer->personalAccessToken || $request->user()->id !== $computer->personalAccessToken->tokenable_id) {
            return redirect()->route('computers.index')->with('error', 'Unauthorized action or invalid token.');
        }

        // Delete the computer
        $computer->delete();

        return redirect()->route('computers.index')->with('success', 'Computer deleted successfully.');
    }
}
