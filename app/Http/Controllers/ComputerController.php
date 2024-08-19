<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Laravel\Jetstream\Jetstream;
use App\Models\Computer;

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

        // Fetch computers associated with these tokens
        $computers = Computer::whereIn('personal_access_token_id', $tokens->pluck('id'))->get();

        return Jetstream::inertia()->render($request, 'Computers/Index', [
            'computers' => $computers->map(function ($computer) {
                return $computer->toArray();
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


}
