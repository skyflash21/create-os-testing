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
                    'computer' => $computer->toArray(),
                    'personal_access_token' => $computer->personalAccessToken ? $computer->personalAccessToken->toArray() : null,
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
        ]);
        

        // Create a new computer
        $computer = Computer::create([
            'personal_access_token_id' => $request->personal_access_token_id,
        ]);

        return redirect()->route('computers.index')->with('success', 'Computer added successfully.');
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
