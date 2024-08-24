<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;

use App\Models\Computer;
use Illuminate\Routing\Controller;
use Laravel\Jetstream\Jetstream;

use App\Events\ComputerRegisteredEvent;

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
                    'type' => $computer->type,
                    'is_advanced' => $computer->is_advanced,
                    'wireless_modem_side' => $computer->wireless_modem_side,
                    'used_disk_space' => $computer->used_disk_space,
                    'total_disk_space' => $computer->total_disk_space,
                    'last_used_at' => $computer->last_used_at,
                    'created_at' => $computer->created_at,
                    'token_name' => $computer->personalAccessToken->name,
                    'token_id' => $computer->personalAccessToken->id,
                ];
            }),
        ]);
    }

    /**
     * Register a new computer from the api.
     * 
     * @param Request $request
     * @return json
     */
    public function registerComputer(Request $request)
    {
        $personal_access_token = PersonalAccessToken::findToken($request->bearerToken());

        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'type' => 'required|in:turtle,pocket,computer',
            'is_advanced' => 'required|boolean',
            'wireless_modem_side' => 'required|in:left,right,front,back,up,down,none',
            'total_disk_space' => 'required|integer',
            'used_disk_space' => 'required|integer',
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
            'type' => $request->type,
            'is_advanced' => $request->is_advanced,
            'wireless_modem_side' => $request->wireless_modem_side,
            'total_disk_space' => $request->total_disk_space,
            'used_disk_space' => $request->used_disk_space,
        ]);

        $user = $personal_access_token->tokenable;

        // Dispatch the event
        event(new ComputerRegisteredEvent($computer, $user));

        return response()->json($computer, 201);
    }

    /**
     * Retrieve the computer data from the api.
     */
    public function retrieveComputer(Request $request)
    {
        $personal_access_token = PersonalAccessToken::findToken($request->bearerToken());

        // Check if the personal access token exists
        if (!$personal_access_token) {
            return response()->json(['error' => 'Unauthorized action or invalid token.'], 401);
        }

        // Validate the incoming request data
        $validatedData = $request->validate([
            'id' => 'required|exists:computers,id',
        ]);

        // Retrieve the computer data
        $computer = Computer::where('id', $request->id)->first();

        return response()->json($computer, 200);
    }

    /**
     * Update the specified computer in storage.
     * 
     * @param Request $request
     * @param Computer $computer
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Computer $computer)
    {
        // Check if the computer has a linked personal access token
        if (!$computer->personalAccessToken || $request->user()->id !== $computer->personalAccessToken->tokenable_id) {
            return redirect()->route('computers.index')->with('error', 'Unauthorized action or invalid token.');
        }

        // Validate the incoming request data
        $validatedData = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string|max:255',
        ]);

        // Update the computer
        $computer->update($validatedData);

        return redirect()->route('computers.index')->with('success', 'Computer updated successfully.');
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
